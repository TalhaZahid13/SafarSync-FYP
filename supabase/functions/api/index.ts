// SafarSync API — Supabase Edge Function.
//
// Replaces the Node/Express + MySQL backend (lib/backend). Same endpoints and
// response shapes, so the Flutter app talks to:
//   https://<project-ref>.supabase.co/functions/v1/api/<endpoint>
// with the user's Supabase session JWT in the Authorization header.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { authenticate, resolveAdmin } from "./lib/auth.ts";
import { corsHeaders, type Ctx, HttpError, json, Router } from "./lib/http.ts";
import { registerCore } from "./routes/core.ts";
import { registerTrips } from "./routes/trips.ts";
import { registerFeatures } from "./routes/features.ts";
import { registerAdmin } from "./routes/admin.ts";

const router = new Router();
router.get("/health", "public", () => json({ status: "OK", timestamp: new Date().toISOString() }));
registerCore(router);
registerTrips(router);
registerFeatures(router);
registerAdmin(router);

// Simple per-isolate rate limits (mirrors express-rate-limit settings).
const buckets = new Map<string, { n: number; reset: number }>();
function rateLimited(key: string, max: number, windowMs: number) {
  const now = Date.now();
  const b = buckets.get(key);
  if (!b || b.reset < now) {
    if (buckets.size > 5000) buckets.clear();
    buckets.set(key, { n: 1, reset: now + windowMs });
    return false;
  }
  b.n++;
  return b.n > max;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const url = new URL(req.url);
  // pathname is /api/<endpoint> (function name prefix); tolerate /functions/v1/api too
  const path = url.pathname.replace(/^\/functions\/v1/, "").replace(/^\/api(?=\/|$)/, "") || "/";
  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";

  try {
    const found = router.match(req.method, path);
    if (!found) return json({ error: "Endpoint not found" }, 404);
    const { route, params } = found;

    if (rateLimited(`g:${ip}`, 300, 60_000)) return json({ error: "Too many requests, slow down." }, 429);
    if (path.startsWith("/ai") && rateLimited(`ai:${ip}`, 30, 60_000)) {
      return json({ error: "AI rate limit exceeded." }, 429);
    }

    const rawBody = ["POST", "PUT", "PATCH", "DELETE"].includes(req.method) ? await req.text() : "";
    let body: any = {};
    if (rawBody && !path.startsWith("/payments/webhook")) {
      try { body = JSON.parse(rawBody); } catch { return json({ error: "Invalid JSON body" }, 400); }
    }

    const authOrNull = route.access === "public" ? null : await authenticate(req);
    if ((route.access === "user" || route.access === "admin") && !authOrNull) {
      return json({ error: "Authorization token is required" }, 401);
    }
    if (route.access === "admin") {
      const admin = await resolveAdmin(authOrNull!);
      if (!admin) return json({ error: "Access denied: admin privileges required" }, 403);
    }

    const ctx: Ctx = {
      req, params, query: url.searchParams, body, rawBody, ip,
      auth: authOrNull as Ctx["auth"], authOrNull,
    };
    return await route.handler(ctx);
  } catch (e) {
    if (e instanceof HttpError) return json(e.body, e.status);
    console.error(`[api] ${req.method} ${path} failed:`, e);
    return json({ error: "Internal server error" }, 500);
  }
});
