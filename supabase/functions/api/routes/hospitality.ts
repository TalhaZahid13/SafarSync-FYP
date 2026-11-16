// Hotels (rooms, availability, server-side pricing, stay bookings) and
// restaurants (opening hours, time slots, seat capacity, reservations).
//
// Inventory is ADMIN-MANAGED (hotels.inventory_source = 'internal'): SafarSync
// is not connected to a hotel/restaurant supplier, so availability and prices
// come only from these tables, which admins maintain. Every amount is computed
// here; the app never sends a price.
import { type Row, exec, isUniqueViolation, q, q1, tx } from "../lib/db.ts";
import { type Ctx, fail, idParam, json, type Router, text, toInt, toNum } from "../lib/http.ts";

// ── Time helpers (restaurants/hotels operate in their own timezone) ──────────
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)$/;
const DAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
export const HOLD_MINUTES = 30; // unpaid hotel bookings hold rooms this long

export function todayIn(tz: string, at = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit" })
    .format(at);
}

function tzOffsetMinutes(tz: string, at: Date): number {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone: tz, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
    }).formatToParts(at).map((p) => [p.type, p.value]),
  );
  const asUtc = Date.UTC(+parts.year, +parts.month - 1, +parts.day, +parts.hour, +parts.minute, +parts.second);
  return Math.round((asUtc - at.getTime()) / 60000);
}

/** Local wall-clock date + time in [tz] → UTC instant. */
export function zonedToUtc(date: string, time: string, tz: string): Date {
  const [y, m, d] = date.split("-").map(Number);
  const [hh, mm] = time.split(":").map(Number);
  const guess = Date.UTC(y, m - 1, d, hh, mm);
  const off = tzOffsetMinutes(tz, new Date(guess));
  return new Date(guess - off * 60000);
}

const addDays = (date: string, n: number) => {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
};
const dayKey = (date: string) => {
  const [y, m, d] = date.split("-").map(Number);
  return DAY_KEYS[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
};
const nightsBetween = (a: string, b: string) =>
  Math.round((Date.parse(b + "T00:00:00Z") - Date.parse(a + "T00:00:00Z")) / 86400000);
const money = (n: number) => Math.round(n * 100) / 100;
const toMin = (t: string) => +t.slice(0, 2) * 60 + +t.slice(3, 5);
const fromMin = (n: number) => `${String(Math.floor(n / 60)).padStart(2, "0")}:${String(n % 60).padStart(2, "0")}`;

// ── Hotel pricing ────────────────────────────────────────────────────────────
export interface StayQuote {
  nights: number;
  rooms: number;
  guests: number;
  nightly: { date: string; price: number; source: string }[];
  room_subtotal: number;
  service_fee: number;
  service_fee_rate: number;
  tax: number;
  tax_rate: number;
  total: number;
  currency: "PKR";
}

/** Nightly price for one room: seasonal rate > weekend (Fri/Sat night) > base. */
export function nightlyPrice(room: Row, rates: Row[], date: string): { price: number; source: string } {
  const season = rates.find((r) => String(r.starts_on) <= date && date <= String(r.ends_on));
  if (season) return { price: Number(season.price_per_night), source: season.label || "seasonal" };
  const dk = dayKey(date);
  if ((dk === "fri" || dk === "sat") && room.weekend_price_per_night) {
    return { price: Number(room.weekend_price_per_night), source: "weekend" };
  }
  return { price: Number(room.base_price_per_night), source: "base" };
}

export function quoteStay(hotel: Row, room: Row, rates: Row[], checkIn: string, checkOut: string,
                          rooms: number, guests: number): StayQuote {
  const nights = nightsBetween(checkIn, checkOut);
  const nightly = Array.from({ length: nights }, (_, i) => {
    const date = addDays(checkIn, i);
    return { date, ...nightlyPrice(room, rates, date) };
  });
  const roomSubtotal = money(nightly.reduce((s, n) => s + n.price, 0) * rooms);
  const serviceRate = Number(hotel.service_fee_rate) || 0;
  const taxRate = Number(hotel.tax_rate) || 0;
  const serviceFee = money(roomSubtotal * serviceRate);
  const tax = money((roomSubtotal + serviceFee) * taxRate);
  return {
    nights, rooms, guests, nightly, room_subtotal: roomSubtotal, service_fee: serviceFee,
    service_fee_rate: serviceRate, tax, tax_rate: taxRate, total: money(roomSubtotal + serviceFee + tax),
    currency: "PKR",
  };
}

/** Rooms of [roomTypeId] still free for the whole [checkIn, checkOut) stay. */
async function roomsAvailable(ex: Parameters<typeof q1>[2], roomTypeId: number, total: number,
                              checkIn: string, checkOut: string, excludeBookingId: number | null = null) {
  const row = await q1(
    `select coalesce(sum(rooms), 0) as used from public.bookings
     where room_type_id = $1 and check_in < $3 and check_out > $2
       and booking_id <> coalesce($4, -1)
       and (status in ('Confirmed', 'Active')
            or (status in ('Pending', 'Awaiting Payment') and created_at > now() - make_interval(mins => $5)))`,
    [roomTypeId, checkIn, checkOut, excludeBookingId, HOLD_MINUTES], ex);
  return Math.max(total - Number(row?.used ?? 0), 0);
}

function validateStay(body: Record<string, unknown>, tz = "Asia/Karachi") {
  const checkIn = String(body?.check_in ?? ""), checkOut = String(body?.check_out ?? "");
  if (!DATE_RE.test(checkIn) || !DATE_RE.test(checkOut)) fail(400, "check_in and check_out must be YYYY-MM-DD");
  const nights = nightsBetween(checkIn, checkOut);
  if (!(nights >= 1)) fail(400, "check_out must be after check_in");
  if (nights > 30) fail(400, "Stays are limited to 30 nights");
  if (checkIn < todayIn(tz)) fail(400, "check_in cannot be in the past");
  if (checkIn > addDays(todayIn(tz), 365)) fail(400, "Bookings open up to 12 months ahead");
  const rooms = toInt(body?.rooms, 1)!, guests = toInt(body?.guests, 1)!;
  if (rooms < 1 || rooms > 10) fail(400, "rooms must be between 1 and 10");
  if (guests < 1 || guests > 50) fail(400, "guests must be between 1 and 50");
  return { checkIn, checkOut, rooms, guests };
}

const HOTEL_COLS = `h.hotel_id, h.name, h.description, h.address, h.city, h.latitude, h.longitude, h.image_url,
  h.category, h.rating, h.amenities, to_char(h.check_in_time, 'HH24:MI') as check_in_time,
  to_char(h.check_out_time, 'HH24:MI') as check_out_time, h.free_cancel_hours, h.tax_rate, h.service_fee_rate,
  h.inventory_source`;

async function loadHotel(hotelId: number, includeInactive = false) {
  const hotel = await q1(`select ${HOTEL_COLS}, h.is_active from public.hotels h where h.hotel_id = $1
                          ${includeInactive ? "" : "and h.is_active"}`, [hotelId]);
  if (!hotel) fail(404, "Hotel not found");
  const rooms = await q(
    `select * from public.hotel_room_types where hotel_id = $1 ${includeInactive ? "" : "and is_active"}
     order by base_price_per_night asc`, [hotelId]);
  const rates = rooms.length
    ? await q(`select rate_id, room_type_id, label, to_char(starts_on, 'YYYY-MM-DD') as starts_on,
                      to_char(ends_on, 'YYYY-MM-DD') as ends_on, price_per_night
               from public.hotel_seasonal_rates where room_type_id = any($1::int[]) order by starts_on`,
      [rooms.map((r) => r.room_type_id)])
    : [];
  return { hotel: hotel!, rooms, rates };
}

// ── Restaurant availability ──────────────────────────────────────────────────
interface Slot { time: string; remaining: number; available: boolean }

async function restaurantSlots(r: Row, date: string, partySize: number): Promise<Slot[]> {
  const hours = (r.opening_hours?.[dayKey(date)] ?? []) as { open: string; close: string }[];
  const step = Number(r.slot_minutes) || 30;
  const times: string[] = [];
  for (const h of hours) {
    if (!TIME_RE.test(h.open) || !TIME_RE.test(h.close)) continue;
    // last seating one slot before closing
    for (let m = toMin(h.open); m + step <= toMin(h.close); m += step) times.push(fromMin(m));
  }
  if (!times.length) return [];
  const startUtc = zonedToUtc(date, "00:00", r.timezone).toISOString();
  const endUtc = zonedToUtc(addDays(date, 1), "00:00", r.timezone).toISOString();
  const used = await q(
    `select reservation_at, sum(party_size) as seats from public.bookings
     where restaurant_id = $1 and reservation_at >= $2 and reservation_at < $3
       and status in ('Pending', 'Confirmed', 'Active') group by reservation_at`,
    [r.restaurant_id, startUtc, endUtc]);
  const byInstant = new Map(used.map((u) => [new Date(u.reservation_at).getTime(), Number(u.seats)]));
  const leadCutoff = Date.now() + 30 * 60000; // at least 30 minutes' notice
  return times.map((time) => {
    const at = zonedToUtc(date, time, r.timezone);
    const remaining = Math.max(Number(r.seats_per_slot) - (byInstant.get(at.getTime()) ?? 0), 0);
    return { time, remaining, available: at.getTime() >= leadCutoff && remaining >= partySize };
  });
}

const RESTAURANT_COLS = `restaurant_id, name, description, address, city, latitude, longitude, phone, image_url,
  cuisine, cuisine_tag, rating, avg_price_per_person, tags, opening_hours, timezone, slot_minutes,
  max_party_size, seating_options, reservation_policy, accepts_reservations, inventory_source`;

// ── Routes ───────────────────────────────────────────────────────────────────
export function registerHospitality(r: Router) {
  // ---- hotels (public catalogue) ----
  r.get("/hotels", "public", async ({ query }) => {
    const where = ["h.is_active"];
    const vals: unknown[] = [];
    const city = text(query.get("city"), 100);
    if (city) { vals.push(city); where.push(`lower(h.city) = lower($${vals.length})`); }
    const cat = text(query.get("category"), 50);
    if (cat && cat !== "All") { vals.push(cat); where.push(`lower(h.category) = lower($${vals.length})`); }
    const search = text(query.get("search"), 100);
    if (search) { vals.push(`%${search}%`); where.push(`(h.name ilike $${vals.length} or h.address ilike $${vals.length} or h.city ilike $${vals.length})`); }
    const hotels = await q(
      `select ${HOTEL_COLS},
              (select min(base_price_per_night) from public.hotel_room_types rt where rt.hotel_id = h.hotel_id and rt.is_active) as from_price,
              (select count(*) from public.hotel_room_types rt where rt.hotel_id = h.hotel_id and rt.is_active) as room_type_count
       from public.hotels h where ${where.join(" and ")} order by h.rating desc nulls last, h.name`, vals);
    return json({ success: true, hotels, currency: "PKR" });
  });

  r.get("/hotels/:id", "public", async ({ params }) => {
    const { hotel, rooms, rates } = await loadHotel(idParam(params.id));
    return json({ success: true, hotel: { ...hotel, room_types: rooms.map((rt) => ({
      ...rt, seasonal_rates: rates.filter((x) => x.room_type_id === rt.room_type_id),
    })) } });
  });

  // Rooms free for the dates + an exact server-side quote for each.
  r.get("/hotels/:id/availability", "public", async ({ params, query }) => {
    const stay = validateStay(Object.fromEntries(query.entries()));
    const { hotel, rooms, rates } = await loadHotel(idParam(params.id));
    const out = [];
    for (const rt of rooms) {
      const free = await roomsAvailable(undefined, rt.room_type_id, rt.total_rooms, stay.checkIn, stay.checkOut);
      const fits = stay.guests <= rt.max_guests * stay.rooms;
      out.push({
        room_type_id: rt.room_type_id, name: rt.name, description: rt.description, max_guests: rt.max_guests,
        amenities: rt.amenities, image_url: rt.image_url, rooms_available: free,
        available: free >= stay.rooms && fits,
        unavailable_reason: free < stay.rooms ? "Not enough rooms free for these dates"
          : !fits ? `Up to ${rt.max_guests} guests per room` : null,
        quote: quoteStay(hotel, rt, rates.filter((x) => x.room_type_id === rt.room_type_id),
          stay.checkIn, stay.checkOut, stay.rooms, stay.guests),
      });
    }
    return json({ success: true, hotel_id: hotel.hotel_id, check_in: stay.checkIn, check_out: stay.checkOut,
                  rooms: stay.rooms, guests: stay.guests, room_types: out, currency: "PKR" });
  });

  // Create a stay booking. Price + availability decided here, atomically.
  r.post("/hotels/bookings", "user", async ({ auth, body }) => {
    const hotelId = toInt(body?.hotel_id), roomTypeId = toInt(body?.room_type_id);
    if (!hotelId || !roomTypeId) fail(400, "hotel_id and room_type_id are required");
    const stay = validateStay(body);
    const contactName = text(body?.contact_name, 120), contactPhone = text(body?.contact_phone, 30);
    if (!contactName || !contactPhone) fail(400, "contact_name and contact_phone are required");
    if (!/^[+\d][\d\s-]{6,19}$/.test(contactPhone!)) fail(400, "Enter a valid phone number");
    const { hotel, rooms, rates } = await loadHotel(hotelId!);
    const rt = rooms.find((x) => x.room_type_id === roomTypeId);
    if (!rt) fail(404, "Room type not found for this hotel");
    if (stay.guests > rt!.max_guests * stay.rooms) fail(400, `Up to ${rt!.max_guests} guests per room`);
    const quote = quoteStay(hotel, rt!, rates.filter((x) => x.room_type_id === roomTypeId),
      stay.checkIn, stay.checkOut, stay.rooms, stay.guests);

    const booking = await tx(async (t) => {
      // serialise bookings for this room type so two people can't take the last room
      await q(`select pg_advisory_xact_lock(1001, $1)`, [roomTypeId], t);
      const free = await roomsAvailable(t, roomTypeId!, rt!.total_rooms, stay.checkIn, stay.checkOut);
      if (free < stay.rooms) fail(409, "Sorry — those rooms were just booked. Please pick other dates or another room.");
      return await q1(
        `insert into public.bookings (user_id, booking_type, booking_date, travel_date, num_travelers,
            estimated_duration_days, notes, total_amount, status, hotel_id, room_type_id, check_in, check_out,
            rooms, guests, contact_name, contact_phone, price_breakdown, currency)
         values ($1, 'hotel', current_date, $2, $3, $4, $5, $6, 'Pending', $7, $8, $2, $9, $10, $3, $11, $12,
                 $13::text::jsonb, 'PKR')
         returning booking_id, booking_reference, status, total_amount, created_at`,
        [auth.userId, stay.checkIn, stay.guests, quote.nights, text(body?.notes, 1000) ?? `${hotel.name} — ${rt!.name}`,
         quote.total, hotelId, roomTypeId, stay.checkOut, stay.rooms, contactName, contactPhone,
         JSON.stringify({ ...quote, hotel_name: hotel.name, room_name: rt!.name })], t);
    });
    return json({
      success: true, booking_id: booking!.booking_id, booking_reference: booking!.booking_reference,
      status: booking!.status, total_amount: quote.total, currency: "PKR", quote,
      hold_minutes: HOLD_MINUTES,
      message: `Rooms held for ${HOLD_MINUTES} minutes — complete payment to confirm.`,
    }, 201);
  });

  // ---- restaurants ----
  r.get("/restaurants", "public", async ({ query }) => {
    const where = ["is_active"];
    const vals: unknown[] = [];
    const tag = text(query.get("cuisine"), 50);
    if (tag && tag !== "All") { vals.push(tag); where.push(`lower(cuisine_tag) = lower($${vals.length})`); }
    const city = text(query.get("city"), 100);
    if (city) { vals.push(city); where.push(`lower(city) = lower($${vals.length})`); }
    const search = text(query.get("search"), 100);
    if (search) { vals.push(`%${search}%`); where.push(`(name ilike $${vals.length} or address ilike $${vals.length} or cuisine ilike $${vals.length})`); }
    const rows = await q(`select ${RESTAURANT_COLS} from public.restaurants where ${where.join(" and ")}
                          order by rating desc nulls last, name`, vals);
    return json({ success: true, restaurants: rows });
  });

  r.get("/restaurants/:id", "public", async ({ params }) => {
    const row = await q1(`select ${RESTAURANT_COLS} from public.restaurants where restaurant_id = $1 and is_active`,
      [idParam(params.id)]);
    if (!row) fail(404, "Restaurant not found");
    return json({ success: true, restaurant: row });
  });

  r.get("/restaurants/:id/availability", "public", async ({ params, query }) => {
    const rest = await q1(`select * from public.restaurants where restaurant_id = $1 and is_active`, [idParam(params.id)]);
    if (!rest) fail(404, "Restaurant not found");
    if (!rest!.accepts_reservations) fail(400, "This restaurant does not take reservations");
    const date = String(query.get("date") ?? "");
    if (!DATE_RE.test(date)) fail(400, "date must be YYYY-MM-DD");
    const party = toInt(query.get("party_size"), 2)!;
    if (party < 1 || party > rest!.max_party_size) fail(400, `Party size must be 1–${rest!.max_party_size}`);
    const today = todayIn(rest!.timezone);
    if (date < today || date > addDays(today, 60)) fail(400, "Reservations can be made up to 60 days ahead");
    const slots = await restaurantSlots(rest!, date, party);
    return json({ success: true, restaurant_id: rest!.restaurant_id, date, party_size: party,
                  timezone: rest!.timezone, open: slots.length > 0, slots });
  });

  r.post("/restaurants/reservations", "user", async ({ auth, body }) => {
    const restId = toInt(body?.restaurant_id);
    if (!restId) fail(400, "restaurant_id is required");
    const rest = await q1(`select * from public.restaurants where restaurant_id = $1 and is_active`, [restId]);
    if (!rest) fail(404, "Restaurant not found");
    if (!rest!.accepts_reservations) fail(400, "This restaurant does not take reservations");
    const date = String(body?.date ?? ""), time = String(body?.time ?? "");
    if (!DATE_RE.test(date) || !TIME_RE.test(time)) fail(400, "date (YYYY-MM-DD) and time (HH:MM) are required");
    const party = toInt(body?.party_size)!;
    if (!party || party < 1 || party > rest!.max_party_size) fail(400, `Party size must be 1–${rest!.max_party_size}`);
    const seating = text(body?.seating_preference, 40);
    const options: string[] = Array.isArray(rest!.seating_options) ? rest!.seating_options : [];
    if (seating && !options.includes(seating)) fail(400, `Seating must be one of: ${options.join(", ")}`);
    const contactName = text(body?.contact_name, 120), contactPhone = text(body?.contact_phone, 30);
    if (!contactName || !contactPhone) fail(400, "contact_name and contact_phone are required");
    if (!/^[+\d][\d\s-]{6,19}$/.test(contactPhone!)) fail(400, "Enter a valid phone number");
    const today = todayIn(rest!.timezone);
    if (date < today || date > addDays(today, 60)) fail(400, "Reservations can be made up to 60 days ahead");

    const at = zonedToUtc(date, time, rest!.timezone);
    try {
      const row = await tx(async (t) => {
        await q(`select pg_advisory_xact_lock(1002, $1)`, [restId], t);
        const slot = (await restaurantSlots(rest!, date, party)).find((s) => s.time === time);
        if (!slot) fail(400, "The restaurant is closed at that time");
        if (!slot!.available) {
          fail(409, slot!.remaining < party ? "Not enough seats left at that time — please pick another slot"
                                             : "That time is too soon or already passed");
        }
        return await q1(
          `insert into public.bookings (user_id, booking_type, booking_date, travel_date, num_travelers,
              estimated_duration_days, notes, total_amount, status, restaurant_id, reservation_at, party_size,
              seating_preference, contact_name, contact_phone, currency)
           values ($1, 'restaurant', current_date, $2, $3, 1, $4, 0, 'Confirmed', $5, $6, $3, $7, $8, $9, 'PKR')
           returning booking_id, booking_reference, status`,
          [auth.userId, date, party, text(body?.notes, 1000) ?? `Table at ${rest!.name}`, restId,
           at.toISOString(), seating, contactName, contactPhone], t);
      });
      return json({
        success: true, booking_id: row!.booking_id, booking_reference: row!.booking_reference,
        status: row!.status, restaurant: rest!.name, date, time, party_size: party,
        message: `Table for ${party} at ${rest!.name} confirmed for ${date} ${time}.`,
      }, 201);
    } catch (e) {
      if (isUniqueViolation(e)) fail(409, "You already have a reservation here at that time");
      throw e;
    }
  });

  // ---- admin: hotels / rooms / rates ----
  const hotelFields = ["name", "description", "address", "city", "latitude", "longitude", "image_url", "category",
    "rating", "amenities", "check_in_time", "check_out_time", "free_cancel_hours", "tax_rate", "service_fee_rate",
    "inventory_source", "is_active"];
  const roomFields = ["name", "description", "max_guests", "base_price_per_night", "weekend_price_per_night",
    "total_rooms", "amenities", "image_url", "is_active"];
  const restaurantFields = ["name", "description", "address", "city", "latitude", "longitude", "phone", "image_url",
    "cuisine", "cuisine_tag", "rating", "avg_price_per_person", "tags", "opening_hours", "timezone", "slot_minutes",
    "seats_per_slot", "max_party_size", "seating_options", "reservation_policy", "accepts_reservations",
    "inventory_source", "is_active"];
  const JSON_COLS = new Set(["amenities", "tags", "opening_hours", "seating_options"]);

  const pick = (body: Record<string, unknown>, fields: string[]) => {
    const cols = fields.filter((f) => body?.[f] !== undefined);
    const vals = cols.map((c) => JSON_COLS.has(c) ? JSON.stringify(body[c] ?? (c === "opening_hours" ? {} : [])) : body[c]);
    const place = (c: string, i: number) => JSON_COLS.has(c) ? `$${i}::text::jsonb` : `$${i}`;
    return { cols, vals, place };
  };
  const insertRow = async (table: string, idCol: string, body: Record<string, unknown>, fields: string[],
                           extra: Record<string, unknown> = {}) => {
    const { cols, vals, place } = pick({ ...body, ...extra }, [...fields, ...Object.keys(extra)]);
    try {
      return await q1(`insert into public.${table} (${cols.join(", ")})
                       values (${cols.map((c, i) => place(c, i + 1)).join(", ")}) returning ${idCol}`, vals);
    } catch (e) {
      const code = (e as { code?: string }).code;
      if (code === "23514" || code === "23502" || code === "22P02" || code === "22007") fail(400, `Invalid value: ${(e as Error).message}`);
      throw e;
    }
  };
  const updateRow = async (table: string, idCol: string, id: number, body: Record<string, unknown>, fields: string[]) => {
    const { cols, vals, place } = pick(body, fields);
    if (!cols.length) fail(400, "No fields to update");
    try {
      const n = await exec(`update public.${table} set ${cols.map((c, i) => `${c} = ${place(c, i + 1)}`).join(", ")}
                            where ${idCol} = $${cols.length + 1}`, [...vals, id]);
      if (!n) fail(404, "Not found");
    } catch (e) {
      const code = (e as { code?: string }).code;
      if (code === "23514" || code === "23502" || code === "22P02" || code === "22007") fail(400, `Invalid value: ${(e as Error).message}`);
      throw e;
    }
  };

  r.get("/admin/hotels", "admin", async () => {
    const hotels = await q(`select ${HOTEL_COLS}, h.is_active from public.hotels h order by h.name`);
    const rooms = await q(`select * from public.hotel_room_types order by hotel_id, base_price_per_night`);
    const rates = await q(`select rate_id, room_type_id, label, to_char(starts_on, 'YYYY-MM-DD') as starts_on,
                                  to_char(ends_on, 'YYYY-MM-DD') as ends_on, price_per_night
                           from public.hotel_seasonal_rates order by starts_on`);
    return json({ success: true, hotels: hotels.map((h) => ({
      ...h,
      room_types: rooms.filter((r2) => r2.hotel_id === h.hotel_id)
        .map((r2) => ({ ...r2, seasonal_rates: rates.filter((x) => x.room_type_id === r2.room_type_id) })),
    })) });
  });
  r.post("/admin/hotels", "admin", async (c: Ctx) => {
    if (!text(c.body?.name)) fail(400, "name is required");
    const row = await insertRow("hotels", "hotel_id", c.body, hotelFields);
    return json({ success: true, hotel_id: row!.hotel_id }, 201);
  });
  r.put("/admin/hotels/:id", "admin", async (c: Ctx) => {
    await updateRow("hotels", "hotel_id", idParam(c.params.id), c.body, hotelFields);
    return json({ success: true });
  });
  r.delete("/admin/hotels/:id", "admin", async (c: Ctx) => {
    await exec(`update public.hotels set is_active = false where hotel_id = $1`, [idParam(c.params.id)]);
    return json({ success: true, message: "Hotel hidden (existing bookings are kept)" });
  });
  r.post("/admin/hotels/:id/rooms", "admin", async (c: Ctx) => {
    if (!text(c.body?.name) || !(toNum(c.body?.base_price_per_night)! > 0)) {
      fail(400, "name and a positive base_price_per_night are required");
    }
    const row = await insertRow("hotel_room_types", "room_type_id", c.body, roomFields, { hotel_id: idParam(c.params.id) });
    return json({ success: true, room_type_id: row!.room_type_id }, 201);
  });
  r.put("/admin/rooms/:id", "admin", async (c: Ctx) => {
    await updateRow("hotel_room_types", "room_type_id", idParam(c.params.id), c.body, roomFields);
    return json({ success: true });
  });
  r.delete("/admin/rooms/:id", "admin", async (c: Ctx) => {
    await exec(`update public.hotel_room_types set is_active = false where room_type_id = $1`, [idParam(c.params.id)]);
    return json({ success: true });
  });
  r.post("/admin/rooms/:id/rates", "admin", async (c: Ctx) => {
    const b = c.body ?? {};
    if (!DATE_RE.test(String(b.starts_on)) || !DATE_RE.test(String(b.ends_on)) || !(toNum(b.price_per_night)! > 0)) {
      fail(400, "starts_on, ends_on (YYYY-MM-DD) and a positive price_per_night are required");
    }
    const row = await insertRow("hotel_seasonal_rates", "rate_id", b, ["label", "starts_on", "ends_on", "price_per_night"],
      { room_type_id: idParam(c.params.id) });
    return json({ success: true, rate_id: row!.rate_id }, 201);
  });
  r.delete("/admin/rates/:id", "admin", async (c: Ctx) => {
    await exec(`delete from public.hotel_seasonal_rates where rate_id = $1`, [idParam(c.params.id)]);
    return json({ success: true });
  });

  // ---- admin: restaurants ----
  r.get("/admin/restaurants", "admin", async () => {
    const rows = await q(`select ${RESTAURANT_COLS}, seats_per_slot, is_active from public.restaurants order by name`);
    return json({ success: true, restaurants: rows });
  });
  r.post("/admin/restaurants", "admin", async (c: Ctx) => {
    if (!text(c.body?.name)) fail(400, "name is required");
    const row = await insertRow("restaurants", "restaurant_id", c.body, restaurantFields);
    return json({ success: true, restaurant_id: row!.restaurant_id }, 201);
  });
  r.put("/admin/restaurants/:id", "admin", async (c: Ctx) => {
    await updateRow("restaurants", "restaurant_id", idParam(c.params.id), c.body, restaurantFields);
    return json({ success: true });
  });
  r.delete("/admin/restaurants/:id", "admin", async (c: Ctx) => {
    await exec(`update public.restaurants set is_active = false where restaurant_id = $1`, [idParam(c.params.id)]);
    return json({ success: true, message: "Restaurant hidden (existing reservations are kept)" });
  });

  // ---- admin: stays & reservations ----
  r.get("/admin/hotel-bookings", "admin", async ({ query }) => {
    const status = text(query.get("status"), 30);
    const rows = await q(
      `select b.booking_id, b.booking_reference, b.status, b.payment_status, b.total_amount, b.currency,
              to_char(b.check_in, 'YYYY-MM-DD') as check_in, to_char(b.check_out, 'YYYY-MM-DD') as check_out,
              b.rooms, b.guests, b.contact_name, b.contact_phone, b.created_at,
              h.name as hotel_name, rt.name as room_name, u.full_name, u.email
       from public.bookings b
       join public.users u on u.user_id = b.user_id
       left join public.hotels h on h.hotel_id = b.hotel_id
       left join public.hotel_room_types rt on rt.room_type_id = b.room_type_id
       where b.booking_type = 'hotel' and b.hotel_id is not null ${status ? "and b.status = $1" : ""}
       order by b.check_in desc nulls last, b.created_at desc limit 300`, status ? [status] : []);
    return json({ success: true, bookings: rows });
  });
  r.get("/admin/reservations", "admin", async ({ query }) => {
    const vals: unknown[] = [];
    const where = [`b.booking_type = 'restaurant' and b.restaurant_id is not null`];
    const status = text(query.get("status"), 30);
    if (status) { vals.push(status); where.push(`b.status = $${vals.length}`); }
    const date = String(query.get("date") ?? "");
    if (DATE_RE.test(date)) { vals.push(date); where.push(`(b.reservation_at at time zone r.timezone)::date = $${vals.length}::date`); }
    const rows = await q(
      `select b.booking_id, b.booking_reference, b.status, b.party_size, b.seating_preference, b.reservation_at,
              to_char(b.reservation_at at time zone r.timezone, 'YYYY-MM-DD HH24:MI') as local_time,
              b.contact_name, b.contact_phone, b.notes, b.created_at, r.name as restaurant_name,
              u.full_name, u.email
       from public.bookings b
       join public.users u on u.user_id = b.user_id
       join public.restaurants r on r.restaurant_id = b.restaurant_id
       where ${where.join(" and ")} order by b.reservation_at desc limit 300`, vals);
    return json({ success: true, reservations: rows });
  });
  r.put("/admin/reservations/:id/status", "admin", async (c: Ctx) => {
    const status = c.body?.status;
    if (!["Confirmed", "Cancelled", "Completed"].includes(status)) fail(400, "status must be Confirmed, Cancelled or Completed");
    const reason = text(c.body?.reason, 500);
    const n = await exec(
      `update public.bookings set status = $1,
              cancelled_at = case when $1 = 'Cancelled' then now() else cancelled_at end,
              cancellation_reason = case when $1 = 'Cancelled' then coalesce($2, 'Cancelled by restaurant') else cancellation_reason end
       where booking_id = $3 and booking_type = 'restaurant'`, [status, reason, idParam(c.params.id)]);
    if (!n) fail(404, "Reservation not found");
    return json({ success: true });
  });
}
