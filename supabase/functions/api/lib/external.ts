// Third-party integrations: Groq (AI), Stripe, weather, email.
// All keys are Edge Function secrets — never shipped in the app.
import nodemailer from "npm:nodemailer@6.9.16";

// ── Groq ────────────────────────────────────────────────────────────────────
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = Deno.env.get("GROQ_MODEL") || "llama-3.3-70b-versatile";

export const groqConfigured = () => !!Deno.env.get("GROQ_API_KEY");

export async function groqChat(
  messages: { role: string; content: string }[],
  opts: { maxTokens?: number; temperature?: number; timeoutMs?: number } = {},
): Promise<string> {
  const key = Deno.env.get("GROQ_API_KEY");
  if (!key) throw new Error("GROQ_API_KEY not configured");
  const model = GROQ_MODEL;
  // Reasoning models spend part of max_tokens "thinking" before answering; with
  // small budgets the visible answer comes back empty. Give them headroom and
  // ask for brief reasoning.
  const isGptOss = /gpt-oss/i.test(model);
  const isQwen3 = /qwen3/i.test(model);
  const isReasoning = isGptOss || isQwen3 || /deepseek-r1|reason/i.test(model);
  const requested = opts.maxTokens ?? 512;
  const body: Record<string, unknown> = {
    model,
    messages,
    max_tokens: isReasoning ? Math.max(requested * 4, 2048) : requested,
    temperature: opts.temperature ?? 0.7,
  };
  if (isGptOss) body.reasoning_effort = "low";
  if (isQwen3) body.reasoning_effort = "none";
  if (isReasoning) body.reasoning_format = "hidden";

  const res = await fetch(GROQ_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(opts.timeoutMs ?? (isReasoning ? 40000 : 20000)),
  });
  if (!res.ok) throw new Error(`Groq HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
  const data = await res.json();
  const content = String(data?.choices?.[0]?.message?.content ?? "");
  // strip any inline reasoning some models emit
  const cleaned = content.replace(/<think>[\s\S]*?<\/think>/gi, "").trim();
  if (!cleaned) {
    console.error(`[ai] empty completion from ${model} (finish_reason=${data?.choices?.[0]?.finish_reason})`);
  }
  return cleaned;
}

// ── Stripe (REST, no SDK) ───────────────────────────────────────────────────
export const stripeConfigured = () => !!Deno.env.get("STRIPE_SECRET_KEY");

function form(obj: Record<string, unknown>, prefix = "", out = new URLSearchParams()) {
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null) continue;
    const key = prefix ? `${prefix}[${k}]` : k;
    if (typeof v === "object") form(v as Record<string, unknown>, key, out);
    else out.append(key, String(v));
  }
  return out;
}

export async function stripe(method: "GET" | "POST", path: string, params?: Record<string, unknown>) {
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) throw new Error("Stripe not configured. Set the STRIPE_SECRET_KEY secret.");
  const res = await fetch(`https://api.stripe.com/v1/${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: method === "POST" ? form(params ?? {}).toString() : undefined,
    signal: AbortSignal.timeout(20000),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data?.error?.message ?? `Stripe HTTP ${res.status}`);
  return data;
}

/** Verify a Stripe-Signature header (v1 scheme, 5-minute tolerance). */
export async function verifyStripeSignature(payload: string, header: string, secret: string): Promise<boolean> {
  const parts = Object.fromEntries(
    header.split(",").map((p) => p.split("=") as [string, string]).filter((p) => p.length === 2),
  );
  const t = parts["t"];
  const sigs = header.split(",").filter((p) => p.startsWith("v1=")).map((p) => p.slice(3));
  if (!t || sigs.length === 0) return false;
  if (Math.abs(Date.now() / 1000 - Number(t)) > 300) return false;
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${t}.${payload}`));
  const expected = Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, "0")).join("");
  return sigs.some((s) => s.length === expected.length &&
    s.split("").reduce((acc, ch, i) => acc | (ch.charCodeAt(0) ^ expected.charCodeAt(i)), 0) === 0);
}

// ── Weather ─────────────────────────────────────────────────────────────────
// OpenWeatherMap when OWM_API_KEY is set (gives city names), otherwise the
// keyless Open-Meteo API so weather keeps working with no configuration.
export const weatherCodeToCondition = (code: number) => {
  if (code === 0) return "Clear";
  if ([1, 2].includes(code)) return "Partly Cloudy";
  if (code === 3) return "Cloudy";
  if ([45, 48].includes(code)) return "Fog";
  if ([51, 53, 55].includes(code)) return "Drizzle";
  if ([61, 63, 65].includes(code)) return "Rain";
  if ([71, 73, 75].includes(code)) return "Snow";
  if ([80, 81, 82].includes(code)) return "Showers";
  if ([85, 86].includes(code)) return "Snow Showers";
  if ([95, 96, 99].includes(code)) return "Thunderstorm";
  return "Unknown";
};

async function getJson(url: string) {
  const res = await fetch(url, { signal: AbortSignal.timeout(12000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

export async function currentWeather(lat: number, lng: number, fallbackCity: string) {
  const owm = Deno.env.get("OWM_API_KEY");
  if (owm) {
    const d = await getJson(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${owm}&units=metric`,
    );
    return {
      temperature: Math.round(d.main?.temp ?? 0),
      condition: d.weather?.[0]?.description ?? "Unknown",
      humidity: Math.round(d.main?.humidity ?? 0),
      wind_speed: Math.round(d.wind?.speed ?? 0),
      city: d.name || fallbackCity,
    };
  }
  const d = await getJson(
    `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}` +
      `&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&wind_speed_unit=ms`,
  );
  return {
    temperature: Math.round(d.current?.temperature_2m ?? 0),
    condition: weatherCodeToCondition(d.current?.weather_code ?? -1),
    humidity: Math.round(d.current?.relative_humidity_2m ?? 0),
    wind_speed: Math.round(d.current?.wind_speed_10m ?? 0),
    city: fallbackCity,
  };
}

export async function weatherForecast(lat: number, lng: number, days: number, fallbackCity: string) {
  const owm = Deno.env.get("OWM_API_KEY");
  if (owm) {
    const data = await getJson(
      `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&appid=${owm}&units=metric`,
    );
    const byDay: Record<string, any> = {};
    for (const item of data.list ?? []) {
      const [date, hour] = String(item.dt_txt).split(" ");
      if (!byDay[date] || hour === "12:00:00") {
        byDay[date] = {
          date,
          temp_min: Math.round(item.main.temp_min),
          temp_max: Math.round(item.main.temp_max),
          condition: item.weather?.[0]?.description ?? "Unknown",
          icon: item.weather?.[0]?.icon ?? "",
          humidity: item.main.humidity,
          wind_speed: Math.round(item.wind.speed),
        };
      }
    }
    return { city: data.city?.name || fallbackCity, forecast: Object.values(byDay).slice(0, Math.min(days, 7)) };
  }
  const d = await getJson(
    `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}` +
      `&daily=temperature_2m_max,temperature_2m_min,weather_code,relative_humidity_2m_mean,wind_speed_10m_max` +
      `&wind_speed_unit=ms&timezone=auto&forecast_days=${Math.min(Math.max(days, 1), 7)}`,
  );
  const daily = d.daily ?? {};
  const forecast = (daily.time ?? []).map((date: string, i: number) => ({
    date,
    temp_min: Math.round(daily.temperature_2m_min?.[i] ?? 0),
    temp_max: Math.round(daily.temperature_2m_max?.[i] ?? 0),
    condition: weatherCodeToCondition(daily.weather_code?.[i] ?? -1),
    icon: "",
    humidity: Math.round(daily.relative_humidity_2m_mean?.[i] ?? 0),
    wind_speed: Math.round(daily.wind_speed_10m_max?.[i] ?? 0),
  }));
  return { city: fallbackCity, forecast };
}

// ── Email (Gmail/SMTP over implicit TLS — Edge Functions block port 587) ────
let transporter: ReturnType<typeof nodemailer.createTransport> | null = null;
const emailConfigured = () => !!(Deno.env.get("EMAIL_USER") && Deno.env.get("EMAIL_PASS"));

function mailer() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: Deno.env.get("EMAIL_HOST") || "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: { user: Deno.env.get("EMAIL_USER"), pass: Deno.env.get("EMAIL_PASS") },
    });
  }
  return transporter;
}

const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));

function layout(heading: string, bodyHtml: string, accent = "#13E8D0") {
  return `
  <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; border-radius: 12px;">
    <div style="background: linear-gradient(135deg, #1B5A6E, ${accent}); padding: 24px; border-radius: 12px 12px 0 0; text-align: center;">
      <h1 style="color: white; margin: 0; font-size: 24px;">SafarSync</h1>
      <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0; font-size: 14px;">Travel Smarter. Travel Safer. Travel Together.</p>
    </div>
    <div style="background: white; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e0e0e0; border-top: none;">
      <h2 style="color: #1B5A6E; margin: 0 0 16px;">${heading}</h2>
      ${bodyHtml}
      <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
      <p style="color: #aaa; font-size: 12px; text-align: center; margin: 0;">
        Travel Smarter. Travel Safer. Travel Together.<br/><strong>SafarSync Team</strong>
      </p>
    </div>
  </div>`;
}

async function send(to: string, subject: string, html: string) {
  if (!emailConfigured()) {
    console.log(`[email] skipped (EMAIL_USER/EMAIL_PASS secrets not set): ${subject}`);
    return;
  }
  try {
    await mailer().sendMail({ from: `"SafarSync" <${Deno.env.get("EMAIL_USER")}>`, to, subject, html });
    console.log(`[email] sent "${subject}" → ${to}`);
  } catch (e) {
    console.error(`[email] failed "${subject}" → ${to}:`, (e as Error).message);
  }
}

const mapLink = (lat: unknown, lng: unknown) => `https://www.google.com/maps?q=${lat},${lng}`;

export const emails = {
  groupInvitation: (a: { toEmail: string; toName?: string; senderName: string; tripName: string; invitationId: number }) =>
    send(a.toEmail, "SafarSync Group Booking Invitation", layout("You have been invited!", `
      <p style="color:#333;font-size:16px;">Hello <strong>${esc(a.toName || a.toEmail)}</strong>,</p>
      <p style="color:#555;line-height:1.6;"><strong>${esc(a.senderName)}</strong> has invited you to join the group trip:</p>
      <div style="background:#f0f9ff;border-left:4px solid #13E8D0;padding:16px;margin:20px 0;border-radius:4px;">
        <p style="margin:0;font-size:20px;font-weight:bold;color:#1B5A6E;">${esc(a.tripName)}</p>
        <p style="margin:8px 0 0;color:#666;font-size:14px;">Trip Type: Group Booking</p>
      </div>
      <p style="color:#555;line-height:1.6;">Please open the <strong>SafarSync</strong> app and navigate to your invitations to accept or decline this trip.</p>
      <p style="color:#888;font-size:13px;text-align:center;">Invitation ID: #${a.invitationId}</p>`)),

  invitationResponse: (a: { toEmail: string; toName?: string; responderName: string; tripName: string; status: string }) =>
    send(a.toEmail, `Invitation ${a.status} — ${a.tripName}`, layout(`Invitation ${esc(a.status)}`, `
      <p style="color:#333;font-size:16px;">Hello <strong>${esc(a.toName || a.toEmail)}</strong>,</p>
      <p style="color:#555;line-height:1.6;"><strong>${esc(a.responderName)}</strong> has
        <strong>${esc(a.status.toLowerCase())}</strong> your invitation to join <strong>${esc(a.tripName)}</strong>.</p>`)),

  emergencyAlert: (a: Record<string, any>) =>
    send(a.toEmail, `🚨 EMERGENCY SOS — ${a.userName}`, layout("Emergency SOS Alert", `
      <p style="color:#333;font-size:16px;">Hello <strong>${esc(a.toName)}</strong>,</p>
      <p style="color:#c0392b;font-weight:bold;">${esc(a.userName)} has triggered an emergency SOS.</p>
      <table style="width:100%;font-size:14px;color:#444;">
        <tr><td><b>Phone</b></td><td>${esc(a.userPhone)}</td></tr>
        <tr><td><b>Email</b></td><td>${esc(a.userEmail)}</td></tr>
        ${a.tripName ? `<tr><td><b>Trip</b></td><td>${esc(a.tripName)}</td></tr>` : ""}
        <tr><td><b>Time</b></td><td>${esc(a.timestamp)}</td></tr>
        <tr><td><b>Alert ID</b></td><td>#${esc(a.alertId)}</td></tr>
        ${a.message ? `<tr><td><b>Message</b></td><td>${esc(a.message)}</td></tr>` : ""}
      </table>
      <p style="text-align:center;margin:24px 0;"><a href="${mapLink(a.latitude, a.longitude)}"
        style="background:#c0392b;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;">View location on map</a></p>`,
      "#c0392b")),

  emergencyContact: (a: Record<string, any>) =>
    send(a.toEmail, `🚨 ${a.userName} needs help — SafarSync SOS`, layout("Emergency SOS", `
      <p style="color:#333;font-size:16px;">Hello <strong>${esc(a.toName)}</strong>,</p>
      <p style="color:#555;line-height:1.6;">You are listed as an emergency contact${a.relationship ? ` (${esc(a.relationship)})` : ""}
        for <strong>${esc(a.userName)}</strong>, who has just triggered an SOS alert in SafarSync.</p>
      <table style="width:100%;font-size:14px;color:#444;">
        <tr><td><b>Phone</b></td><td>${esc(a.userPhone)}</td></tr>
        ${a.tripName ? `<tr><td><b>Trip</b></td><td>${esc(a.tripName)}</td></tr>` : ""}
        <tr><td><b>Time</b></td><td>${esc(a.timestamp)}</td></tr>
        ${a.message ? `<tr><td><b>Message</b></td><td>${esc(a.message)}</td></tr>` : ""}
      </table>
      <p style="text-align:center;margin:24px 0;"><a href="${mapLink(a.latitude, a.longitude)}"
        style="background:#c0392b;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;">See their location</a></p>
      <p style="color:#555;">Please try to reach them immediately. In Pakistan, call 1122 (Rescue) or 15 (Police) if needed.</p>`,
      "#c0392b")),
};
