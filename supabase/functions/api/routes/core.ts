// auth, users, notifications, location, wishlist, destinations, routes, weather
import { exec, isFkViolation, isUniqueViolation, q, q1 } from "../lib/db.ts";
import { clampLimit, fail, idParam, json, type Router, text, toInt, toNum } from "../lib/http.ts";
import { resolveAdmin } from "../lib/auth.ts";
import { currentWeather, weatherForecast } from "../lib/external.ts";
import { emit } from "../lib/notify.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

/** Delete a Supabase Auth user (cascades to public.users via FK). */
export async function deleteAuthUser(authUserId: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${authUserId}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${SERVICE_KEY}`, apikey: SERVICE_KEY },
  });
  if (!res.ok && res.status !== 404) throw new Error(`Auth delete failed (${res.status})`);
}

// Destination row in the shape every screen expects (old `destination`
// endpoint + local SQLite seed keys: id/location/image/reviews/price).
export const DEST_COLS = `
  d.destination_id as id, d.destination_id, d.name,
  coalesce(d.location, d.city, d.country) as location,
  d.city, d.country, d.category, d.description,
  d.image_url, d.image_url as image,
  coalesce(d.rating, 4.5) as rating, d.review_count, d.review_count as reviews,
  d.average_cost, d.price_label as price, d.latitude, d.longitude, d.best_time_to_visit`;

export function registerCore(r: Router) {
  // ── auth ──────────────────────────────────────────────────────────────────
  // Called by the app after every Supabase sign-in (email, Google, Apple).
  // Replaces POST /auth/firebase-exchange: records the login and returns the
  // integer user id + flags the UI caches.
  r.post("/auth/session", "user", async ({ auth, body }) => {
    const sets = ["last_login_at = now()"];
    const vals: unknown[] = [];
    const add = (col: string, v: unknown) => { vals.push(v); sets.push(`${col} = $${vals.length}`); };
    const provider = String(auth.authUser.app_metadata?.provider ?? "email").toLowerCase();
    add("auth_provider", provider === "google" ? "GOOGLE" : provider === "apple" ? "APPLE" : "EMAIL");
    if (text(body?.phone_number, 30)) add("phone_number", text(body.phone_number, 30));
    if (text(body?.blood_group, 10)) add("blood_group", text(body.blood_group, 10));
    if (text(body?.full_name, 255) && !auth.user.full_name) add("full_name", text(body.full_name, 255));
    if (text(body?.profile_picture_url, 1000) && !auth.user.profile_picture_url) {
      add("profile_picture_url", text(body.profile_picture_url, 1000));
    }
    vals.push(auth.userId);
    const u = await q1(
      `update public.users set ${sets.join(", ")} where user_id = $${vals.length}
       returning user_id, email, full_name, auth_provider, role, is_admin, profile_picture_url`,
      vals,
    );
    return json({
      success: true,
      user: { ...u, firebase_uid: auth.authUser.id, is_admin: !!u?.is_admin },
    });
  });

  r.get("/auth/me", "user", async ({ auth }) => {
    const u = await q1(
      `select user_id, email, full_name, phone_number, profile_picture_url, blood_group, bio,
              is_admin, role, auth_provider, theme_preference, created_at, last_login_at
       from public.users where user_id = $1`, [auth.userId]);
    if (!u) fail(404, "User not found");
    return json({ success: true, user: u });
  });

  // Admin panel session check (replaces /admin/auth/login + /admin/auth/me)
  r.get("/admin/auth/me", "user", async ({ auth }) => {
    const admin = await resolveAdmin(auth);
    if (!admin) fail(403, "Access denied: admin privileges required");
    await exec(`update public.admins set last_login = now() where auth_user_id = $1`, [auth.authUser.id]);
    return json({
      success: true,
      admin: { admin_id: admin!.adminId, email: admin!.email, full_name: admin!.adminName, role: admin!.role },
    });
  });

  // ── users ─────────────────────────────────────────────────────────────────
  r.get("/users/profile", "user", async ({ auth }) => {
    const u = await q1(
      `select u.user_id, u.email, u.full_name, u.phone_number, u.city, u.profile_picture_url,
              u.blood_group, u.bio, u.created_at, u.is_admin, u.auth_provider, u.role, u.last_login_at,
              (select count(*) from public.bookings where user_id = u.user_id) as total_bookings,
              (select count(*) from public.group_booking_members where user_id = u.user_id) as group_trips,
              (select count(*) from public.wishlists where user_id = u.user_id) as wishlist_count,
              (select count(*) from public.emergency_alerts where user_id = u.user_id and status = 'Active') as active_sos
       from public.users u where u.user_id = $1`, [auth.userId]);
    if (!u) fail(404, "User not found");
    return json({ success: true, user: { ...u, firebase_uid: auth.authUser.id } });
  });

  r.put("/users/profile", "user", async ({ auth, body }) => {
    const fields: string[] = [];
    const vals: unknown[] = [];
    const limits: Record<string, number> = {
      full_name: 255, phone_number: 30, blood_group: 10, bio: 2000, profile_picture_url: 1000, city: 100,
    };
    for (const [col, max] of Object.entries(limits)) {
      if (body?.[col] !== undefined) {
        const v = body[col] === null ? null : String(body[col]).trim().slice(0, max);
        if (col === "full_name" && !v) fail(400, "full_name cannot be empty");
        vals.push(v);
        fields.push(`${col} = $${vals.length}`);
      }
    }
    if (!fields.length) fail(400, "No fields to update");
    vals.push(auth.userId);
    await exec(`update public.users set ${fields.join(", ")} where user_id = $${vals.length}`, vals);
    return json({ success: true, message: "Profile updated" });
  });

  r.get("/users/stats", "user", async ({ auth }) => {
    const s = await q1(
      `select (select count(*) from public.bookings where user_id = $1) as total_bookings,
              (select count(*) from public.bookings where user_id = $1 and status = 'Completed') as completed_trips,
              (select count(*) from public.group_booking_members where user_id = $1) as group_trips,
              (select count(*) from public.wishlists where user_id = $1) as wishlist_count,
              (select count(*) from public.emergency_alerts where user_id = $1) as total_sos,
              (select count(*) from public.ai_chat_history where user_id = $1) as ai_chats`, [auth.userId]);
    return json({ success: true, stats: s ?? {} });
  });

  r.get("/users/preferences", "user", async ({ auth }) => {
    const p = await q1(`select * from public.user_preferences where user_id = $1`, [auth.userId]);
    return json({
      success: true,
      preferences: p ?? {
        language: "en", theme: "dark", notifications_enabled: true, weather_alerts: true,
        traffic_alerts: true, emergency_sharing_enabled: true,
      },
    });
  });

  r.put("/users/preferences", "user", async ({ auth, body }) => {
    const b = body ?? {};
    await q(
      `insert into public.user_preferences
         (user_id, language, theme, notifications_enabled, weather_alerts, traffic_alerts,
          emergency_sharing_enabled, preferred_categories)
       values ($1, $2, $3, coalesce($4, true), coalesce($5, true), coalesce($6, true), coalesce($7, true), $8::text::jsonb)
       on conflict (user_id) do update set
         language = excluded.language, theme = excluded.theme,
         notifications_enabled = excluded.notifications_enabled,
         weather_alerts = excluded.weather_alerts, traffic_alerts = excluded.traffic_alerts,
         emergency_sharing_enabled = excluded.emergency_sharing_enabled,
         preferred_categories = excluded.preferred_categories`,
      [auth.userId, b.language ?? null, b.theme ?? null, b.notifications_enabled ?? null,
       b.weather_alerts ?? null, b.traffic_alerts ?? null, b.emergency_sharing_enabled ?? null,
       b.preferred_categories ? JSON.stringify(b.preferred_categories) : null],
    );
    return json({ success: true, message: "Preferences updated" });
  });

  r.get("/users/search", "user", async ({ query }) => {
    const email = text(query.get("email"), 255);
    if (!email) fail(400, "email query parameter required");
    const u = await q1(
      `select user_id, full_name, email, profile_picture_url from public.users
       where lower(email) = lower($1) and not is_blocked limit 1`, [email]);
    if (!u) fail(404, "User not found");
    return json({ success: true, user: u });
  });

  r.delete("/users/account", "user", async ({ auth }) => {
    await deleteAuthUser(auth.authUser.id);
    await exec(`delete from public.users where user_id = $1`, [auth.userId]); // no-op if cascaded
    return json({ success: true, message: "Account deleted" });
  });

  r.put("/users/theme-preference", "user", async ({ auth, body }) => {
    const t = body?.theme_preference;
    if (!["default", "snow", "desert", "beach", "mountain", "forest", "urban"].includes(t)) {
      fail(400, "Invalid theme_preference");
    }
    await exec(`update public.users set theme_preference = $1 where user_id = $2`, [t, auth.userId]);
    return json({ success: true, theme_preference: t });
  });

  r.get("/users", "public", () => json({ message: "User routes active" }));

  // ── notifications ─────────────────────────────────────────────────────────
  r.get("/notifications/unread-count", "user", async ({ auth }) => {
    const row = await q1(
      `select count(*) as count from public.notifications where user_id = $1 and not is_read`, [auth.userId]);
    return json({ success: true, count: row?.count ?? 0 });
  });

  r.get("/notifications", "user", async ({ auth, query }) => {
    const limit = clampLimit(query.get("limit"), 20, 200);
    const unreadOnly = query.get("unread_only") === "true";
    const rows = await q(
      `select * from public.notifications where user_id = $1 ${unreadOnly ? "and not is_read" : ""}
       order by created_at desc limit $2`, [auth.userId, limit]);
    return json({ notifications: rows });
  });

  r.put("/notifications/read/all", "user", async ({ auth }) => {
    await exec(`update public.notifications set is_read = true where user_id = $1 and not is_read`, [auth.userId]);
    return json({ message: "All notifications marked as read" });
  });

  r.put("/notifications/:id/read", "user", async ({ auth, params }) => {
    await exec(`update public.notifications set is_read = true where notification_id = $1 and user_id = $2`,
      [idParam(params.id), auth.userId]);
    return json({ message: "Notification marked as read" });
  });

  r.delete("/notifications/:id", "user", async ({ auth, params }) => {
    await exec(`delete from public.notifications where notification_id = $1 and user_id = $2`,
      [idParam(params.id), auth.userId]);
    return json({ message: "Notification deleted" });
  });

  // ── location ──────────────────────────────────────────────────────────────
  // Previously unauthenticated (anyone could read anyone's position). Now the
  // caller can only write/read their own location history.
  r.post("/location/update", "user", async ({ auth, body }) => {
    const lat = toNum(body?.latitude), lng = toNum(body?.longitude);
    if (lat === null || lng === null) {
      return json({ success: false, error: "latitude and longitude are required numeric values" }, 400);
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return json({ success: false, error: "Invalid coordinate range" }, 400);
    }
    const capturedAt = body?.captured_at ? new Date(body.captured_at) : new Date();
    if (Number.isNaN(capturedAt.getTime())) {
      return json({ success: false, error: "captured_at must be a valid ISO datetime" }, 400);
    }
    const accuracy = toNum(body?.accuracy);
    let city = text(body?.city, 100), country = text(body?.country, 100);

    // nearest known destination city (same logic as the old controller)
    const near = await q1(
      `select city, country from public.destinations
       where latitude is not null and longitude is not null and coalesce(trim(city), '') <> ''
       order by (6371 * acos(least(1, greatest(-1,
                  cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2))
                + sin(radians($1)) * sin(radians(latitude)))))) asc
       limit 1`, [lat, lng]);
    if (near) { city = near.city ?? city; country = near.country ?? country; }

    const identifier = `user_${auth.userId}`;
    const lastLocation = [city, country].filter(Boolean).join(", ") || `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    const row = await q1(
      `insert into public.user_location_updates
         (user_identifier, latitude, longitude, city, country, accuracy_meters, captured_at)
       values ($1, $2, $3, $4, $5, $6, $7) returning location_update_id`,
      [identifier, lat, lng, city, country, accuracy, capturedAt.toISOString()]);
    const updated = await exec(
      `update public.users set last_location = $1, last_latitude = $2, last_longitude = $3,
              last_location_updated_at = $4 where user_id = $5`,
      [lastLocation, lat, lng, capturedAt.toISOString(), auth.userId]);

    const payload = {
      user_identifier: identifier, user_id: auth.userId, user_name: auth.name,
      latitude: lat, longitude: lng, city, country, accuracy_meters: accuracy,
      captured_at: capturedAt.toISOString(), last_location: lastLocation,
    };
    // live map for admins (was io.emit('location:updated'))
    await emit("emergency:admin", "location:updated", payload);
    // forward group-trip positions to the admin emergency map
    const gid = toInt(body?.group_booking_id);
    if (gid) {
      await emit("emergency:admin", "location:group-updated", {
        user_id: auth.userId, user_name: auth.name, latitude: lat, longitude: lng,
        group_booking_id: gid, timestamp: new Date().toISOString(),
      });
    }
    return json({
      success: true, message: "Location updated", location_id: row?.location_update_id,
      traveler_updated: updated > 0, location: payload,
    }, 201);
  });

  r.get("/location/latest", "user", async ({ auth }) => {
    const row = await q1(
      `select location_update_id, user_identifier, latitude, longitude, city, country,
              accuracy_meters, captured_at, created_at
       from public.user_location_updates where user_identifier = $1
       order by captured_at desc, created_at desc limit 1`, [`user_${auth.userId}`]);
    if (!row) return json({ success: false, error: "No location data found" }, 404);
    return json({ success: true, location: row });
  });

  // ── wishlist ──────────────────────────────────────────────────────────────
  r.get("/wishlist", "user", async ({ auth, query }) => {
    const page = Math.max(toInt(query.get("page"), 1)!, 1);
    const limit = clampLimit(query.get("limit"), 10, 100);
    const rows = await q(
      `select ${DEST_COLS}, w.wishlist_id, w.user_id, w.notes, w.priority, w.planned_visit_date, w.created_at
       from public.wishlists w join public.destinations d on d.destination_id = w.destination_id
       where w.user_id = $1 order by w.created_at desc limit $2 offset $3`,
      [auth.userId, limit, (page - 1) * limit]);
    return json({ wishlist: rows, page, limit });
  });

  r.post("/wishlist", "user", async ({ auth, body }) => {
    const destId = toInt(body?.destination_id);
    if (!destId) fail(400, "destination_id is required");
    try {
      const row = await q1(
        `insert into public.wishlists (user_id, destination_id, notes, priority, planned_visit_date)
         values ($1, $2, $3, $4, $5) returning wishlist_id`,
        [auth.userId, destId, text(body.notes, 2000), text(body.priority, 50), body.planned_visit_date || null]);
      return json({ message: "Added to wishlist", wishlist_id: row?.wishlist_id }, 201);
    } catch (e) {
      if (isUniqueViolation(e)) fail(409, "Destination already in wishlist");
      if (isFkViolation(e)) fail(404, "Destination not found");
      throw e;
    }
  });

  r.get("/wishlist/check/:destinationId", "user", async ({ auth, params }) => {
    const row = await q1(`select 1 from public.wishlists where user_id = $1 and destination_id = $2`,
      [auth.userId, idParam(params.destinationId)]);
    return json({ inWishlist: !!row });
  });

  r.delete("/wishlist/:destinationId", "user", async ({ auth, params }) => {
    await exec(`delete from public.wishlists where user_id = $1 and destination_id = $2`,
      [auth.userId, idParam(params.destinationId)]);
    return json({ message: "Removed from wishlist" });
  });

  r.put("/wishlist/:destinationId", "user", async ({ auth, params, body }) => {
    await exec(
      `update public.wishlists set notes = $1, priority = $2, planned_visit_date = $3
       where user_id = $4 and destination_id = $5`,
      [text(body?.notes, 2000), text(body?.priority, 50), body?.planned_visit_date || null,
       auth.userId, idParam(params.destinationId)]);
    return json({ message: "Wishlist item updated" });
  });

  // ── destinations (public catalogue) ───────────────────────────────────────
  r.get("/destinations", "public", async ({ query }) => {
    const page = Math.max(toInt(query.get("page"), 1)!, 1);
    const limit = clampLimit(query.get("limit"), 10, 200);
    const where: string[] = [];
    const vals: unknown[] = [];
    for (const key of ["category", "city", "country"]) {
      const v = text(query.get(key), 100);
      if (v) { vals.push(v); where.push(`lower(d.${key}) = lower($${vals.length})`); }
    }
    vals.push(limit, (page - 1) * limit);
    const rows = await q(
      `select ${DEST_COLS} from public.destinations d
       ${where.length ? "where " + where.join(" and ") : ""}
       order by d.rating desc nulls last, d.name asc
       limit $${vals.length - 1} offset $${vals.length}`, vals);
    return json({ destinations: rows, page, limit });
  });

  r.get("/destinations/search", "public", async ({ query }) => {
    const term = text(query.get("query") ?? query.get("q"), 100);
    if (!term) fail(400, "Search query is required");
    const like = `%${term}%`;
    const rows = await q(
      `select ${DEST_COLS} from public.destinations d
       where d.name ilike $1 or d.location ilike $1 or d.city ilike $1 or d.category ilike $1
          or d.description ilike $1
       order by d.rating desc nulls last, d.name asc limit 50`, [like]);
    return json({ results: rows });
  });

  r.get("/destinations/popular/trending", "public", async () => {
    const rows = await q(
      `select ${DEST_COLS} from public.destinations d
       order by d.popularity_score desc, d.rating desc nulls last limit 10`);
    return json({ destinations: rows });
  });

  r.get("/destinations/category/:category", "public", async ({ params, query }) => {
    const page = Math.max(toInt(query.get("page"), 1)!, 1);
    const limit = clampLimit(query.get("limit"), 10, 100);
    const rows = await q(
      `select ${DEST_COLS} from public.destinations d where lower(d.category) = lower($1)
       order by d.rating desc nulls last limit $2 offset $3`,
      [params.category, limit, (page - 1) * limit]);
    return json({ destinations: rows, category: params.category, page, limit });
  });

  r.get("/destinations/:id", "public", async ({ params }) => {
    const row = await q1(`select ${DEST_COLS} from public.destinations d where d.destination_id = $1`,
      [idParam(params.id)]);
    if (!row) fail(404, "Destination not found");
    return json({ destination: row });
  });

  const destFields = ["name", "description", "latitude", "longitude", "location", "city", "country",
    "category", "image_url", "rating", "best_time_to_visit", "average_cost", "price_label"];

  r.post("/destinations", "admin", async ({ body }) => {
    if (!text(body?.name)) fail(400, "name is required");
    const cols = destFields.filter((f) => body[f] !== undefined);
    const row = await q1(
      `insert into public.destinations (${cols.join(", ")}) values (${cols.map((_, i) => `$${i + 1}`).join(", ")})
       returning destination_id`, cols.map((c) => body[c]));
    return json({ message: "Destination created successfully", destination_id: row?.destination_id }, 201);
  });

  r.put("/destinations/:id", "admin", async ({ params, body }) => {
    const cols = destFields.filter((f) => body?.[f] !== undefined);
    if (!cols.length) fail(400, "No fields to update");
    const vals = cols.map((c) => body[c]);
    vals.push(idParam(params.id));
    await exec(`update public.destinations set ${cols.map((c, i) => `${c} = $${i + 1}`).join(", ")}
                where destination_id = $${vals.length}`, vals);
    return json({ message: "Destination updated successfully" });
  });

  r.delete("/destinations/:id", "admin", async ({ params }) => {
    await exec(`delete from public.destinations where destination_id = $1`, [idParam(params.id)]);
    return json({ message: "Destination deleted successfully" });
  });

  // ── user routes (trip planner) ────────────────────────────────────────────
  r.post("/routes", "user", async ({ auth, body }) => {
    const name = text(body?.route_name, 255);
    if (!name) fail(400, "route_name is required");
    const row = await q1(
      `insert into public.routes (user_id, route_name, description, start_location, end_location,
                                  start_lat, start_lng, end_lat, end_lng, difficulty_level, is_public)
       values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) returning route_id`,
      [auth.userId, name, text(body.description, 4000), text(body.start_location), text(body.end_location),
       toNum(body.start_lat), toNum(body.start_lng), toNum(body.end_lat), toNum(body.end_lng),
       text(body.difficulty_level, 50), body.is_public === true]);
    return json({ message: "Route created successfully", route_id: row?.route_id }, 201);
  });

  r.get("/routes/public/trending", "user", async () => {
    const rows = await q(
      `select * from public.routes where is_public order by views_count desc, created_at desc limit 20`);
    return json({ routes: rows });
  });

  r.get("/routes", "user", async ({ auth, query }) => {
    const page = Math.max(toInt(query.get("page"), 1)!, 1);
    const limit = clampLimit(query.get("limit"), 10, 100);
    const rows = await q(
      `select * from public.routes where user_id = $1 order by created_at desc limit $2 offset $3`,
      [auth.userId, limit, (page - 1) * limit]);
    return json({ routes: rows, page, limit });
  });

  r.get("/routes/:id", "user", async ({ auth, params }) => {
    const row = await q1(
      `select * from public.routes where route_id = $1 and (user_id = $2 or is_public)`,
      [idParam(params.id), auth.userId]);
    if (!row) fail(404, "Route not found");
    const stops = await q(`select * from public.route_stops where route_id = $1 order by stop_order`, [row!.route_id]);
    return json({ route: { ...row, stops } });
  });

  r.put("/routes/:id", "user", async ({ auth, params, body }) => {
    const allowed = ["route_name", "description", "start_location", "end_location", "start_lat", "start_lng",
      "end_lat", "end_lng", "difficulty_level", "is_public", "total_distance", "estimated_duration"];
    const cols = allowed.filter((c) => body?.[c] !== undefined);
    if (!cols.length) fail(400, "No fields to update");
    const vals = cols.map((c) => body[c]);
    vals.push(idParam(params.id), auth.userId);
    const n = await exec(
      `update public.routes set ${cols.map((c, i) => `${c} = $${i + 1}`).join(", ")}
       where route_id = $${vals.length - 1} and user_id = $${vals.length}`, vals);
    if (!n) fail(404, "Route not found");
    return json({ message: "Route updated successfully" });
  });

  r.delete("/routes/:id", "user", async ({ auth, params }) => {
    const n = await exec(`delete from public.routes where route_id = $1 and user_id = $2`,
      [idParam(params.id), auth.userId]);
    if (!n) fail(404, "Route not found");
    return json({ message: "Route deleted successfully" });
  });

  r.post("/routes/:id/stops", "user", async ({ auth, params, body }) => {
    const route = await q1(`select route_id from public.routes where route_id = $1 and user_id = $2`,
      [idParam(params.id), auth.userId]);
    if (!route) fail(404, "Route not found");
    const row = await q1(
      `insert into public.route_stops (route_id, destination_id, stop_order, latitude, longitude,
                                       stop_name, duration_at_stop, notes)
       values ($1, $2, coalesce($3, 0), $4, $5, $6, $7, $8) returning stop_id`,
      [route!.route_id, toInt(body?.destination_id), toInt(body?.stop_order), toNum(body?.latitude),
       toNum(body?.longitude), text(body?.stop_name), toInt(body?.duration_at_stop), text(body?.notes, 2000)]);
    return json({ message: "Stop added", stop_id: row?.stop_id }, 201);
  });

  // ── weather (keys stay server-side) ───────────────────────────────────────
  const nearestCity = async (lat: number, lng: number) => {
    const row = await q1(
      `select coalesce(city, location, name) as city from public.destinations
       where latitude is not null and longitude is not null
         and abs(latitude - $1) < 1.5 and abs(longitude - $2) < 1.5
       order by (latitude - $1)^2 + (longitude - $2)^2 limit 1`, [lat, lng]);
    return row?.city ?? "Current Location";
  };

  r.get("/weather/:lat/:lng/forecast", "public", async ({ params, query }) => {
    const lat = toNum(params.lat), lng = toNum(params.lng);
    if (lat === null || lng === null) fail(400, "Invalid latitude or longitude");
    try {
      const days = clampLimit(query.get("days"), 7, 7);
      return json(await weatherForecast(lat!, lng!, days, await nearestCity(lat!, lng!)));
    } catch (e) {
      console.error("[weather] forecast:", (e as Error).message);
      fail(502, "Failed to fetch weather forecast");
    }
    return json({});
  });

  r.get("/weather/:lat/:lng", "public", async ({ params }) => {
    const lat = toNum(params.lat), lng = toNum(params.lng);
    if (lat === null || lng === null) fail(400, "Invalid latitude or longitude");
    try {
      return json({ weather: await currentWeather(lat!, lng!, await nearestCity(lat!, lng!)), cached: false });
    } catch (e) {
      console.error("[weather] current:", (e as Error).message);
      fail(502, "Failed to fetch live weather data");
    }
    return json({});
  });

  r.post("/weather/batch", "public", async ({ body }) => {
    const locations = Array.isArray(body?.locations) ? body.locations.slice(0, 20) : null;
    if (!locations?.length) fail(400, "locations array is required");
    const results = await Promise.allSettled(locations.map(async ({ lat, lng }: any) => {
      const w = await currentWeather(Number(lat), Number(lng), await nearestCity(Number(lat), Number(lng)));
      return { lat, lng, ...w };
    }));
    return json({
      weather: results.map((r2, i) => r2.status === "fulfilled"
        ? r2.value
        : { lat: locations[i].lat, lng: locations[i].lng, error: String(r2.reason?.message ?? r2.reason) }),
    });
  });
}
