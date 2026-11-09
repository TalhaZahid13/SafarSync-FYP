// bookings, group bookings, groups (invite codes), invitations, group chat
import { exec, isUniqueViolation, q, q1, tx } from "../lib/db.ts";
import { fail, idParam, json, type Router, text, toInt, toNum, clampLimit } from "../lib/http.ts";
import { resolveAdmin, type AuthCtx } from "../lib/auth.ts";
import { background, emit, notify } from "../lib/notify.ts";
import { emails } from "../lib/external.ts";

const BOOKING_STATUSES = ["Pending", "Awaiting Payment", "Confirmed", "Active", "Completed", "Cancelled", "Refunded"];
const TRANSITIONS: Record<string, string[]> = {
  "Pending": ["Awaiting Payment", "Confirmed", "Cancelled"],
  "Awaiting Payment": ["Confirmed", "Cancelled", "Refunded"],
  "Confirmed": ["Active", "Cancelled", "Refunded"],
  "Active": ["Completed", "Cancelled"],
  "Completed": [],
  "Cancelled": ["Refunded"],
  "Refunded": [],
};
const GROUP_STATUSES = ["Planning", "Open", "Full", "Active", "Completed", "Cancelled"];

export async function getBookingById(id: number) {
  return await q1(
    `select b.*, d.name as destination_name, d.image_url, d.latitude, d.longitude, d.average_cost,
            u.full_name, u.email
     from public.bookings b
     left join public.destinations d on d.destination_id = b.destination_id
     join public.users u on u.user_id = b.user_id
     where b.booking_id = $1`, [id]);
}

const MEMBER_SQL = `
  select u.user_id, u.full_name, u.email, u.profile_picture_url, m.joined_at, m.role
  from public.group_booking_members m join public.users u on u.user_id = m.user_id
  where m.group_booking_id = $1
  order by (m.role <> 'organizer'), m.joined_at`;

async function isMember(gid: number, userId: number) {
  return !!(await q1(`select 1 from public.group_booking_members where group_booking_id = $1 and user_id = $2`,
    [gid, userId]));
}
async function requireMemberOrAdmin(gid: number, auth: AuthCtx) {
  if (await isMember(gid, auth.userId)) return;
  if (await resolveAdmin(auth)) return;
  fail(403, "You are not a member of this group");
}

const makeCode = () => {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
};

export function registerTrips(r: Router) {
  // ── single bookings ───────────────────────────────────────────────────────
  r.post("/bookings/create", "user", async ({ auth, body }) => {
    const b = body ?? {};
    if (!b.booking_date) fail(400, "booking_date is required");
    const bookingType = String(b.booking_type ?? "");
    const isHotelOrRestaurant = bookingType === "hotel" || bookingType === "restaurant";
    if (!isHotelOrRestaurant && !b.destination_id) fail(400, "destination_id is required for destination bookings");

    const days = Math.max(toInt(b.duration_days, 1)!, 1);
    const travelers = Math.max(toInt(b.num_travelers, 1)!, 1);

    if (isHotelOrRestaurant) {
      const unit = toNum(b.item_price_per_unit) ?? 0;
      const total = toNum(b.total_amount) ?? unit * days * travelers;
      if (total < 0) fail(400, "Invalid amount");
      const label = bookingType === "hotel" ? "Hotel" : "Restaurant";
      const item = text(b.item_name, 200);
      const tag = item ? `[${label}: ${item}]` : `[${label} Booking]`;
      const notes = text(b.notes, 2000) ? `${tag} ${text(b.notes, 2000)}` : tag;
      const row = await q1(
        `insert into public.bookings (user_id, destination_id, booking_type, booking_date, travel_date,
                                      num_travelers, estimated_duration_days, notes, total_amount)
         values ($1, $2, $3, $4, $5, $6, $7, $8, $9) returning booking_id`,
        [auth.userId, toInt(b.destination_id), bookingType, b.booking_date, b.travel_date || null,
         travelers, days, notes, total]);
      return json({ success: true, booking_id: row?.booking_id, total_amount: total, booking_type: bookingType, item_name: item }, 201);
    }

    const dest = await q1(`select destination_id, average_cost from public.destinations where destination_id = $1`,
      [toInt(b.destination_id)]);
    if (!dest) fail(404, "Destination not found");
    // price is always computed server-side from the catalogue
    const total = (Number(dest!.average_cost) || 50) * days * travelers;
    const row = await q1(
      `insert into public.bookings (user_id, destination_id, booking_type, booking_date, travel_date,
                                    num_travelers, estimated_duration_days, notes, total_amount, package_id)
       values ($1, $2, 'single', $3, $4, $5, $6, $7, $8, $9) returning booking_id`,
      [auth.userId, dest!.destination_id, b.booking_date, b.travel_date || null, travelers, days,
       text(b.notes, 2000) ?? "", total, toInt(b.package_id)]);
    return json({ success: true, booking_id: row?.booking_id, total_amount: total, message: "Booking created" }, 201);
  });

  r.get("/bookings/list", "user", async ({ auth }) => {
    const rows = await q(
      `select b.*, d.name as destination_name, d.image_url, d.latitude, d.longitude, d.average_cost
       from public.bookings b left join public.destinations d on d.destination_id = b.destination_id
       where b.user_id = $1 order by b.created_at desc`, [auth.userId]);
    return json({ success: true, bookings: rows });
  });

  // /bookings?status=confirmed&limit=1 (used by the destination theme)
  r.get("/bookings", "user", async ({ auth, query }) => {
    const status = text(query.get("status"), 30);
    const limit = clampLimit(query.get("limit"), 20, 100);
    const vals: unknown[] = [auth.userId];
    let filter = "";
    if (status === "upcoming") {
      filter = `and b.status in ('Pending','Awaiting Payment','Confirmed') and (b.travel_date is null or b.travel_date >= current_date)`;
    } else if (status) {
      vals.push(status);
      filter = `and lower(b.status) = lower($2)`;
    }
    vals.push(limit);
    const rows = await q(
      `select b.*, d.name as destination_name, d.image_url, d.category, d.city, d.latitude, d.longitude
       from public.bookings b left join public.destinations d on d.destination_id = b.destination_id
       where b.user_id = $1 ${filter} order by coalesce(b.travel_date, b.booking_date) asc nulls last
       limit $${vals.length}`, vals);
    return json({ success: true, bookings: rows });
  });

  r.get("/bookings/admin/stats", "admin", async () => {
    const s = await q1(
      `select count(*) as total_bookings,
              count(*) filter (where status = 'Pending') as pending,
              count(*) filter (where status = 'Awaiting Payment') as awaiting_payment,
              count(*) filter (where status = 'Confirmed') as confirmed,
              count(*) filter (where status = 'Active') as active,
              count(*) filter (where status = 'Completed') as completed,
              count(*) filter (where status = 'Cancelled') as cancelled,
              coalesce(sum(total_amount) filter (where payment_status = 'Paid'), 0) as total_revenue
       from public.bookings`);
    return json({ success: true, stats: s ?? {} });
  });

  r.get("/bookings/:booking_id", "user", async ({ auth, params }) => {
    const booking = await getBookingById(idParam(params.booking_id));
    if (!booking) fail(404, "Booking not found");
    if (booking!.user_id !== auth.userId && !(await resolveAdmin(auth))) fail(403, "Forbidden");
    return json({ success: true, booking });
  });

  r.put("/bookings/:booking_id/status", "user", async ({ auth, params, body }) => {
    const status = body?.status;
    if (!BOOKING_STATUSES.includes(status)) fail(400, `Invalid status. Valid: ${BOOKING_STATUSES.join(", ")}`);
    const booking = await getBookingById(idParam(params.booking_id));
    if (!booking) fail(404, "Booking not found");
    const admin = await resolveAdmin(auth);
    if (!admin && booking!.user_id !== auth.userId) fail(403, "Forbidden");
    const allowed = TRANSITIONS[booking!.status] ?? [];
    if (!allowed.includes(status)) {
      fail(400, `Cannot transition from '${booking!.status}' to '${status}'. Allowed: ${allowed.join(", ") || "none"}`);
    }
    // users may not mark their own booking paid/confirmed — that comes from payments
    if (!admin && !["Cancelled"].includes(status)) fail(403, "Only an admin can set this status");
    await exec(`update public.bookings set status = $1 where booking_id = $2`, [status, booking!.booking_id]);
    return json({ success: true, message: "Status updated" });
  });

  r.post("/bookings/:booking_id/cancel", "user", async ({ auth, params, body }) => {
    const booking = await getBookingById(idParam(params.booking_id));
    if (!booking) fail(404, "Booking not found");
    if (booking!.user_id !== auth.userId) fail(403, "Forbidden");
    if (["Completed", "Cancelled", "Refunded"].includes(booking!.status)) {
      fail(400, `Cannot cancel a ${booking!.status} booking`);
    }
    const n = await exec(
      `update public.bookings set status = 'Cancelled', cancelled_at = now(), cancellation_reason = $1
       where booking_id = $2 and user_id = $3 and status not in ('Completed','Cancelled','Refunded')`,
      [text(body?.reason, 1000) ?? "", booking!.booking_id, auth.userId]);
    if (!n) fail(400, "Booking could not be cancelled");
    return json({ success: true, message: "Booking cancelled" });
  });

  // ── group bookings ────────────────────────────────────────────────────────
  r.post("/group-bookings/create", "user", async ({ auth, body }) => {
    const name = text(body?.trip_name, 255);
    if (!name) fail(400, "trip_name is required");
    const id = await tx(async (t) => {
      const gb = await q1(
        `insert into public.group_bookings (trip_name, created_by, description, start_date, end_date,
                                            max_members, destination_id, status, invite_code)
         values ($1, $2, $3, $4, $5, $6, $7, 'Planning', $8) returning group_booking_id`,
        [name, auth.userId, text(body.description, 4000) ?? "", body.start_date || null, body.end_date || null,
         Math.max(toInt(body.max_members, 20)!, 1), toInt(body.destination_id), makeCode()], t);
      await q(`insert into public.group_booking_members (group_booking_id, user_id, role) values ($1, $2, 'organizer')`,
        [gb!.group_booking_id, auth.userId], t);
      return gb!.group_booking_id as number;
    });
    return json({ success: true, group_booking_id: id, message: "Group trip created successfully" }, 201);
  });

  r.get("/group-bookings/list", "user", async ({ auth }) => {
    const rows = await q(
      `select gb.*, u.full_name as created_by_name, d.name as destination_name,
              (select count(*) from public.group_booking_members where group_booking_id = gb.group_booking_id) as member_count,
              (select role from public.group_booking_members where group_booking_id = gb.group_booking_id and user_id = $1) as my_role
       from public.group_bookings gb
       join public.users u on u.user_id = gb.created_by
       left join public.destinations d on d.destination_id = gb.destination_id
       where gb.created_by = $1
          or gb.group_booking_id in (select group_booking_id from public.group_booking_members where user_id = $1)
       order by gb.created_at desc`, [auth.userId]);
    return json({ success: true, group_bookings: rows });
  });

  r.post("/group-bookings/tracking/start", "user", async ({ auth, body }) => {
    const gid = toInt(body?.group_booking_id);
    if (!gid) fail(400, "group_booking_id is required");
    await requireMemberOrAdmin(gid!, auth);
    const row = await q1(
      `insert into public.group_tracking_sessions (group_booking_id, status) values ($1, 'active') returning id`, [gid]);
    await emit(`group-tracking:${gid}`, "tracking:started", { group_booking_id: gid });
    return json({ success: true, session_id: row?.id });
  });

  r.get("/group-bookings/admin/stats", "admin", async () => {
    const s = await q1(
      `select count(distinct gb.group_booking_id) as total_group_bookings,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Planning') as planning,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Active') as active,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Completed') as completed,
              count(distinct gbm.user_id) as total_members,
              count(distinct gts.id) as active_tracking_sessions
       from public.group_bookings gb
       left join public.group_booking_members gbm on gbm.group_booking_id = gb.group_booking_id
       left join public.group_tracking_sessions gts on gts.group_booking_id = gb.group_booking_id and gts.status = 'active'`);
    return json({ success: true, stats: s ?? {} });
  });

  r.get("/group-bookings/:group_booking_id", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    const gb = await q1(
      `select gb.*, u.full_name as created_by_name, u.profile_picture_url as creator_profile,
              d.name as destination_name
       from public.group_bookings gb
       join public.users u on u.user_id = gb.created_by
       left join public.destinations d on d.destination_id = gb.destination_id
       where gb.group_booking_id = $1`, [gid]);
    if (!gb) fail(404, "Group trip not found");
    // invited users may preview the trip before accepting
    const invited = await q1(`select 1 from public.group_invitations where group_booking_id = $1 and receiver_id = $2`,
      [gid, auth.userId]);
    if (!invited) await requireMemberOrAdmin(gid, auth);
    const members = await q(MEMBER_SQL, [gid]);
    return json({ success: true, group_booking: { ...gb, members, member_count: members.length } });
  });

  r.post("/group-bookings/:group_booking_id/join", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    const gb = await q1(`select max_members, status from public.group_bookings where group_booking_id = $1`, [gid]);
    if (!gb) fail(404, "Group not found");
    if (gb!.status === "Cancelled" || gb!.status === "Completed") fail(400, "This group trip is closed");
    // joining by shared Group ID is an existing app feature ("Join by Group ID")
    const cnt = await q1(`select count(*) as c from public.group_booking_members where group_booking_id = $1`, [gid]);
    if ((cnt?.c ?? 0) >= gb!.max_members) fail(400, "Group has reached maximum capacity");
    try {
      await q(`insert into public.group_booking_members (group_booking_id, user_id, role) values ($1, $2, 'member')`,
        [gid, auth.userId]);
    } catch (e) {
      if (isUniqueViolation(e)) fail(400, "Already a member of this group");
      throw e;
    }
    await emit(`group-tracking:${gid}`, "member:joined", { group_booking_id: gid, user_id: auth.userId, user_name: auth.name });
    return json({ success: true, message: "Joined group trip successfully" });
  });

  r.post("/group-bookings/:group_booking_id/close", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    const gb = await q1(`select created_by from public.group_bookings where group_booking_id = $1`, [gid]);
    if (!gb) fail(404, "Group not found");
    if (gb!.created_by !== auth.userId) fail(403, "Only the organizer can close the group");
    await exec(`update public.group_bookings set status = 'Cancelled' where group_booking_id = $1`, [gid]);
    return json({ success: true, message: "Group closed" });
  });

  r.get("/group-bookings/:group_booking_id/members", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    await requireMemberOrAdmin(gid, auth);
    const members = await q(MEMBER_SQL, [gid]);
    return json({ success: true, members, member_count: members.length });
  });

  r.delete("/group-bookings/:group_booking_id/members/:user_id", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    const target = idParam(params.user_id);
    const me = await q1(`select role from public.group_booking_members where group_booking_id = $1 and user_id = $2`,
      [gid, auth.userId]);
    if (!me || me.role !== "organizer") fail(403, "Only the organizer can remove members");
    await exec(`delete from public.group_booking_members where group_booking_id = $1 and user_id = $2 and role <> 'organizer'`,
      [gid, target]);
    return json({ success: true, message: "Member removed" });
  });

  r.put("/group-bookings/:group_booking_id/members/role", "user", async ({ auth, params, body }) => {
    const gid = idParam(params.group_booking_id);
    const role = body?.role;
    if (!["organizer", "member"].includes(role)) fail(400, "Invalid role. Must be organizer or member");
    const me = await q1(`select role from public.group_booking_members where group_booking_id = $1 and user_id = $2`,
      [gid, auth.userId]);
    if (!me || me.role !== "organizer") fail(403, "Only the organizer can change roles");
    await exec(`update public.group_booking_members set role = $1 where group_booking_id = $2 and user_id = $3`,
      [role, gid, toInt(body?.user_id)]);
    return json({ success: true, message: "Role updated" });
  });

  r.get("/group-bookings/:group_booking_id/locations", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_booking_id);
    await requireMemberOrAdmin(gid, auth);
    const rows = await q(
      `select u.user_id, u.full_name, u.profile_picture_url,
              l.latitude, l.longitude, l.city, l.country, l.captured_at, l.accuracy_meters
       from public.group_booking_members m
       join public.users u on u.user_id = m.user_id
       left join lateral (
         select latitude, longitude, city, country, captured_at, accuracy_meters
         from public.user_location_updates
         where user_identifier = 'user_' || u.user_id
         order by captured_at desc limit 1) l on true
       where m.group_booking_id = $1
       order by u.full_name`, [gid]);
    return json({ success: true, member_locations: rows });
  });

  r.put("/group-bookings/:group_booking_id/status", "user", async ({ auth, params, body }) => {
    const gid = idParam(params.group_booking_id);
    const status = body?.status;
    if (!GROUP_STATUSES.includes(status)) fail(400, `Invalid status. Valid: ${GROUP_STATUSES.join(", ")}`);
    const gb = await q1(`select created_by from public.group_bookings where group_booking_id = $1`, [gid]);
    if (!gb) fail(404, "Group not found");
    if (gb!.created_by !== auth.userId && !(await resolveAdmin(auth))) fail(403, "Only the organizer can change status");
    await exec(`update public.group_bookings set status = $1 where group_booking_id = $2`, [status, gid]);
    return json({ success: true, message: "Status updated" });
  });

  // ── groups (invite-code groups; stored as group_bookings) ─────────────────
  r.post("/groups/create", "user", async ({ auth, body }) => {
    const name = text(body?.group_name, 255);
    if (!name) fail(400, "group_name is required");
    const result = await tx(async (t) => {
      for (let attempt = 0; attempt < 5; attempt++) {
        const code = makeCode();
        const exists = await q1(`select 1 from public.group_bookings where invite_code = $1`, [code], t);
        if (exists) continue;
        const gb = await q1(
          `insert into public.group_bookings (trip_name, description, created_by, max_members, invite_code, status)
           values ($1, $2, $3, $4, $5, 'Open') returning group_booking_id`,
          [name, text(body.description, 4000) ?? "", auth.userId, Math.max(toInt(body.max_members, 10)!, 1), code], t);
        await q(`insert into public.group_booking_members (group_booking_id, user_id, role) values ($1, $2, 'organizer')`,
          [gb!.group_booking_id, auth.userId], t);
        return { id: gb!.group_booking_id as number, code };
      }
      throw new Error("Could not generate a unique invite code");
    });
    return json({ success: true, group_id: result.id, invite_code: result.code, group_name: name,
                  message: "Group created successfully" }, 201);
  });

  r.get("/groups/my-groups", "user", async ({ auth }) => {
    const rows = await q(
      `select gb.group_booking_id as group_id, gb.trip_name as group_name, gb.description, gb.invite_code,
              gb.status, gb.max_members, gb.created_by, gb.created_at, me.role as my_role,
              u.full_name as creator_name,
              (select count(*) from public.group_booking_members where group_booking_id = gb.group_booking_id) as member_count
       from public.group_bookings gb
       join public.group_booking_members me on me.group_booking_id = gb.group_booking_id and me.user_id = $1
       left join public.users u on u.user_id = gb.created_by
       order by gb.created_at desc`, [auth.userId]);
    return json({ success: true, groups: rows });
  });

  r.post("/groups/join", "user", async ({ auth, body }) => {
    const code = text(body?.invite_code, 20)?.toUpperCase();
    if (!code) fail(400, "invite_code is required");
    const gb = await q1(
      `select group_booking_id, trip_name, max_members, status,
              (select count(*) from public.group_booking_members where group_booking_id = gb.group_booking_id) as member_count
       from public.group_bookings gb where upper(invite_code) = $1`, [code]);
    if (!gb) fail(404, "Invalid invite code");
    if (gb!.status === "Cancelled") fail(400, "This group has been closed");
    if (gb!.member_count >= gb!.max_members) fail(400, "Group is full");
    try {
      await q(`insert into public.group_booking_members (group_booking_id, user_id, role) values ($1, $2, 'member')`,
        [gb!.group_booking_id, auth.userId]);
    } catch (e) {
      if (isUniqueViolation(e)) fail(400, "Already a member of this group");
      throw e;
    }
    await emit(`group-tracking:${gb!.group_booking_id}`, "member:joined",
      { group_booking_id: gb!.group_booking_id, user_id: auth.userId, user_name: auth.name });
    return json({ success: true, group_id: gb!.group_booking_id, group_name: gb!.trip_name, message: "Joined group successfully" });
  });

  const GROUP_MEMBERS_SQL = `
    select u.user_id, u.full_name, u.email, u.profile_picture_url, m.role, m.joined_at
    from public.group_booking_members m join public.users u on u.user_id = m.user_id
    where m.group_booking_id = $1 order by m.joined_at asc`;

  r.get("/groups/:group_id/members", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_id);
    await requireMemberOrAdmin(gid, auth);
    return json({ success: true, members: await q(GROUP_MEMBERS_SQL, [gid]) });
  });

  r.get("/groups/:group_id", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_id);
    const group = await q1(
      `select gb.group_booking_id as group_id, gb.trip_name as group_name, gb.description, gb.invite_code,
              gb.status, gb.max_members, gb.created_by, gb.created_at, u.full_name as creator_name,
              (select count(*) from public.group_booking_members where group_booking_id = gb.group_booking_id) as member_count
       from public.group_bookings gb left join public.users u on u.user_id = gb.created_by
       where gb.group_booking_id = $1`, [gid]);
    if (!group) fail(404, "Group not found");
    await requireMemberOrAdmin(gid, auth);
    return json({ success: true, group, members: await q(GROUP_MEMBERS_SQL, [gid]) });
  });

  r.post("/groups/:group_id/invite", "user", async ({ auth, params, body }) => {
    const gid = idParam(params.group_id);
    const receiver = toInt(body?.receiver_id);
    if (!receiver) fail(400, "receiver_id is required");
    if (!(await isMember(gid, auth.userId))) fail(403, "You are not a member of this group");
    try {
      await q(`insert into public.group_invitations (group_booking_id, sender_id, receiver_id, status)
               values ($1, $2, $3, 'Pending')`, [gid, auth.userId, receiver]);
    } catch (e) {
      if (isUniqueViolation(e)) fail(400, "Invitation already sent");
      throw e;
    }
    return json({ success: true, message: "Invitation sent" });
  });

  r.delete("/groups/:group_id/members/:user_id", "user", async ({ auth, params }) => {
    const gid = idParam(params.group_id);
    const target = idParam(params.user_id);
    const me = await q1(`select role from public.group_booking_members where group_booking_id = $1 and user_id = $2`,
      [gid, auth.userId]);
    if (target !== auth.userId && me?.role !== "organizer") fail(403, "Only organizers can remove members");
    const n = await exec(`delete from public.group_booking_members where group_booking_id = $1 and user_id = $2`,
      [gid, target]);
    if (!n) fail(404, "Member not found");
    return json({ success: true, message: "Member removed" });
  });

  // ── invitations ───────────────────────────────────────────────────────────
  r.post("/invitations/send", "user", async ({ auth, body }) => {
    const gid = toInt(body?.group_booking_id);
    const email = text(body?.receiver_email, 255);
    if (!gid || !email) fail(400, "group_booking_id and receiver_email are required");
    if (!(await isMember(gid!, auth.userId))) fail(403, "You are not a member of this group");
    const receiver = await q1(
      `select user_id, full_name, email from public.users where lower(email) = lower($1) and is_active and not is_blocked limit 1`,
      [email]);
    if (!receiver) fail(404, "No SafarSync user found with that email");
    if (receiver!.user_id === auth.userId) fail(400, "Cannot invite yourself");
    if (await isMember(gid!, receiver!.user_id)) fail(400, "User is already a member of this group");
    const trip = await q1(`select trip_name from public.group_bookings where group_booking_id = $1`, [gid]);
    if (!trip) fail(404, "Group booking not found");
    let inv;
    try {
      inv = await q1(
        `insert into public.group_invitations (group_booking_id, sender_id, receiver_id, status)
         values ($1, $2, $3, 'Pending') returning id`, [gid, auth.userId, receiver!.user_id]);
    } catch (e) {
      if (isUniqueViolation(e)) fail(400, "Invitation already sent to this user");
      throw e;
    }
    await notify(receiver!.user_id, "Group Booking Invitation",
      `You have been invited to join "${trip!.trip_name}" by ${auth.name}.`, "group_invitation", `/invitations/${inv!.id}`);
    background(emails.groupInvitation({
      toEmail: receiver!.email, toName: receiver!.full_name, senderName: auth.name,
      tripName: trip!.trip_name, invitationId: inv!.id,
    }));
    return json({ success: true, invitation_id: inv!.id, message: `Invitation sent to ${receiver!.email}` }, 201);
  });

  r.get("/invitations/received", "user", async ({ auth }) => {
    const rows = await q(
      `select gi.*, gb.trip_name, gb.description, gb.start_date, gb.status as trip_status,
              u.full_name as sender_name, u.email as sender_email, u.profile_picture_url as sender_avatar
       from public.group_invitations gi
       join public.group_bookings gb on gb.group_booking_id = gi.group_booking_id
       join public.users u on u.user_id = gi.sender_id
       where gi.receiver_id = $1 order by gi.created_at desc`, [auth.userId]);
    return json({ success: true, invitations: rows });
  });

  r.get("/invitations/sent", "user", async ({ auth }) => {
    const rows = await q(
      `select gi.*, gb.trip_name, u.full_name as receiver_name, u.email as receiver_email
       from public.group_invitations gi
       join public.group_bookings gb on gb.group_booking_id = gi.group_booking_id
       join public.users u on u.user_id = gi.receiver_id
       where gi.sender_id = $1 order by gi.created_at desc`, [auth.userId]);
    return json({ success: true, invitations: rows });
  });

  r.get("/invitations/pending-count", "user", async ({ auth }) => {
    const row = await q1(`select count(*) as count from public.group_invitations where receiver_id = $1 and status = 'Pending'`,
      [auth.userId]);
    return json({ success: true, pending_count: row?.count ?? 0 });
  });

  r.put("/invitations/:id/respond", "user", async ({ auth, params, body }) => {
    const status = body?.status;
    if (!["Accepted", "Declined"].includes(status)) fail(400, "status must be Accepted or Declined");
    const inv = await q1(
      `select gi.*, gb.trip_name, gb.max_members,
              s.full_name as sender_name, s.email as sender_email,
              rc.full_name as receiver_name
       from public.group_invitations gi
       join public.group_bookings gb on gb.group_booking_id = gi.group_booking_id
       join public.users s on s.user_id = gi.sender_id
       join public.users rc on rc.user_id = gi.receiver_id
       where gi.id = $1`, [idParam(params.id)]);
    if (!inv) fail(404, "Invitation not found");
    if (inv!.receiver_id !== auth.userId) fail(403, "Not authorized to respond to this invitation");
    if (inv!.status !== "Pending") fail(400, `Invitation already ${inv!.status}`);

    await tx(async (t) => {
      await q(`update public.group_invitations set status = $1 where id = $2`, [status, inv!.id], t);
      if (status === "Accepted") {
        await q(`insert into public.group_booking_members (group_booking_id, user_id) values ($1, $2)
                 on conflict (group_booking_id, user_id) do nothing`, [inv!.group_booking_id, auth.userId], t);
      }
    });

    if (status === "Accepted") {
      await notify(inv!.sender_id, "Invitation Accepted",
        `${inv!.receiver_name} has accepted your invitation to join "${inv!.trip_name}".`, "invitation_accepted");
      await emit(`group-tracking:${inv!.group_booking_id}`, "member:joined",
        { group_booking_id: inv!.group_booking_id, user_id: auth.userId, user_name: inv!.receiver_name });
    } else {
      await notify(inv!.sender_id, "Invitation Declined",
        `${inv!.receiver_name} has declined the invitation to "${inv!.trip_name}".`, "invitation_declined");
    }
    background(emails.invitationResponse({
      toEmail: inv!.sender_email, toName: inv!.sender_name, responderName: inv!.receiver_name,
      tripName: inv!.trip_name, status,
    }));
    return json({ success: true, status, message: `Invitation ${status}` });
  });

  // ── group chat ────────────────────────────────────────────────────────────
  const MSG_SQL = `
    select m.message_id, m.group_booking_id, m.user_id, m.message, m.message_type, m.created_at,
           u.full_name as sender_name, u.profile_picture_url as sender_avatar
    from public.group_chat_messages m join public.users u on u.user_id = m.user_id`;

  r.get("/group-chat/:groupId/messages", "user", async ({ auth, params, query }) => {
    const gid = idParam(params.groupId);
    if (!(await isMember(gid, auth.userId))) fail(403, "Not a member of this group");
    const limit = clampLimit(query.get("limit"), 50, 200);
    const before = toInt(query.get("before"));
    const rows = await q(
      `${MSG_SQL} where m.group_booking_id = $1 ${before ? "and m.message_id < $3" : ""}
       order by m.created_at desc, m.message_id desc limit $2`,
      before ? [gid, limit, before] : [gid, limit]);
    return json({ success: true, messages: rows.reverse() });
  });

  r.post("/group-chat/:groupId/messages", "user", async ({ auth, params, body }) => {
    const gid = idParam(params.groupId);
    const message = typeof body?.message === "string" ? body.message.trim() : "";
    if (!message) fail(400, "Message cannot be empty");
    if (message.length > 4000) fail(400, "Message is too long");
    const type = ["text", "image", "location", "system"].includes(body?.message_type) ? body.message_type : "text";
    if (!(await isMember(gid, auth.userId))) fail(403, "Not a member of this group");
    const ins = await q1(
      `insert into public.group_chat_messages (group_booking_id, user_id, message, message_type)
       values ($1, $2, $3, $4) returning message_id`, [gid, auth.userId, message, type]);
    const full = await q1(`${MSG_SQL} where m.message_id = $1`, [ins!.message_id]);
    await emit(`group:${gid}`, "chat:message", full);
    return json({ success: true, message: full }, 201);
  });

  r.delete("/group-chat/:groupId/messages/:messageId", "user", async ({ auth, params }) => {
    const gid = idParam(params.groupId);
    const mid = idParam(params.messageId);
    const n = await exec(
      `delete from public.group_chat_messages where message_id = $1 and group_booking_id = $2 and user_id = $3`,
      [mid, gid, auth.userId]);
    if (!n) fail(404, "Message not found or not yours");
    await emit(`group:${gid}`, "chat:deleted", { message_id: mid });
    return json({ success: true, message: "Message deleted" });
  });
}
