// emergency + SOS, emergency contacts, payments (Stripe), AI, tours, virtual tours
import { exec, q, q1, tx } from "../lib/db.ts";
import { clampLimit, fail, idParam, json, type Router, text, toInt, toNum } from "../lib/http.ts";
import { resolveAdmin } from "../lib/auth.ts";
import { background, emit, notify } from "../lib/notify.ts";
import { emails, groqChat, groqConfigured, stripe, stripeConfigured, verifyStripeSignature } from "../lib/external.ts";
import { getBookingById } from "./trips.ts";
import { HOLD_MINUTES } from "./hospitality.ts";

const SYSTEM_PROMPT = `You are Safar AI, a travel assistant specializing in Pakistan tourism.
You help travelers plan trips, discover destinations, understand local culture, find food spots,
and stay safe while traveling in Pakistan. You are friendly, concise, and always give practical advice.
When asked about other topics, gently redirect to travel-related assistance.`;

const WELLNESS_PROMPT = `You are SafarSync's wellness companion for travelers.
You help with travel anxiety, jet lag, culture shock, loneliness on trips, and maintaining
mental and physical health while traveling. Be empathetic, supportive, and give actionable tips.
Keep responses warm, brief, and practical.`;

const ALERT_SQL = `
  select ea.*, u.full_name, u.email, gb.trip_name
  from public.emergency_alerts ea
  join public.users u on u.user_id = ea.user_id
  left join public.group_bookings gb on ea.trip_type = 'group' and ea.trip_id = gb.group_booking_id`;

async function dispatchEmergency(alertId: number, userId: number, lat: number, lng: number,
                                 msg: string | null, tripId: number | null, tripType: string | null) {
  const user = await q1(
    `select u.full_name, u.phone_number, u.email,
            case when $1 = 'group' then gb.trip_name end as trip_name
     from public.users u left join public.group_bookings gb on gb.group_booking_id = $2
     where u.user_id = $3`, [tripType ?? "", tripId ?? 0, userId]);
  if (!user) return;
  const tripName = user.trip_name || (tripId ? `Trip #${tripId}` : null);
  const timestamp = new Date().toLocaleString("en-PK", { timeZone: "Asia/Karachi" });
  const nowIso = new Date().toISOString();

  await emit("emergency:admin", "emergency:sos", {
    alert_id: alertId, user_id: userId, user_name: user.full_name, user_phone: user.phone_number || "N/A",
    user_email: user.email, trip_name: tripName, latitude: lat, longitude: lng, message: msg, timestamp: nowIso,
  });
  await emit("emergency:admin", "sos_alert", { alert_id: alertId, user_id: userId, latitude: lat, longitude: lng, timestamp: nowIso });

  await notify(userId, "🚨 SOS Alert Sent",
    "Your emergency alert has been broadcast to all admins. Stay safe — help is coming.",
    "emergency_sos_sent", `/emergency/${alertId}`);

  const payload = {
    userName: user.full_name, userPhone: user.phone_number || "N/A", userEmail: user.email, tripName,
    latitude: lat, longitude: lng, alertId, message: msg, timestamp,
  };

  const contacts = await q(
    `select contact_name, contact_email, relationship from public.emergency_contacts
     where user_id = $1 and coalesce(contact_email, '') <> ''`, [userId]);
  for (const c of contacts) {
    await emails.emergencyContact({ toEmail: c.contact_email, toName: c.contact_name, relationship: c.relationship, ...payload });
  }

  const admins = await q(
    `select distinct user_id, full_name, email from (
       select user_id, full_name, email from public.users where is_admin and not is_blocked
       union
       select u.user_id, u.full_name, u.email from public.admins a
       join public.users u on u.auth_user_id = a.auth_user_id where a.is_active) x`);
  const body = `${user.full_name} triggered SOS! Phone: ${user.phone_number || "N/A"}` +
    (tripName ? ` | Trip: ${tripName}` : "") + ` | Location: ${lat.toFixed(5)}, ${lng.toFixed(5)}`;
  for (const a of admins) {
    await notify(a.user_id, `🚨 Emergency SOS — ${user.full_name}`, body, "emergency_sos_admin", `/admin/emergency/${alertId}`);
    await emails.emergencyAlert({ toEmail: a.email, toName: a.full_name, ...payload });
  }
  const envEmail = Deno.env.get("ADMIN_EMAIL");
  if (envEmail && !admins.some((a) => a.email === envEmail)) {
    await emails.emergencyAlert({ toEmail: envEmail, toName: "SafarSync Admin", ...payload });
  }
}

function parsePkg(row: Record<string, any>) {
  const arr = (v: unknown) => Array.isArray(v) ? v : (() => { try { return JSON.parse(String(v ?? "[]")); } catch { return []; } })();
  return { ...row, destinations: arr(row.destinations), itinerary: arr(row.itinerary), includes: arr(row.includes) };
}

function fallbackPlan(budget: number, travelers: number, days: number, dests: Record<string, any>[]) {
  const perDay = Math.round(budget / travelers / days);
  const names = dests.slice(0, Math.min(days, 3)).map((d) => d.name);
  return {
    title: `${days}-Day Budget Adventure in Pakistan`,
    total_estimated_cost: budget,
    daily_budget: perDay * travelers,
    recommended_destinations: names.length ? names : ["Murree", "Naran", "Swat"],
    itinerary: Array.from({ length: days }, (_, i) => ({
      day: i + 1,
      location: names[i % Math.max(names.length, 1)] || "Islamabad",
      activities: ["Explore local attractions", "Try local food", "Sightseeing"],
      estimated_cost: perDay * travelers,
      transport: "Public bus / Coaster (most affordable)",
      accommodation: "Local guesthouse or budget hotel",
    })),
    money_saving_tips: [
      "Travel by public transport (Coasters/buses) instead of renting cars",
      "Stay in guesthouses rather than hotels — often cleaner and cheaper",
      "Eat at local dhabas for authentic food at 1/5 the restaurant price",
      "Book accommodations in advance for better rates",
      "Travel off-season (Oct–Mar for northern areas) for discounts",
    ],
    best_time_to_go: "April–October for northern areas, October–March for south",
    included_in_budget: ["Accommodation", "Transport", "Main meals", "Entry tickets"],
    not_included: ["Flights", "Personal shopping", "Tips", "Emergency expenses"],
  };
}

export async function getTourById(id: number, includeInactive = false) {
  const tour = await q1(
    `select vt.*, d.name as destination_name,
            (select count(*) from public.virtual_tour_scenes where tour_id = vt.id) as scene_count
     from public.virtual_tours vt left join public.destinations d on d.destination_id = vt.destination_id
     where vt.id = $1 ${includeInactive ? "" : "and vt.is_active"}`, [id]);
  if (!tour) return null;
  const scenes = await q(`select * from public.virtual_tour_scenes where tour_id = $1 order by scene_order asc, id asc`, [id]);
  const ids = scenes.map((s) => s.id);
  const hotspots = ids.length
    ? await q(`select h.*, h.target_scene_id as target_scene_db_id from public.virtual_tour_hotspots h
               where h.scene_id = any($1::int[])`, [ids])
    : [];
  tour.scenes = scenes.map((s) => ({
    ...s,
    sceneKey: `scene_${s.id}`,
    hotspots: hotspots.filter((h) => h.scene_id === s.id)
      .map((h) => ({ ...h, targetSceneKey: h.target_scene_id ? `scene_${h.target_scene_id}` : null })),
  }));
  tour.defaultSceneKey = tour.scenes.length ? tour.scenes[0].sceneKey : null;
  return tour;
}

export function registerFeatures(r: Router) {
  // ── emergency SOS ─────────────────────────────────────────────────────────
  r.get("/emergency/admin/all", "admin", async () => {
    return json({ success: true, alerts: await q(`${ALERT_SQL} order by ea.created_at desc limit 50`) });
  });

  r.get("/emergency/admin/events", "admin", async () => {
    const rows = await q(
      `select ee.*, u.full_name, u.phone_number from public.emergency_events ee
       join public.users u on u.user_id = ee.user_id order by ee.created_at desc limit 100`);
    return json({ success: true, events: rows });
  });

  r.get("/emergency/active", "user", async ({ auth }) => {
    const alert = await q1(`${ALERT_SQL} where ea.user_id = $1 and ea.status = 'Active' order by ea.created_at desc limit 1`,
      [auth.userId]);
    return json({ success: true, alert: alert ?? null });
  });

  r.get("/emergency/my-alerts", "user", async ({ auth }) => {
    const rows = await q(
      `select ea.*, gb.trip_name from public.emergency_alerts ea
       left join public.group_bookings gb on ea.trip_type = 'group' and ea.trip_id = gb.group_booking_id
       where ea.user_id = $1 order by ea.created_at desc limit 20`, [auth.userId]);
    return json({ success: true, alerts: rows });
  });

  r.post("/emergency/trigger", "user", async ({ auth, body }) => {
    const lat = toNum(body?.latitude) ?? 0, lng = toNum(body?.longitude) ?? 0;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return json({ success: false, message: "Invalid coordinates" }, 400);
    const tripType = ["single", "group"].includes(body?.trip_type) ? body.trip_type : null;
    const tripId = toInt(body?.trip_id);
    const message = text(body?.message ?? body?.location_description, 2000);
    const row = await q1(
      `insert into public.emergency_alerts (user_id, trip_id, trip_type, latitude, longitude, message, status)
       values ($1, $2, $3, $4, $5, $6, 'Active') returning id`,
      [auth.userId, tripId, tripType, lat, lng, message]);
    await q(`insert into public.emergency_events (user_id, type, latitude, longitude) values ($1, 'full_sos', $2, $3)`,
      [auth.userId, lat, lng]);
    background(dispatchEmergency(row!.id, auth.userId, lat, lng, message, tripId, tripType));
    return json({ success: true, alert_id: row!.id, message: "SOS activated — emergency contacts notified" }, 201);
  });

  r.post("/emergency/event", "user", async ({ auth, body }) => {
    const type = body?.type;
    if (!["ambulance", "police", "tourist_police", "ice_share", "full_sos"].includes(type)) {
      return json({ success: false, message: "Invalid event type" }, 400);
    }
    const lat = toNum(body?.latitude) ?? 0, lng = toNum(body?.longitude) ?? 0;
    const row = await q1(
      `insert into public.emergency_events (user_id, type, latitude, longitude) values ($1, $2, $3, $4) returning id`,
      [auth.userId, type, lat, lng]);
    const u = await q1(`select full_name, phone_number from public.users where user_id = $1`, [auth.userId]);
    await emit("emergency:admin", "emergency:event", {
      event_id: row!.id, user_id: auth.userId, user_name: u?.full_name || "Unknown", user_phone: u?.phone_number || "N/A",
      type, latitude: lat, longitude: lng, timestamp: new Date().toISOString(),
    });
    return json({ success: true, event_id: row!.id }, 201);
  });

  r.post("/emergency/tracking", "user", async ({ auth, body }) => {
    const eid = toInt(body?.emergency_id), lat = toNum(body?.latitude), lng = toNum(body?.longitude);
    if (!eid || lat === null || lng === null) {
      return json({ success: false, message: "emergency_id, latitude, longitude are required" }, 400);
    }
    const a = await q1(`select id from public.emergency_alerts where id = $1 and user_id = $2 and status = 'Active'`,
      [eid, auth.userId]);
    if (!a) return json({ success: false, message: "Active emergency not found" }, 404);
    const row = await q1(`insert into public.emergency_tracking (emergency_id, latitude, longitude) values ($1, $2, $3) returning id`,
      [eid, lat, lng]);
    await emit("emergency:admin", "emergency:tracking", {
      emergency_id: eid, user_id: auth.userId, latitude: lat, longitude: lng, timestamp: new Date().toISOString(),
    });
    return json({ success: true, tracking_id: row!.id });
  });

  r.get("/emergency/:id/tracking", "user", async ({ auth, params }) => {
    const id = idParam(params.id);
    const owner = await q1(`select user_id from public.emergency_alerts where id = $1`, [id]);
    if (!owner) return json({ success: false, message: "Alert not found" }, 404);
    if (owner.user_id !== auth.userId && !(await resolveAdmin(auth))) fail(403, "Forbidden");
    const rows = await q(`select id, latitude, longitude, "timestamp" from public.emergency_tracking
                          where emergency_id = $1 order by "timestamp" asc`, [id]);
    return json({ success: true, points: rows });
  });

  const setMyAlertStatus = async (id: number, userId: number, status: string) =>
    await exec(`update public.emergency_alerts set status = $1, resolved_at = $2 where id = $3 and user_id = $4`,
      [status, status === "Resolved" ? new Date().toISOString() : null, id, userId]);

  r.put("/emergency/:id/resolve", "user", async ({ auth, params }) => {
    const id = idParam(params.id);
    if (!(await setMyAlertStatus(id, auth.userId, "Resolved"))) return json({ success: false, message: "Alert not found" }, 404);
    await emit("emergency:admin", "emergency:resolved", { alert_id: id, user_id: auth.userId, timestamp: new Date().toISOString() });
    await notify(auth.userId, "✅ Emergency Resolved", "Your emergency alert has been marked as resolved. Stay safe.",
      "emergency_resolved", `/emergency/${id}`);
    return json({ success: true, message: "Emergency resolved" });
  });

  r.put("/emergency/:id/cancel", "user", async ({ auth, params }) => {
    const id = idParam(params.id);
    if (!(await setMyAlertStatus(id, auth.userId, "Cancelled"))) return json({ success: false, message: "Alert not found" }, 404);
    await emit("emergency:admin", "emergency:resolved", { alert_id: id, user_id: auth.userId, timestamp: new Date().toISOString() });
    return json({ success: true, message: "Emergency cancelled" });
  });

  r.put("/emergency/:id/acknowledge", "admin", async ({ params }) => {
    const id = idParam(params.id);
    const n = await exec(`update public.emergency_alerts set status = 'Acknowledged', acknowledged_at = now()
                          where id = $1 and status = 'Active'`, [id]);
    await emit("emergency:admin", "emergency:acknowledged", { alert_id: id, timestamp: new Date().toISOString() });
    return json({ success: true, affected: n });
  });

  // legacy /sos routes
  r.post("/sos/trigger", "user", async ({ auth, body }) => {
    const lat = toNum(body?.latitude) ?? 0, lng = toNum(body?.longitude) ?? 0;
    const row = await q1(`insert into public.sos_alerts (user_id, latitude, longitude, status) values ($1, $2, $3, 'Active') returning id`,
      [auth.userId, lat, lng]);
    await emit("emergency:admin", "sos_alert", { user_id: auth.userId, alert_id: row!.id, latitude: lat, longitude: lng, timestamp: new Date().toISOString() });
    return json({ success: true, alert_id: row!.id, message: "SOS activated - Emergency contacts notified" });
  });
  r.get("/sos/recent", "admin", async () => {
    const rows = await q(`select sa.id as alert_id, sa.user_id, sa.status, sa.created_at, u.full_name
                          from public.sos_alerts sa join public.users u on u.user_id = sa.user_id
                          where sa.status = 'Active' order by sa.created_at desc limit 20`);
    return json({ success: true, alerts: rows });
  });
  r.post("/sos/:alert_id/resolve", "user", async ({ auth, params }) => {
    const id = idParam(params.alert_id);
    const admin = await resolveAdmin(auth);
    await exec(`update public.sos_alerts set status = 'Resolved', resolved_at = now() where id = $1 ${admin ? "" : "and user_id = $2"}`,
      admin ? [id] : [id, auth.userId]);
    return json({ success: true, message: "SOS resolved" });
  });

  // ── emergency contacts (ICE) ──────────────────────────────────────────────
  r.get("/emergency-contacts", "user", async ({ auth }) => {
    const rows = await q(`select * from public.emergency_contacts where user_id = $1 order by is_primary desc, contact_id asc`,
      [auth.userId]);
    return json({ success: true, contacts: rows });
  });

  const contactFields = (b: any) => ({
    name: text(b?.contact_name, 255), phone: text(b?.contact_phone, 30), email: text(b?.contact_email, 255),
    rel: text(b?.relationship, 100), primary: b?.is_primary === true || b?.is_primary === 1,
  });

  r.post("/emergency-contacts", "user", async ({ auth, body }) => {
    const c = contactFields(body);
    if (!c.name || !c.phone) return json({ success: false, message: "contact_name and contact_phone are required" }, 400);
    const row = await tx(async (t) => {
      if (c.primary) await q(`update public.emergency_contacts set is_primary = false where user_id = $1`, [auth.userId], t);
      return await q1(
        `insert into public.emergency_contacts (user_id, contact_name, contact_phone, contact_email, relationship, is_primary)
         values ($1, $2, $3, $4, $5, $6) returning contact_id`,
        [auth.userId, c.name, c.phone, c.email, c.rel, c.primary], t);
    });
    return json({ success: true, contact_id: row!.contact_id }, 201);
  });

  r.put("/emergency-contacts/:id", "user", async ({ auth, params, body }) => {
    const c = contactFields(body);
    if (!c.name || !c.phone) return json({ success: false, message: "contact_name and contact_phone are required" }, 400);
    const n = await tx(async (t) => {
      if (c.primary) await q(`update public.emergency_contacts set is_primary = false where user_id = $1`, [auth.userId], t);
      return await exec(
        `update public.emergency_contacts set contact_name = $1, contact_phone = $2, contact_email = $3,
                relationship = $4, is_primary = $5 where contact_id = $6 and user_id = $7`,
        [c.name, c.phone, c.email, c.rel, c.primary, idParam(params.id), auth.userId], t);
    });
    if (!n) return json({ success: false, message: "Contact not found" }, 404);
    return json({ success: true });
  });

  r.delete("/emergency-contacts/:id", "user", async ({ auth, params }) => {
    const n = await exec(`delete from public.emergency_contacts where contact_id = $1 and user_id = $2`,
      [idParam(params.id), auth.userId]);
    if (!n) return json({ success: false, message: "Contact not found" }, 404);
    return json({ success: true });
  });

  // ── payments (Stripe) ─────────────────────────────────────────────────────
  // ── Payment amount: ONE server-side source of truth ──────────────────────
  // Hotel stays carry a server-built price_breakdown (rooms × nights + fees +
  // tax). Destination bookings keep the original rule: total + 10% tax.
  // Restaurant reservations are free (no payment).
  const quoteFor = (b: Record<string, any>) => {
    const pb = b.price_breakdown;
    if (pb && Number(pb.total) > 0) {
      return {
        subtotal: Number(pb.room_subtotal) + Number(pb.service_fee || 0), tax: Number(pb.tax),
        tax_rate: Number(pb.tax_rate), total: Number(pb.total), currency: "PKR", breakdown: pb,
      };
    }
    if (b.booking_type === "restaurant") return null;
    const subtotal = Number(b.total_amount) > 0
      ? Number(b.total_amount)
      : (Number(b.estimated_duration_days) || 1) * (Number(b.average_cost) || 50) * (Number(b.num_travelers) || 1);
    const tax = Math.round(subtotal * 0.10 * 100) / 100;
    return { subtotal, tax, tax_rate: 0.10, total: Math.round((subtotal + tax) * 100) / 100, currency: "PKR", breakdown: null };
  };

  // Charge currency is a server decision. Default: PKR (paisa, 2 decimals).
  // PAYMENT_CURRENCY=usd switches to USD using the admin-set usd_pkr_rate.
  const chargeFor = async (totalPkr: number) => {
    const cur = (Deno.env.get("PAYMENT_CURRENCY") || "pkr").toLowerCase();
    if (cur === "pkr") return { currency: "pkr", amount: Math.round(totalPkr * 100), fx_rate: null as number | null };
    if (cur !== "usd") throw new Error(`Unsupported PAYMENT_CURRENCY ${cur}`);
    const rate = Number((await q1(`select value from public.app_settings where key = 'usd_pkr_rate'`))?.value);
    if (!(rate > 0)) fail(503, "USD charging is enabled but no PKR→USD rate is configured. Contact support.");
    return { currency: "usd", amount: Math.round((totalPkr / rate) * 100), fx_rate: rate };
  };

  const loadPayable = async (bookingId: number, userId: number) => {
    const booking = await getBookingById(bookingId);
    if (!booking) fail(404, "Booking not found");
    if (booking!.user_id !== userId) fail(403, "Forbidden");
    return booking!;
  };

  /** Confirms the booking only if Stripe charged exactly what we recorded. */
  const markPaid = async (bookingId: number, piId: string, amountMinor: number, currency?: string) => {
    const rec = await q1(`select amount, currency from public.payments where stripe_payment_intent_id = $1`, [piId]);
    if (!rec) fail(409, "No payment record for this charge — not confirmed. Contact support.");
    if (Math.round(Number(rec!.amount) * 100) !== Number(amountMinor) ||
        (currency && String(rec!.currency).toLowerCase() !== String(currency).toLowerCase())) {
      console.error(`[payments] amount/currency mismatch for ${piId}: recorded ${rec!.amount} ${rec!.currency}, stripe ${amountMinor} ${currency}`);
      fail(409, "Payment amount does not match the booking — not confirmed. Contact support.");
    }
    return await tx(async (t) => {
      await q(`update public.bookings set payment_status = 'Paid', payment_intent_id = $1,
                      status = case when status in ('Pending', 'Awaiting Payment') then 'Confirmed' else status end
               where booking_id = $2`, [piId, bookingId], t);
      const pay = await q1(`update public.payments set status = 'succeeded' where stripe_payment_intent_id = $1
                            returning id`, [piId], t);
      if (pay) {
        const already = await q1(`select 1 from public.transactions where payment_id = $1 and status = 'completed'`, [pay.id], t);
        if (!already) {
          await q(`insert into public.transactions (payment_id, amount, status, transaction_reference)
                   values ($1, $2, 'completed', $3)`, [pay.id, amountMinor / 100, piId], t);
        }
      }
      return pay?.id ?? null;
    });
  };

  r.get("/payments/quote/:booking_id", "user", async ({ auth, params }) => {
    const b = await loadPayable(idParam(params.booking_id), auth.userId);
    const qt = quoteFor(b);
    if (!qt) return json({ success: true, payable: false, reason: "Restaurant reservations are free — no payment needed." });
    const charge = await chargeFor(qt.total);
    return json({
      success: true, payable: b.payment_status !== "Paid", booking_id: b.booking_id, ...qt,
      charge_currency: charge.currency.toUpperCase(), charge_amount: charge.amount / 100, fx_rate: charge.fx_rate,
    });
  });

  r.post("/payments/create-intent", "user", async ({ auth, body }) => {
    if (!stripeConfigured()) fail(500, "Stripe not configured. Set the STRIPE_SECRET_KEY secret.");
    const bookingId = toInt(body?.booking_id);
    if (!bookingId) fail(400, "booking_id is required");
    const booking = await loadPayable(bookingId!, auth.userId);
    if (booking.payment_status === "Paid") fail(400, "This booking is already paid");
    if (["Cancelled", "Refunded", "Completed"].includes(booking.status)) {
      fail(400, `Cannot pay for a ${booking.status} booking`);
    }
    // Any client-sent `amount` is ignored: the charge comes only from the
    // server-side quote.
    const qt = quoteFor(booking);
    if (!qt || !(qt.total > 0)) fail(400, "This booking has nothing to pay");

    // A hotel hold lapses after HOLD_MINUTES unpaid; re-check rooms are free.
    if (booking.booking_type === "hotel" && booking.room_type_id &&
        Date.now() - new Date(booking.created_at).getTime() > HOLD_MINUTES * 60000) {
      const free = await q1(
        `select rt.total_rooms - coalesce((select sum(b2.rooms) from public.bookings b2
            where b2.room_type_id = rt.room_type_id and b2.booking_id <> $1
              and b2.check_in < $3 and b2.check_out > $2
              and (b2.status in ('Confirmed','Active') or (b2.status in ('Pending','Awaiting Payment')
                   and b2.created_at > now() - make_interval(mins => $4)))), 0) as free
         from public.hotel_room_types rt where rt.room_type_id = $5`,
        [booking.booking_id, booking.check_in, booking.check_out, HOLD_MINUTES, booking.room_type_id]);
      if (Number(free?.free ?? 0) < Number(booking.rooms ?? 1)) {
        fail(409, "Your room hold expired and the rooms have since been booked. Please make a new booking.");
      }
    }

    const charge = await chargeFor(qt!.total);

    // Re-use an open PaymentIntent for the same booking/amount/currency
    // instead of creating a second one (no duplicate charges on retries).
    const open = await q1(
      `select stripe_payment_intent_id from public.payments
       where booking_id = $1 and user_id = $2 and status = 'pending' and amount = $3 and lower(currency) = $4
       order by created_at desc limit 1`, [bookingId, auth.userId, charge.amount / 100, charge.currency]);
    if (open) {
      const existing = await stripe("GET", `payment_intents/${encodeURIComponent(open.stripe_payment_intent_id)}`);
      if (existing.status === "succeeded") {
        await markPaid(bookingId!, existing.id, existing.amount, existing.currency);
        fail(400, "This booking is already paid");
      }
      if (["requires_payment_method", "requires_confirmation", "requires_action"].includes(existing.status)) {
        return json({
          success: true, clientSecret: existing.client_secret, paymentIntentId: existing.id,
          amount: existing.amount / 100, currency: String(existing.currency).toUpperCase(),
          quoted_total_pkr: qt!.total, fx_rate: charge.fx_rate, livemode: existing.livemode, reused: true,
        });
      }
    }

    const pi = await stripe("POST", "payment_intents", {
      amount: charge.amount, currency: charge.currency,
      automatic_payment_methods: { enabled: true },
      description: `SafarSync booking ${booking.booking_reference ?? bookingId}`,
      metadata: {
        booking_id: String(bookingId), user_id: String(auth.userId),
        quoted_total_pkr: String(qt!.total), charge_currency: charge.currency,
      },
    }, `pi-${bookingId}-${charge.currency}-${charge.amount}-${Math.floor(Date.now() / 600000)}`);
    await q(
      `insert into public.payments (user_id, booking_id, stripe_payment_intent_id, amount, currency, status)
       values ($1, $2, $3, $4, $5, 'pending')
       on conflict (stripe_payment_intent_id) do update set status = 'pending'`,
      [auth.userId, bookingId, pi.id, charge.amount / 100, charge.currency]);
    await exec(`update public.bookings set status = 'Awaiting Payment' where booking_id = $1 and status = 'Pending'`, [bookingId]);
    return json({
      success: true, clientSecret: pi.client_secret, paymentIntentId: pi.id,
      amount: charge.amount / 100, currency: charge.currency.toUpperCase(), quoted_total_pkr: qt!.total,
      fx_rate: charge.fx_rate, livemode: pi.livemode,
    });
  });

  r.post("/payments/confirm", "user", async ({ auth, body }) => {
    if (!stripeConfigured()) fail(500, "Stripe not configured. Set the STRIPE_SECRET_KEY secret.");
    const bookingId = toInt(body?.booking_id);
    const piId = text(body?.payment_intent_id, 255);
    if (!bookingId || !piId) fail(400, "booking_id and payment_intent_id are required");
    await loadPayable(bookingId!, auth.userId);
    const pi = await stripe("GET", `payment_intents/${encodeURIComponent(piId!)}`);
    if (String(pi.metadata?.user_id) !== String(auth.userId) || String(pi.metadata?.booking_id) !== String(bookingId)) {
      fail(403, "Payment does not belong to this user");
    }
    if (pi.status !== "succeeded") fail(400, `Payment not completed. Status: ${pi.status}`);
    const paymentId = await markPaid(bookingId!, piId!, pi.amount, pi.currency);
    return json({ success: true, message: "Payment confirmed. Booking is now Confirmed.", payment_id: paymentId });
  });

  // Stripe → webhook (configure https://<project>.supabase.co/functions/v1/api/payments/webhook)
  r.post("/payments/webhook", "public", async ({ req, rawBody }) => {
    const secret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
    if (!secret) fail(503, "Webhook not configured (STRIPE_WEBHOOK_SECRET)");
    const ok = await verifyStripeSignature(rawBody, req.headers.get("stripe-signature") ?? "", secret!);
    if (!ok) fail(400, "Webhook signature verification failed");
    const event = JSON.parse(rawBody);
    const obj = event?.data?.object ?? {};
    switch (event.type) {
      case "payment_intent.succeeded":
        if (obj.metadata?.booking_id) await markPaid(Number(obj.metadata.booking_id), obj.id, obj.amount, obj.currency);
        break;
      case "payment_intent.payment_failed":
      case "payment_intent.canceled":
        await exec(`update public.payments set status = 'failed' where stripe_payment_intent_id = $1`, [obj.id]);
        if (event.type === "payment_intent.canceled" && obj.metadata?.booking_id) {
          await exec(`update public.bookings set status = 'Cancelled' where booking_id = $1 and payment_status <> 'Paid'`,
            [Number(obj.metadata.booking_id)]);
        }
        break;
      case "charge.refunded": {
        const pay = obj.payment_intent
          ? await q1(`select id, booking_id from public.payments where stripe_payment_intent_id = $1`, [obj.payment_intent])
          : null;
        if (pay) {
          await exec(`update public.payments set status = 'refunded', refund_approved_at = coalesce(refund_approved_at, now())
                      where id = $1`, [pay.id]);
          if (pay.booking_id) {
            await exec(`update public.bookings set status = 'Refunded', payment_status = 'Refunded' where booking_id = $1`,
              [pay.booking_id]);
          }
          const dup = await q1(`select 1 from public.transactions where payment_id = $1 and status = 'refunded'
                                and transaction_reference = $2`, [pay.id, obj.id]);
          if (!dup) {
            await q(`insert into public.transactions (payment_id, amount, status, transaction_reference)
                     values ($1, $2, 'refunded', $3)`, [pay.id, (obj.amount_refunded ?? 0) / 100, obj.id]);
          }
        }
        break;
      }
    }
    return json({ received: true });
  });

  r.post("/payments/refund", "user", async ({ auth, body }) => {
    const bookingId = toInt(body?.booking_id);
    if (!bookingId) fail(400, "booking_id is required");
    const booking = await getBookingById(bookingId!);
    if (!booking) fail(404, "Booking not found");
    if (booking!.user_id !== auth.userId) fail(403, "Forbidden");
    if (booking!.payment_status !== "Paid") fail(400, "No paid payment to refund");
    if (!booking!.payment_intent_id) fail(400, "No payment intent found for this booking");
    const pay = await q1(`select id, refund_requested_at, refund_approved_at from public.payments
                          where stripe_payment_intent_id = $1`, [booking!.payment_intent_id]);
    if (!pay) fail(404, "Payment record not found");
    if (pay!.refund_approved_at) fail(400, "Refund already approved");
    if (pay!.refund_requested_at) fail(400, "Refund already requested — awaiting admin approval");
    await exec(`update public.payments set refund_requested_at = now() where id = $1`, [pay!.id]);
    return json({ success: true, message: "Refund request submitted. Our team will review it within 24-48 hours." });
  });

  r.get("/payments/history", "user", async ({ auth }) => {
    const rows = await q(
      `select p.*, b.booking_id, b.booking_type, b.booking_reference,
              coalesce(d.name, h.name, rs.name) as destination_name from public.payments p
       left join public.bookings b on b.booking_id = p.booking_id
       left join public.destinations d on d.destination_id = b.destination_id
       left join public.hotels h on h.hotel_id = b.hotel_id
       left join public.restaurants rs on rs.restaurant_id = b.restaurant_id
       where p.user_id = $1 order by p.created_at desc`, [auth.userId]);
    return json({ success: true, payments: rows });
  });

  r.get("/payments/:payment_id/receipt", "user", async ({ auth, params }) => {
    const row = await q1(
      `select p.*, b.booking_id, b.num_travelers, b.travel_date, b.booking_date, b.booking_reference,
              b.booking_type, b.check_in, b.check_out, b.rooms, b.price_breakdown,
              coalesce(d.name, (select name from public.hotels where hotel_id = b.hotel_id)) as destination_name,
              u.full_name, u.email,
              t.transaction_reference, t.created_at as transaction_date
       from public.payments p
       left join public.bookings b on b.booking_id = p.booking_id
       left join public.destinations d on d.destination_id = b.destination_id
       left join public.users u on u.user_id = p.user_id
       left join lateral (select transaction_reference, created_at from public.transactions
                          where payment_id = p.id and status = 'completed' order by id desc limit 1) t on true
       where p.id = $1 and p.user_id = $2`, [idParam(params.payment_id), auth.userId]);
    if (!row) fail(404, "Payment not found");
    return json({ success: true, receipt: row });
  });

  // ── AI ────────────────────────────────────────────────────────────────────
  r.post("/ai/chat", "user", async ({ auth, body }) => {
    const message = text(body?.message, 4000);
    if (!message) fail(400, "Message is required");
    const history = Array.isArray(body?.history) ? body.history.slice(-10) : [];
    const msgs = [
      { role: "system", content: SYSTEM_PROMPT },
      ...history.flatMap((h: any) => [
        h?.user_message ? { role: "user", content: String(h.user_message) } : null,
        h?.ai_response ? { role: "assistant", content: String(h.ai_response) } : null,
      ].filter(Boolean)),
      { role: "user", content: message },
    ];
    let reply: string;
    try {
      reply = (await groqChat(msgs as any)) || "I could not generate a response. Please try again.";
    } catch (e) {
      console.error("[ai] chat:", (e as Error).message);
      fail(502, groqConfigured() ? "AI service unavailable. Please try again later." : "AI service is not configured yet.");
    }
    const row = await q1(
      `insert into public.ai_chat_history (user_id, user_message, ai_response, context_data)
       values ($1, $2, $3, $4::text::jsonb) returning chat_id`,
      [auth.userId, message, reply!, JSON.stringify(body?.context_data ?? {})]);
    return json({ chat_id: row?.chat_id ?? null, user_message: message, ai_response: reply! });
  });

  r.post("/ai/wellness", "user", async ({ auth, body }) => {
    const message = text(body?.message, 4000);
    if (!message) fail(400, "Message is required");
    const history = Array.isArray(body?.history) ? body.history.slice(-6) : [];
    const msgs = [
      { role: "system", content: WELLNESS_PROMPT },
      ...history.flatMap((h: any) => {
        if (h?.role && h?.content) return [{ role: String(h.role) === "assistant" ? "assistant" : "user", content: String(h.content) }];
        const out = [];
        if (h?.user_message) out.push({ role: "user", content: String(h.user_message) });
        if (h?.ai_response) out.push({ role: "assistant", content: String(h.ai_response) });
        return out;
      }),
      { role: "user", content: message },
    ];
    let reply: string;
    try {
      reply = (await groqChat(msgs)) || "I'm here for you. Could you tell me a bit more?";
    } catch (e) {
      console.error("[ai] wellness:", (e as Error).message);
      fail(502, groqConfigured() ? "AI service unavailable. Please try again later." : "AI service is not configured yet.");
    }
    await q(`insert into public.mental_health_chat_history (user_id, user_message, ai_response) values ($1, $2, $3)`,
      [auth.userId, message, reply!]);
    return json({ user_message: message, ai_response: reply! });
  });

  r.get("/ai/recommendations", "user", async ({ auth, query }) => {
    const limit = clampLimit(query.get("limit"), 10, 50);
    const recs = await q(
      `select ar.*, d.name, d.city, d.country, d.description, d.image_url, d.rating
       from public.ai_recommendations ar join public.destinations d on d.destination_id = ar.destination_id
       where ar.user_id = $1 and not ar.viewed order by ar.confidence_score desc nulls last limit $2`,
      [auth.userId, limit]);
    if (recs.length) return json({ recommendations: recs });
    const dests = await q(
      `select destination_id, name, city, country, description, image_url, rating, average_cost, category
       from public.destinations order by rating desc nulls last, destination_id asc limit $1`, [limit]);
    return json({
      recommendations: dests.map((d) => ({
        id: null, user_id: auth.userId, destination_id: d.destination_id, title: `Discover ${d.name}`,
        description: d.description, confidence_score: d.rating ?? 0, category: d.category || "Popular",
        viewed: false, name: d.name, city: d.city, country: d.country, image_url: d.image_url, rating: d.rating,
      })),
    });
  });

  r.get("/ai/history", "user", async ({ auth, query }) => {
    const rows = await q(`select * from public.ai_chat_history where user_id = $1 order by created_at desc limit $2`,
      [auth.userId, clampLimit(query.get("limit"), 50, 200)]);
    return json({ chatHistory: rows.reverse() });
  });

  r.delete("/ai/history", "user", async ({ auth }) => {
    await exec(`delete from public.ai_chat_history where user_id = $1`, [auth.userId]);
    return json({ message: "Chat history cleared" });
  });

  r.post("/ai/recommendations/:id/rate", "user", async ({ auth, params, body }) => {
    await exec(`update public.ai_recommendations set viewed = true, helpful_rating = $1
                where recommendation_id = $2 and user_id = $3`, [body?.helpful ? 1 : 0, idParam(params.id), auth.userId]);
    return json({ message: "Recommendation rated" });
  });

  // ── tour packages (Sasta Tours) ───────────────────────────────────────────
  r.get("/tours/packages", "public", async ({ query }) => {
    const where = ["is_active"];
    const vals: unknown[] = [];
    const cat = text(query.get("category"), 100);
    if (cat && cat !== "all") { vals.push(cat); where.push(`lower(category) = lower($${vals.length})`); }
    const maxPrice = toNum(query.get("max_price"));
    if (maxPrice) { vals.push(maxPrice); where.push(`total_price <= $${vals.length}`); }
    const maxDays = toInt(query.get("max_days"));
    if (maxDays) { vals.push(maxDays); where.push(`duration_days <= $${vals.length}`); }
    const search = text(query.get("search"), 100);
    if (search) { vals.push(`%${search}%`); where.push(`(title ilike $${vals.length} or description ilike $${vals.length})`); }
    const rows = await q(`select * from public.tour_packages where ${where.join(" and ")} order by total_price asc`, vals);
    return json({ success: true, packages: rows.map(parsePkg) });
  });

  r.get("/tours/packages/:id", "public", async ({ params }) => {
    const row = await q1(`select * from public.tour_packages where package_id = $1 and is_active`, [idParam(params.id)]);
    if (!row) fail(404, "Package not found");
    return json({ success: true, package: parsePkg(row!) });
  });

  r.post("/tours/budget-plan", "user", async ({ auth, body }) => {
    const budget = toNum(body?.budget_amount);
    const days = toInt(body?.duration_days);
    if (!budget || !days) fail(400, "budget_amount and duration_days are required");
    if (budget! <= 0 || days! <= 0 || days! > 60) fail(400, "Invalid budget or duration");
    const travelers = Math.max(toInt(body?.num_travelers, 1)!, 1);
    const perPerson = Math.round(budget! / travelers);
    const startCity = text(body?.start_city, 100);
    const prefs = text(body?.preferences, 500);

    const pkgs = (await q(`select * from public.tour_packages where is_active and total_price <= $1 and duration_days <= $2
                           order by total_price asc limit 3`, [budget, days])).map(parsePkg);
    const dests = await q(
      `select destination_id, name, city, country, category, average_cost, description from public.destinations
       where average_cost is not null and average_cost <= $1 order by rating desc nulls last limit 8`, [perPerson * days!]);

    let plan: any = null;
    if (groqConfigured()) {
      const prompt = `You are a Pakistan travel expert. Generate a detailed budget travel plan with this exact JSON structure.

User requirements:
- Total budget: PKR ${budget} for ${travelers} traveler(s)
- Per person budget: PKR ${perPerson}
- Duration: ${days} days
- Start city: ${startCity || "any city in Pakistan"}
- Preferences: ${prefs || "nature, adventure, culture"}

Available affordable destinations: ${dests.map((d) => `${d.name} (${d.city}, avg cost PKR ${d.average_cost}/day)`).join(", ")}

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "title": "Trip name",
  "total_estimated_cost": 0,
  "daily_budget": 0,
  "recommended_destinations": ["dest1", "dest2"],
  "itinerary": [
    {"day": 1, "location": "City", "activities": ["Activity 1", "Activity 2"], "estimated_cost": 0, "transport": "How to get there", "accommodation": "Where to stay"}
  ],
  "money_saving_tips": ["tip1", "tip2", "tip3"],
  "best_time_to_go": "Month/Season",
  "included_in_budget": ["item1", "item2"],
  "not_included": ["item1"]
}`;
      try {
        const raw = await groqChat([{ role: "user", content: prompt }], { maxTokens: 1000, temperature: 0.6, timeoutMs: 45000 });
        const m = raw.match(/\{[\s\S]*\}/);
        if (m) plan = JSON.parse(m[0]);
      } catch (e) {
        console.error("[ai] budget plan (non-fatal):", (e as Error).message);
      }
    }
    if (!plan) plan = fallbackPlan(budget!, travelers, days!, dests);
    await q(`insert into public.budget_plans (user_id, budget_amount, num_travelers, duration_days, start_city, preferences, generated_plan)
             values ($1, $2, $3, $4, $5, $6, $7::text::jsonb)`,
      [auth.userId, budget, travelers, days, startCity, prefs, JSON.stringify(plan)]).catch(() => {});
    return json({ success: true, budget_plan: plan, matching_packages: pkgs, affordable_destinations: dests.slice(0, 6) });
  });

  r.get("/tours/budget-history", "user", async ({ auth }) => {
    const rows = await q(`select * from public.budget_plans where user_id = $1 order by created_at desc limit 10`, [auth.userId]);
    return json({ success: true, plans: rows });
  });

  // ── virtual tours ─────────────────────────────────────────────────────────
  r.get("/virtual-tours", "public", async ({ query }) => {
    const destId = toInt(query.get("destination_id"));
    const rows = await q(
      `select vt.*, d.name as destination_name,
              (select count(*) from public.virtual_tour_scenes where tour_id = vt.id) as scene_count
       from public.virtual_tours vt left join public.destinations d on d.destination_id = vt.destination_id
       where vt.is_active ${destId ? "and vt.destination_id = $1" : ""} order by vt.created_at desc`,
      destId ? [destId] : []);
    return json({ success: true, tours: rows });
  });

  r.get("/virtual-tours/destination/:destinationId", "public", async ({ params }) => {
    const row = await q1(`select id from public.virtual_tours where destination_id = $1 and is_active limit 1`,
      [idParam(params.destinationId)]);
    if (!row) fail(404, "No virtual tour for this destination");
    return json({ success: true, tour: await getTourById(row!.id) });
  });

  r.get("/virtual-tours/:id", "public", async ({ params }) => {
    const tour = await getTourById(idParam(params.id));
    if (!tour) fail(404, "Tour not found");
    return json({ success: true, tour });
  });

  r.post("/virtual-tours/narration", "user", async ({ body }) => {
    let sceneName = text(body?.scene_name, 200);
    const sceneId = toInt(body?.scene_id);
    let tourTitle = text(body?.tour_title, 200);
    let destName = text(body?.destination_name, 200);
    let canCache = false;
    if (sceneId) {
      const scene = await q1(
        `select s.scene_name, s.ai_narration, vt.title as tour_title, d.name as destination_name
         from public.virtual_tour_scenes s
         join public.virtual_tours vt on vt.id = s.tour_id
         left join public.destinations d on d.destination_id = vt.destination_id
         where s.id = $1`, [sceneId]);
      if (scene?.ai_narration) return json({ success: true, narration: scene.ai_narration, cached: true });
      // Narration is cached for every visitor, so build it only from stored
      // data, never from client text (prevents cache poisoning).
      if (scene) {
        sceneName = scene.scene_name;
        tourTitle = scene.tour_title ?? null;
        destName = scene.destination_name ?? null;
        canCache = true;
      }
    }
    if (!sceneName) fail(400, "scene_name required");
    if (!groqConfigured()) fail(503, "AI service not configured");
    const prompt = [
      "You are a professional tour guide narrating a virtual 360° tour of Pakistan.",
      `You are currently at: ${sceneName}`,
      tourTitle ? `As part of the "${tourTitle}" tour.` : "",
      destName ? `Destination: ${destName}.` : "",
      "Provide a 3-4 sentence engaging narration. Include:",
      "- What the visitor is seeing right now",
      "- A key historical or natural fact",
      "- A travel tip or interesting detail",
      "Keep it warm, vivid, and under 80 words. Do not use bullet points.",
    ].filter(Boolean).join(" ");
    try {
      const narration = (await groqChat([{ role: "user", content: prompt }], { maxTokens: 200, temperature: 0.75 })).trim() ||
        "Welcome to this incredible location. Take a moment to look around in every direction.";
      if (canCache) {
        await exec(`update public.virtual_tour_scenes set ai_narration = $1
                    where id = $2 and coalesce(ai_narration, '') = ''`, [narration, sceneId]);
      }
      return json({ success: true, narration });
    } catch (e) {
      console.error("[ai] narration:", (e as Error).message);
      fail(500, "Failed to generate narration");
    }
    return json({});
  });
}
