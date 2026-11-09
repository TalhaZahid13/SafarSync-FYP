// /admin/* — every route here requires an admin (resolved in index.ts).
import { exec, q, q1 } from "../lib/db.ts";
import { type Ctx, fail, idParam, json, type Router, text, toInt, toNum } from "../lib/http.ts";
import { emit } from "../lib/notify.ts";
import { stripe, stripeConfigured } from "../lib/external.ts";
import { deleteAuthUser } from "./core.ts";
import { getTourById } from "./features.ts";

async function logAction(c: Ctx, action: string, targetType: string | null, targetId: number | null, details: unknown) {
  try {
    const a = c.auth.admin!;
    await q(
      `insert into public.admin_activity_logs (admin_id, admin_name, action, target_type, target_id, details, ip_address)
       values ($1, $2, $3, $4, $5, $6, $7)`,
      [a.adminId, a.adminName || a.email, action, targetType, targetId,
       typeof details === "object" ? JSON.stringify(details ?? {}) : String(details ?? ""), c.ip]);
  } catch (e) {
    console.error("[admin] log failed:", (e as Error).message);
  }
}

const requireSuperAdmin = (c: Ctx) => {
  if (c.auth.admin?.role !== "super_admin") {
    fail(403, "This action requires one of these roles: super_admin", { success: false });
  }
};

const cnt = async (sqlText: string) => Number((await q1(sqlText))?.c ?? 0);

const PKG_COLS = ["title", "description", "duration_days", "total_price", "price_per_day", "category",
  "destinations", "itinerary", "includes", "image_url", "max_travelers"];

function pkgValues(b: any) {
  return {
    title: text(b?.title, 255),
    description: b?.description ?? null,
    duration_days: toInt(b?.duration_days, 3),
    total_price: toNum(b?.total_price) ?? 0,
    price_per_day: toNum(b?.price_per_day) ?? 50,
    category: text(b?.category, 100) ?? "General",
    destinations: JSON.stringify(Array.isArray(b?.destinations) ? b.destinations : []),
    itinerary: JSON.stringify(Array.isArray(b?.itinerary) ? b.itinerary : []),
    includes: JSON.stringify(Array.isArray(b?.includes) ? b.includes : []),
    image_url: b?.image_url || null,
    max_travelers: toInt(b?.max_travelers, 10),
  } as Record<string, unknown>;
}

export function registerAdmin(r: Router) {
  r.get("/admin/dashboard", "admin", async () => {
    const [
      totalUsers, newUsersToday, activeUsers30d, blockedUsers, suspendedUsers,
      totalBookings, activeBookings, completedBookings, cancelledBookings, pendingBookings,
      totalGroupBookings, activeGroupTrips, revenue, todayRevenue, monthlyRevenue,
      activeSos, totalSos, activeSessions, aiChats,
    ] = await Promise.all([
      cnt(`select count(*) as c from public.users`),
      cnt(`select count(*) as c from public.users where created_at::date = current_date`),
      cnt(`select count(*) as c from public.users where last_login_at >= now() - interval '30 days'`),
      cnt(`select count(*) as c from public.users where is_blocked`),
      cnt(`select count(*) as c from public.users where suspended_at is not null`),
      cnt(`select count(*) as c from public.bookings`),
      cnt(`select count(*) as c from public.bookings where status = 'Active'`),
      cnt(`select count(*) as c from public.bookings where status = 'Completed'`),
      cnt(`select count(*) as c from public.bookings where status = 'Cancelled'`),
      cnt(`select count(*) as c from public.bookings where status = 'Pending'`),
      cnt(`select count(*) as c from public.group_bookings`),
      cnt(`select count(*) as c from public.group_bookings where status = 'Active'`),
      cnt(`select coalesce(sum(amount), 0) as c from public.payments where status = 'succeeded'`),
      cnt(`select coalesce(sum(amount), 0) as c from public.payments where status = 'succeeded' and created_at::date = current_date`),
      cnt(`select coalesce(sum(amount), 0) as c from public.payments where status = 'succeeded'
             and date_trunc('month', created_at) = date_trunc('month', now())`),
      cnt(`select count(*) as c from public.emergency_alerts where status = 'Active'`),
      cnt(`select count(*) as c from public.emergency_alerts`),
      cnt(`select count(*) as c from public.group_tracking_sessions where status = 'active'`),
      cnt(`select count(*) as c from public.ai_chat_history`),
    ]);
    return json({
      success: true,
      stats: {
        total_users: totalUsers, new_users_today: newUsersToday, active_users_30d: activeUsers30d,
        blocked_users: blockedUsers, suspended_users: suspendedUsers, total_bookings: totalBookings,
        active_bookings: activeBookings, completed_bookings: completedBookings, cancelled_bookings: cancelledBookings,
        pending_bookings: pendingBookings, total_group_bookings: totalGroupBookings, active_group_trips: activeGroupTrips,
        total_revenue: revenue, today_revenue: todayRevenue, monthly_revenue: monthlyRevenue,
        active_sos: activeSos, total_sos: totalSos, active_sessions: activeSessions, ai_chats: aiChats,
        system_health: "98%",
      },
    });
  });

  r.get("/admin/users", "admin", async ({ query }) => {
    const where = ["true"];
    const vals: unknown[] = [];
    const search = text(query.get("search"), 100);
    if (search) {
      vals.push(`%${search}%`);
      where.push(`(u.full_name ilike $1 or u.email ilike $1 or u.phone_number ilike $1)`);
    }
    const status = query.get("status");
    if (status === "blocked") where.push("u.is_blocked");
    if (status === "suspended") where.push("u.suspended_at is not null");
    if (status === "active") where.push("not u.is_blocked and u.suspended_at is null");
    const users = await q(
      `select u.user_id, u.full_name, u.email, u.phone_number, u.profile_picture_url, u.is_admin, u.is_blocked,
              u.auth_user_id as firebase_uid, u.auth_provider, u.role, u.suspended_at, u.suspended_reason,
              u.created_at, u.last_login_at,
              (select count(*) from public.bookings where user_id = u.user_id) as single_bookings,
              (select count(*) from public.group_booking_members where user_id = u.user_id) as group_trips,
              (select count(*) from public.payments where user_id = u.user_id and status = 'succeeded') as payments_count
       from public.users u where ${where.join(" and ")} order by u.created_at desc limit 200`, vals);
    return json({ success: true, users });
  });

  r.get("/admin/users/:id", "admin", async ({ params }) => {
    const id = idParam(params.id);
    const [user, emergencyContacts, bookings, payments, lastLocation] = await Promise.all([
      q1(`select u.user_id, u.full_name, u.email, u.phone_number, u.profile_picture_url, u.is_admin, u.is_blocked,
                 u.auth_user_id as firebase_uid, u.auth_provider, u.role, u.suspended_at, u.suspended_reason,
                 u.created_at, u.last_login_at
          from public.users u where u.user_id = $1`, [id]),
      q(`select contact_id as id, contact_name, contact_phone, relationship from public.emergency_contacts
         where user_id = $1 order by created_at`, [id]),
      q(`select b.booking_id, b.status, b.booking_date, b.travel_date, b.total_amount, b.payment_status,
                d.name as destination_name, d.city
         from public.bookings b left join public.destinations d on d.destination_id = b.destination_id
         where b.user_id = $1 order by b.created_at desc limit 10`, [id]),
      q(`select p.id, p.amount, p.currency, p.status, p.created_at, b.booking_id, d.name as destination_name
         from public.payments p left join public.bookings b on b.booking_id = p.booking_id
         left join public.destinations d on d.destination_id = b.destination_id
         where p.user_id = $1 order by p.created_at desc limit 10`, [id]),
      q1(`select latitude, longitude, captured_at from public.user_location_updates
          where user_identifier = 'user_' || $1::text order by captured_at desc limit 1`, [id]),
    ]);
    if (!user) return json({ success: false, message: "User not found" }, 404);
    return json({ success: true, user, emergencyContacts, bookings, payments, lastLocation });
  });

  const userFlag = (path: string, sqlText: string, action: string, withReason = false) =>
    r.put(path, "admin", async (c) => {
      const id = idParam(c.params.id);
      if (id === c.auth.userId && action !== "USER_UNBLOCKED" && action !== "USER_UNSUSPENDED") {
        fail(400, "You cannot change your own account status", { success: false });
      }
      const reason = text(c.body?.reason, 500);
      await exec(sqlText, withReason ? [reason ?? "", id] : [id]);
      await logAction(c, action, "user", id, { reason });
      const msg = { USER_BLOCKED: "User blocked", USER_UNBLOCKED: "User unblocked", USER_SUSPENDED: "User suspended",
                    USER_UNSUSPENDED: "User unsuspended" } as Record<string, string>;
      return json({ success: true, message: msg[action] });
    });

  userFlag("/admin/users/:id/block", `update public.users set is_blocked = true where user_id = $1`, "USER_BLOCKED");
  userFlag("/admin/users/:id/unblock", `update public.users set is_blocked = false where user_id = $1`, "USER_UNBLOCKED");
  userFlag("/admin/users/:id/suspend",
    `update public.users set suspended_at = now(), suspended_reason = $1 where user_id = $2`, "USER_SUSPENDED", true);
  userFlag("/admin/users/:id/unsuspend",
    `update public.users set suspended_at = null, suspended_reason = null where user_id = $1`, "USER_UNSUSPENDED");

  r.delete("/admin/users/:id", "admin", async (c) => {
    requireSuperAdmin(c);
    const id = idParam(c.params.id);
    if (id === c.auth.userId) return json({ success: false, message: "Cannot delete yourself" }, 400);
    const user = await q1(`select full_name, email, auth_user_id from public.users where user_id = $1`, [id]);
    if (!user) return json({ success: false, message: "User not found" }, 404);
    if (user.auth_user_id) await deleteAuthUser(user.auth_user_id);
    await exec(`delete from public.users where user_id = $1`, [id]);
    await logAction(c, "USER_DELETED", "user", id, { name: user.full_name, email: user.email });
    return json({ success: true, message: "User deleted" });
  });

  r.put("/admin/users/:id/make-admin", "admin", async (c) => {
    requireSuperAdmin(c);
    const id = idParam(c.params.id);
    await exec(`update public.users set is_admin = true, role = 'admin' where user_id = $1`, [id]);
    await logAction(c, "USER_PROMOTED_ADMIN", "user", id, {});
    return json({ success: true, message: "User promoted to admin" });
  });

  r.get("/admin/bookings", "admin", async ({ query }) => {
    const where = ["true"];
    const vals: unknown[] = [];
    const status = text(query.get("status"), 30);
    if (status) { vals.push(status); where.push(`b.status = $${vals.length}`); }
    const search = text(query.get("search"), 100);
    if (search) { vals.push(`%${search}%`); where.push(`(u.full_name ilike $${vals.length} or d.name ilike $${vals.length})`); }
    const rows = await q(
      `select b.booking_id, b.status, b.booking_date, b.travel_date, b.estimated_duration_days, b.num_travelers,
              b.total_amount, b.payment_status, b.created_at, u.user_id, u.full_name, u.email,
              coalesce(d.name, b.notes) as destination_name, d.city
       from public.bookings b join public.users u on u.user_id = b.user_id
       left join public.destinations d on d.destination_id = b.destination_id
       where ${where.join(" and ")} order by b.created_at desc limit 200`, vals);
    return json({ success: true, bookings: rows });
  });

  r.put("/admin/bookings/:id/cancel", "admin", async (c) => {
    const id = idParam(c.params.id);
    const reason = text(c.body?.reason, 1000);
    await exec(`update public.bookings set status = 'Cancelled', cancelled_at = now(), cancellation_reason = $1
                where booking_id = $2`, [reason ?? "Cancelled by admin", id]);
    await logAction(c, "BOOKING_CANCELLED", "booking", id, { reason });
    return json({ success: true, message: "Booking cancelled" });
  });

  r.get("/admin/emergency-alerts", "admin", async ({ query }) => {
    const wf = text(query.get("workflow_status"), 30);
    const alerts = await q(
      `select ea.id, ea.status, ea.workflow_status, ea.latitude, ea.longitude, ea.message, ea.trip_id, ea.trip_type,
              ea.created_at, ea.resolved_at, ea.resolution_notes, ea.acknowledged_at, ea.in_progress_at,
              ea.assigned_admin_id, u.user_id, u.full_name, u.email, u.phone_number, gb.trip_name,
              coalesce((select json_agg(json_build_object('contact_name', ec.contact_name,
                         'contact_phone', ec.contact_phone, 'relationship', ec.relationship))
                        from public.emergency_contacts ec where ec.user_id = ea.user_id), '[]'::json) as emergency_contacts
       from public.emergency_alerts ea join public.users u on u.user_id = ea.user_id
       left join public.group_bookings gb on ea.trip_type = 'group' and ea.trip_id = gb.group_booking_id
       ${wf ? "where ea.workflow_status = $1" : ""}
       order by ea.created_at desc limit 100`, wf ? [wf] : []);
    return json({ success: true, alerts });
  });

  r.put("/admin/emergency-alerts/:id/workflow", "admin", async (c) => {
    const id = idParam(c.params.id);
    const wf = c.body?.workflow_status;
    if (!["New", "Acknowledged", "In Progress", "Resolved"].includes(wf)) {
      return json({ success: false, message: "Invalid workflow_status" }, 400);
    }
    const notes = text(c.body?.resolution_notes, 2000) ?? "";
    const extra = wf === "Acknowledged" ? ", acknowledged_at = now(), status = case when status = 'Active' then 'Acknowledged' else status end"
      : wf === "In Progress" ? ", in_progress_at = now()"
      : wf === "Resolved" ? ", status = 'Resolved', resolved_at = now(), resolution_notes = $4" : "";
    await exec(`update public.emergency_alerts set workflow_status = $1, assigned_admin_id = $2 ${extra} where id = $3`,
      wf === "Resolved" ? [wf, c.auth.admin!.adminId, id, notes] : [wf, c.auth.admin!.adminId, id]);
    const ts = new Date().toISOString();
    await emit("emergency:admin", "emergency:workflow_updated", { alert_id: id, workflow_status: wf, timestamp: ts });
    if (wf === "Resolved") await emit("emergency:admin", "emergency:resolved", { alert_id: id, timestamp: ts });
    await logAction(c, `SOS_${String(wf).toUpperCase().replace(" ", "_")}`, "emergency_alert", id, { resolution_notes: notes });
    return json({ success: true, message: `Alert moved to ${wf}` });
  });

  r.put("/admin/emergency-alerts/:id/resolve", "admin", async (c) => {
    const id = idParam(c.params.id);
    await exec(`update public.emergency_alerts set status = 'Resolved', resolved_at = now(), workflow_status = 'Resolved',
                resolution_notes = $1, assigned_admin_id = $2 where id = $3`,
      [text(c.body?.resolution_notes, 2000) ?? "", c.auth.admin!.adminId, id]);
    await emit("emergency:admin", "emergency:resolved", { alert_id: id, timestamp: new Date().toISOString() });
    await logAction(c, "SOS_RESOLVED", "emergency_alert", id, {});
    return json({ success: true, message: "Alert resolved" });
  });

  r.get("/admin/emergency-map", "admin", async () => {
    const alerts = await q(
      `select ea.id, ea.user_id, ea.trip_id, ea.trip_type, ea.latitude, ea.longitude, ea.message, ea.status, ea.created_at,
              u.full_name as user_name, u.phone_number as user_phone, gb.trip_name,
              case when ea.trip_type = 'group' and ea.trip_id is not null then coalesce((
                select json_agg(json_build_object('user_id', u2.user_id, 'user_name', u2.full_name,
                         'latitude', l.latitude, 'longitude', l.longitude, 'last_seen', l.captured_at))
                from public.group_booking_members m join public.users u2 on u2.user_id = m.user_id
                left join lateral (select latitude, longitude, captured_at from public.user_location_updates
                                   where user_identifier = 'user_' || u2.user_id order by captured_at desc limit 1) l on true
                where m.group_booking_id = ea.trip_id), '[]'::json) else '[]'::json end as group_members
       from public.emergency_alerts ea join public.users u on u.user_id = ea.user_id
       left join public.group_bookings gb on ea.trip_type = 'group' and ea.trip_id = gb.group_booking_id
       where ea.status = 'Active' order by ea.created_at desc`);
    return json({ success: true, alerts });
  });

  r.get("/admin/trips", "admin", async () => {
    const trips = await q(
      `select gb.group_booking_id, gb.trip_name, gb.status, gb.start_date, gb.end_date, gb.created_at, gb.max_members,
              u.full_name as organizer, u.email as organizer_email, count(gbm.user_id) as member_count,
              d.name as destination_name
       from public.group_bookings gb join public.users u on u.user_id = gb.created_by
       left join public.group_booking_members gbm on gbm.group_booking_id = gb.group_booking_id
       left join public.destinations d on d.destination_id = gb.destination_id
       group by gb.group_booking_id, u.user_id, d.destination_id
       order by gb.created_at desc limit 200`);
    return json({ success: true, trips });
  });

  r.get("/admin/payments", "admin", async ({ query }) => {
    const where = ["true"];
    const vals: unknown[] = [];
    const status = text(query.get("status"), 20);
    if (status) { vals.push(status); where.push(`p.status = $${vals.length}`); }
    if (query.get("refund_pending") === "true") {
      where.push("p.refund_requested_at is not null and p.refund_approved_at is null and p.refund_rejected_at is null");
    }
    const search = text(query.get("search"), 100);
    if (search) { vals.push(`%${search}%`); where.push(`(u.full_name ilike $${vals.length} or u.email ilike $${vals.length})`); }
    const rows = await q(
      `select p.id, p.user_id, p.booking_id, p.amount, p.currency, p.status, p.stripe_payment_intent_id,
              p.created_at, p.updated_at, p.refund_requested_at, p.refund_approved_at, p.refund_rejected_at,
              p.refund_admin_notes, u.full_name, u.email, d.name as destination_name
       from public.payments p join public.users u on u.user_id = p.user_id
       left join public.bookings b on b.booking_id = p.booking_id
       left join public.destinations d on d.destination_id = b.destination_id
       where ${where.join(" and ")}
       order by p.refund_requested_at desc nulls last, p.created_at desc limit 200`, vals);
    return json({ success: true, payments: rows });
  });

  r.put("/admin/payments/:id/approve-refund", "admin", async (c) => {
    const id = idParam(c.params.id);
    const notes = text(c.body?.notes, 500) ?? "";
    const pay = await q1(`select * from public.payments where id = $1`, [id]);
    if (!pay) return json({ success: false, message: "Payment not found" }, 404);
    if (pay.status === "refunded") return json({ success: false, message: "Payment already refunded" }, 400);
    let refundId: string | null = null;
    if (pay.stripe_payment_intent_id && pay.status === "succeeded") {
      if (!stripeConfigured()) return json({ success: false, message: "Stripe not configured" }, 500);
      try {
        const refund = await stripe("POST", "refunds", { payment_intent: pay.stripe_payment_intent_id });
        refundId = refund.id;
      } catch (e) {
        return json({ success: false, message: `Stripe refund failed: ${(e as Error).message}` }, 502);
      }
    }
    await exec(`update public.payments set status = 'refunded', refund_approved_at = now(), refund_admin_notes = $1
                where id = $2`, [notes, id]);
    if (pay.booking_id) {
      await exec(`update public.bookings set status = 'Refunded', payment_status = 'Refunded' where booking_id = $1`,
        [pay.booking_id]);
    }
    await logAction(c, "REFUND_APPROVED", "payment", id, { notes, stripeRefundId: refundId });
    return json({ success: true, message: "Refund approved and processed", stripe_refund_id: refundId });
  });

  r.put("/admin/payments/:id/reject-refund", "admin", async (c) => {
    const id = idParam(c.params.id);
    const notes = text(c.body?.notes, 500) ?? "";
    await exec(`update public.payments set refund_rejected_at = now(), refund_admin_notes = $1 where id = $2`, [notes, id]);
    await logAction(c, "REFUND_REJECTED", "payment", id, { notes });
    return json({ success: true, message: "Refund rejected" });
  });

  r.get("/admin/analytics", "admin", async () => {
    const [totals, recentUsers, bookingsByStatus, monthlyBookings, monthlyRevenue, monthlySos, popular] = await Promise.all([
      q1(`select (select count(*) from public.users) as total_users,
                 (select count(*) from public.bookings) as total_bookings,
                 (select count(*) from public.group_bookings) as total_group_bookings,
                 (select count(*) from public.emergency_alerts) as total_sos,
                 (select coalesce(sum(amount), 0) from public.payments where status = 'succeeded') as total_revenue`),
      q(`select to_char(created_at::date, 'YYYY-MM-DD') as d, count(*) as c from public.users
         where created_at >= now() - interval '30 days' group by 1 order by 1`),
      q(`select status, count(*) as c from public.bookings group by status`),
      q(`select to_char(created_at, 'YYYY-MM') as m, count(*) as c from public.bookings group by 1 order by 1 desc limit 12`),
      q(`select to_char(created_at, 'YYYY-MM') as m, coalesce(sum(amount), 0) as c from public.payments
         where status = 'succeeded' group by 1 order by 1 desc limit 12`),
      q(`select to_char(created_at, 'YYYY-MM') as m, count(*) as c from public.emergency_alerts group by 1 order by 1 desc limit 12`),
      q(`select d.name, d.city, count(b.booking_id) as c from public.destinations d
         left join public.bookings b on b.destination_id = d.destination_id
         group by d.destination_id order by c desc limit 10`),
    ]);
    return json({
      success: true,
      analytics: {
        totals, recentUsers, bookingsByStatus,
        monthlyBookings: monthlyBookings.reverse(), monthlyRevenue: monthlyRevenue.reverse(),
        monthlySos: monthlySos.reverse(), popularDestinations: popular,
      },
    });
  });

  r.get("/admin/activity-logs", "admin", async ({ query }) => {
    const action = text(query.get("action"), 100);
    const limit = Math.min(Math.max(toInt(query.get("limit"), 100)!, 1), 500);
    const logs = await q(
      `select * from public.admin_activity_logs ${action ? "where action = $2" : ""} order by created_at desc limit $1`,
      action ? [limit, action] : [limit]);
    return json({ success: true, logs });
  });

  r.post("/admin/broadcast-notification", "admin", async (c) => {
    requireSuperAdmin(c);
    const title = text(c.body?.title, 255), message = text(c.body?.message, 2000);
    const type = text(c.body?.type, 100) ?? "admin_broadcast";
    if (!title || !message) return json({ success: false, error: "title and message required" }, 400);
    const sent = await exec(
      `insert into public.notifications (user_id, title, message, type)
       select user_id, $1, $2, $3 from public.users where not is_blocked`, [title, message, type]);
    await emit("broadcast:all", "notification:new", { title, message, type });
    await logAction(c, "BROADCAST_SENT", "system", null, { title, sentTo: sent });
    return json({ success: true, sent_to: sent, message: "Broadcast sent" });
  });

  r.get("/admin/reports/users", "admin", async () => {
    const users = await q(
      `select u.user_id, u.full_name, u.email, u.phone_number, u.is_blocked, u.suspended_at, u.created_at, u.last_login_at,
              (select count(*) from public.bookings b where b.user_id = u.user_id) as bookings,
              (select count(*) from public.group_booking_members m where m.user_id = u.user_id) as group_trips,
              (select coalesce(sum(p.amount), 0) from public.payments p where p.user_id = u.user_id and p.status = 'succeeded') as total_spent
       from public.users u order by u.created_at desc`);
    return json({ success: true, users });
  });

  r.get("/admin/reports/revenue", "admin", async () => {
    const [summary, monthly, byDestination] = await Promise.all([
      q1(`select coalesce(sum(amount) filter (where status = 'succeeded'), 0) as total_revenue,
                 coalesce(sum(amount) filter (where status = 'refunded'), 0) as total_refunded,
                 count(*) filter (where status = 'succeeded') as successful_payments,
                 count(*) filter (where status = 'failed') as failed_payments
          from public.payments`),
      q(`select to_char(created_at, 'YYYY-MM') as month,
                coalesce(sum(amount) filter (where status = 'succeeded'), 0) as revenue, count(*) as transactions
         from public.payments group by 1 order by 1 desc limit 12`),
      q(`select d.name as destination, count(distinct b.booking_id) as bookings, coalesce(sum(p.amount), 0) as revenue
         from public.destinations d
         left join public.bookings b on b.destination_id = d.destination_id
         left join public.payments p on p.booking_id = b.booking_id and p.status = 'succeeded'
         group by d.destination_id order by revenue desc limit 10`),
    ]);
    return json({ success: true, summary, monthly, byDestination });
  });

  r.get("/admin/reports/sos", "admin", async () => {
    const alerts = await q(
      `select ea.id, ea.status, ea.workflow_status, ea.latitude, ea.longitude, ea.message, ea.created_at,
              ea.resolved_at, ea.resolution_notes, u.full_name, u.email, u.phone_number, gb.trip_name
       from public.emergency_alerts ea join public.users u on u.user_id = ea.user_id
       left join public.group_bookings gb on ea.trip_type = 'group' and ea.trip_id = gb.group_booking_id
       order by ea.created_at desc`);
    return json({ success: true, alerts });
  });

  r.get("/admin/sos-alerts", "admin", async () => {
    const alerts = await q(`select sa.*, u.full_name from public.sos_alerts sa join public.users u on u.user_id = sa.user_id
                            order by sa.created_at desc limit 50`);
    return json({ success: true, alerts });
  });

  r.get("/admin/bookings/stats", "admin", async () => {
    const stats = await q1(`select count(*) as total_bookings,
                                   count(*) filter (where status = 'Pending') as pending,
                                   count(*) filter (where status = 'Active') as active,
                                   count(*) filter (where status = 'Completed') as completed,
                                   count(*) filter (where status = 'Cancelled') as cancelled
                            from public.bookings`);
    return json({ success: true, stats: stats ?? {} });
  });

  r.get("/admin/group-bookings/stats", "admin", async () => {
    const stats = await q1(
      `select count(distinct gb.group_booking_id) as total_group_bookings,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Planning') as planning,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Active') as active,
              count(distinct gb.group_booking_id) filter (where gb.status = 'Completed') as completed,
              count(distinct gbm.user_id) as total_members, count(distinct gts.id) as active_tracking_sessions
       from public.group_bookings gb
       left join public.group_booking_members gbm on gbm.group_booking_id = gb.group_booking_id
       left join public.group_tracking_sessions gts on gts.group_booking_id = gb.group_booking_id and gts.status = 'active'`);
    return json({ success: true, stats: stats ?? {} });
  });

  // ── tour packages ─────────────────────────────────────────────────────────
  r.get("/admin/tours", "admin", async () => {
    const rows = await q(`select * from public.tour_packages where is_active order by total_price asc`);
    return json({ success: true, packages: rows });
  });

  r.post("/admin/tours", "admin", async (c) => {
    const v = pkgValues(c.body);
    if (!v.title) fail(400, "title is required");
    const row = await q1(
      `insert into public.tour_packages (${PKG_COLS.join(", ")}, is_ai_generated, created_by_admin)
       values ($1, $2, $3, $4, $5, $6, $7::text::jsonb, $8::text::jsonb, $9::text::jsonb, $10, $11, $12, $13) returning package_id`,
      [...PKG_COLS.map((k) => v[k]), c.body?.is_ai_generated === true, c.auth.admin!.adminId]);
    await logAction(c, "create_tour_package", "tour_package", row!.package_id, { title: v.title });
    return json({ success: true, package_id: row!.package_id }, 201);
  });

  r.put("/admin/tours/:id", "admin", async (c) => {
    const id = idParam(c.params.id);
    const v = pkgValues(c.body);
    if (!v.title) fail(400, "title is required");
    await exec(
      `update public.tour_packages set title = $1, description = $2, duration_days = $3, total_price = $4,
              price_per_day = $5, category = $6, destinations = $7::text::jsonb, itinerary = $8::text::jsonb, includes = $9::text::jsonb,
              image_url = $10, max_travelers = $11 where package_id = $12`,
      [...PKG_COLS.map((k) => v[k]), id]);
    await logAction(c, "update_tour_package", "tour_package", id, { title: v.title });
    return json({ success: true });
  });

  r.delete("/admin/tours/:id", "admin", async (c) => {
    const id = idParam(c.params.id);
    await exec(`update public.tour_packages set is_active = false where package_id = $1`, [id]);
    await logAction(c, "delete_tour_package", "tour_package", id, {});
    return json({ success: true });
  });

  // ── virtual tours ─────────────────────────────────────────────────────────
  r.get("/admin/virtual-tours", "admin", async () => {
    const tours = await q(
      `select vt.*, d.name as destination_name,
              (select count(*) from public.virtual_tour_scenes where tour_id = vt.id) as scene_count
       from public.virtual_tours vt left join public.destinations d on d.destination_id = vt.destination_id
       order by vt.created_at desc`);
    return json({ success: true, tours });
  });

  r.post("/admin/virtual-tours", "admin", async (c) => {
    const title = text(c.body?.title, 255);
    if (!title) fail(400, "title is required");
    const row = await q1(
      `insert into public.virtual_tours (destination_id, title, description, thumbnail_url) values ($1, $2, $3, $4) returning id`,
      [toInt(c.body?.destination_id), title, c.body?.description ?? null, c.body?.thumbnail_url || null]);
    await logAction(c, "create_virtual_tour", "virtual_tour", row!.id, { title });
    return json({ success: true, tour: await getTourById(row!.id, true) }, 201);
  });

  r.put("/admin/virtual-tours/scenes/:sceneId", "admin", async (c) => {
    const id = idParam(c.params.sceneId);
    const b = c.body ?? {};
    await exec(
      `update public.virtual_tour_scenes set scene_name = $1, panorama_url = $2, description = $3, thumbnail_url = $4,
              scene_order = $5, ai_narration = $6 where id = $7`,
      [text(b.scene_name, 255), b.panorama_url, b.description ?? null, b.thumbnail_url || null,
       toInt(b.scene_order, 0), b.ai_narration || null, id]);
    return json({ success: true, scene: await q1(`select * from public.virtual_tour_scenes where id = $1`, [id]) });
  });

  r.delete("/admin/virtual-tours/scenes/:sceneId", "admin", async (c) => {
    await exec(`delete from public.virtual_tour_scenes where id = $1`, [idParam(c.params.sceneId)]);
    return json({ success: true });
  });

  r.post("/admin/virtual-tours/scenes/:sceneId/hotspots", "admin", async (c) => {
    const b = c.body ?? {};
    if (!["scene", "info"].includes(b.type)) fail(400, "type must be scene or info");
    const row = await q1(
      `insert into public.virtual_tour_hotspots (scene_id, type, target_scene_id, title, text, pitch, yaw)
       values ($1, $2, $3, $4, $5, $6, $7) returning *`,
      [idParam(c.params.sceneId), b.type, toInt(b.target_scene_id), b.title || null, b.text || null,
       toNum(b.pitch) ?? 0, toNum(b.yaw) ?? 0]);
    return json({ success: true, hotspot: row }, 201);
  });

  r.put("/admin/virtual-tours/hotspots/:hotspotId", "admin", async (c) => {
    const b = c.body ?? {};
    if (!["scene", "info"].includes(b.type)) fail(400, "type must be scene or info");
    const row = await q1(
      `update public.virtual_tour_hotspots set type = $1, target_scene_id = $2, title = $3, text = $4, pitch = $5, yaw = $6
       where id = $7 returning *`,
      [b.type, toInt(b.target_scene_id), b.title || null, b.text || null, toNum(b.pitch) ?? 0, toNum(b.yaw) ?? 0,
       idParam(c.params.hotspotId)]);
    return json({ success: true, hotspot: row });
  });

  r.delete("/admin/virtual-tours/hotspots/:hotspotId", "admin", async (c) => {
    await exec(`delete from public.virtual_tour_hotspots where id = $1`, [idParam(c.params.hotspotId)]);
    return json({ success: true });
  });

  r.post("/admin/virtual-tours/:tourId/scenes", "admin", async (c) => {
    const b = c.body ?? {};
    if (!text(b.scene_name) || !text(b.panorama_url, 1000)) fail(400, "scene_name and panorama_url required");
    const row = await q1(
      `insert into public.virtual_tour_scenes (tour_id, scene_name, panorama_url, description, thumbnail_url, scene_order)
       values ($1, $2, $3, $4, $5, $6) returning *`,
      [idParam(c.params.tourId), text(b.scene_name), text(b.panorama_url, 1000), b.description ?? null,
       b.thumbnail_url || null, toInt(b.scene_order, 0)]);
    return json({ success: true, scene: row }, 201);
  });

  r.put("/admin/virtual-tours/:id", "admin", async (c) => {
    const id = idParam(c.params.id);
    const b = c.body ?? {};
    const title = text(b.title, 255);
    if (!title) fail(400, "title is required");
    await exec(
      `update public.virtual_tours set destination_id = $1, title = $2, description = $3, thumbnail_url = $4,
              is_active = $5 where id = $6`,
      [toInt(b.destination_id), title, b.description ?? null, b.thumbnail_url || null,
       b.is_active === undefined ? true : (b.is_active === true || b.is_active === 1), id]);
    await logAction(c, "update_virtual_tour", "virtual_tour", id, { title });
    return json({ success: true, tour: await getTourById(id, true) });
  });

  r.delete("/admin/virtual-tours/:id", "admin", async (c) => {
    const id = idParam(c.params.id);
    await exec(`delete from public.virtual_tours where id = $1`, [id]);
    await logAction(c, "delete_virtual_tour", "virtual_tour", id, {});
    return json({ success: true });
  });
}
