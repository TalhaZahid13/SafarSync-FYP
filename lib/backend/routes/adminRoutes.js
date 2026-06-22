const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { authenticate }  = require('../middleware/authMiddleware');
const { adminOnly }     = require('../middleware/adminMiddleware');
const { requireRole }   = require('../middleware/rbacMiddleware');

// All admin routes require authentication + admin role
router.use(authenticate, adminOnly);

// ─── Helper: Promise wrapper ──────────────────────────────────────────────────
const q = (sql, params = []) =>
  db.promise().query(sql, params).then(([rows]) => rows);

const q1 = (sql, params = []) =>
  db.promise().query(sql, params).then(([rows]) => rows[0] ?? null);

const cnt = async (sql, params = []) => {
  const row = await q1(sql, params);
  if (!row) return 0;
  const v = Object.values(row)[0];
  return typeof v === 'number' ? v : parseInt(v ?? '0', 10) || 0;
};

// ─── Helper: Activity log ─────────────────────────────────────────────────────
const logAction = async (req, action, targetType, targetId, details) => {
  try {
    const adminId   = req.user?.adminId || req.user?.userId || 0;
    const adminName = req.user?.adminName || req.user?.email || 'Admin';
    const ip        = req.ip || req.socket?.remoteAddress || '';
    await q(
      `INSERT INTO admin_activity_logs
         (admin_id, admin_name, action, target_type, target_id, details, ip_address)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [adminId, adminName, action, targetType, targetId,
       typeof details === 'object' ? JSON.stringify(details) : (details ?? ''), ip]
    );
  } catch (_) {}
};

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────
router.get('/dashboard', async (req, res) => {
  try {
    const [
      totalUsers, newUsersToday, activeUsers30d, blockedUsers, suspendedUsers,
      totalBookings, activeBookings, completedBookings, cancelledBookings, pendingBookings,
      totalGroupBookings, activeGroupTrips,
      revenueRow, todayRevenueRow, monthlyRevenueRow,
      activeSos, totalSos, activeSessions, aiChats,
    ] = await Promise.all([
      cnt('SELECT COUNT(*) AS c FROM users'),
      cnt("SELECT COUNT(*) AS c FROM users WHERE DATE(created_at)=CURDATE()"),
      cnt("SELECT COUNT(*) AS c FROM users WHERE last_login_at >= DATE_SUB(NOW(),INTERVAL 30 DAY)"),
      cnt("SELECT COUNT(*) AS c FROM users WHERE is_blocked=1"),
      cnt("SELECT COUNT(*) AS c FROM users WHERE suspended_at IS NOT NULL"),
      cnt('SELECT COUNT(*) AS c FROM bookings'),
      cnt("SELECT COUNT(*) AS c FROM bookings WHERE status='Active'"),
      cnt("SELECT COUNT(*) AS c FROM bookings WHERE status='Completed'"),
      cnt("SELECT COUNT(*) AS c FROM bookings WHERE status='Cancelled'"),
      cnt("SELECT COUNT(*) AS c FROM bookings WHERE status='Pending'"),
      cnt('SELECT COUNT(*) AS c FROM group_bookings'),
      cnt("SELECT COUNT(*) AS c FROM group_bookings WHERE status='Active'"),
      q1("SELECT COALESCE(SUM(amount),0) AS c FROM payments WHERE status='succeeded'"),
      q1("SELECT COALESCE(SUM(amount),0) AS c FROM payments WHERE status='succeeded' AND DATE(created_at)=CURDATE()"),
      q1("SELECT COALESCE(SUM(amount),0) AS c FROM payments WHERE status='succeeded' AND MONTH(created_at)=MONTH(NOW()) AND YEAR(created_at)=YEAR(NOW())"),
      cnt("SELECT COUNT(*) AS c FROM emergency_alerts WHERE status='Active'"),
      cnt('SELECT COUNT(*) AS c FROM emergency_alerts'),
      cnt("SELECT COUNT(*) AS c FROM group_tracking_sessions WHERE status='active'"),
      cnt('SELECT COUNT(*) AS c FROM ai_chat_history'),
    ]);

    res.json({
      success: true,
      stats: {
        total_users:          totalUsers,
        new_users_today:      newUsersToday,
        active_users_30d:     activeUsers30d,
        blocked_users:        blockedUsers,
        suspended_users:      suspendedUsers,
        total_bookings:       totalBookings,
        active_bookings:      activeBookings,
        completed_bookings:   completedBookings,
        cancelled_bookings:   cancelledBookings,
        pending_bookings:     pendingBookings,
        total_group_bookings: totalGroupBookings,
        active_group_trips:   activeGroupTrips,
        total_revenue:        parseFloat(revenueRow?.c ?? 0),
        today_revenue:        parseFloat(todayRevenueRow?.c ?? 0),
        monthly_revenue:      parseFloat(monthlyRevenueRow?.c ?? 0),
        active_sos:           activeSos,
        total_sos:            totalSos,
        active_sessions:      activeSessions,
        ai_chats:             aiChats,
        system_health:        '98%',
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET /api/admin/users ─────────────────────────────────────────────────────
router.get('/users', async (req, res) => {
  try {
    const { search, status } = req.query;
    let sql = `
      SELECT u.user_id, u.full_name, u.email, u.phone_number,
             u.profile_picture_url, u.is_admin, u.is_blocked,
             u.suspended_at, u.suspended_reason, u.created_at, u.last_login_at,
             (SELECT COUNT(*) FROM bookings WHERE user_id=u.user_id) AS single_bookings,
             (SELECT COUNT(*) FROM group_booking_members WHERE user_id=u.user_id) AS group_trips,
             (SELECT COUNT(*) FROM payments WHERE user_id=u.user_id AND status='succeeded') AS payments_count
      FROM users u WHERE 1=1`;
    const params = [];
    if (search) {
      sql += ' AND (u.full_name LIKE ? OR u.email LIKE ? OR u.phone_number LIKE ?)';
      const s = `%${search}%`; params.push(s, s, s);
    }
    if (status === 'blocked')   sql += ' AND u.is_blocked=1';
    if (status === 'suspended') sql += ' AND u.suspended_at IS NOT NULL';
    if (status === 'active')    sql += ' AND u.is_blocked=0 AND u.suspended_at IS NULL';
    sql += ' ORDER BY u.created_at DESC LIMIT 200';
    const users = await q(sql, params);
    res.json({ success: true, users });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET /api/admin/users/:id ─────────────────────────────────────────────────
router.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [user, emergencyContacts, bookings, payments, lastLocation] = await Promise.all([
      q1(`SELECT u.user_id, u.full_name, u.email, u.phone_number,
                 u.profile_picture_url, u.is_admin, u.is_blocked,
                 u.suspended_at, u.suspended_reason, u.created_at, u.last_login_at
          FROM users u WHERE u.user_id=?`, [id]),
      q(`SELECT ec.id, ec.contact_name, ec.contact_phone, ec.relationship
         FROM emergency_contacts ec WHERE ec.user_id=? ORDER BY ec.created_at`, [id]),
      q(`SELECT b.booking_id, b.status, b.booking_date, b.travel_date,
                b.total_amount, b.payment_status,
                d.name AS destination_name, d.city
         FROM bookings b
         LEFT JOIN destinations d ON b.destination_id=d.destination_id
         WHERE b.user_id=? ORDER BY b.created_at DESC LIMIT 10`, [id]),
      q(`SELECT p.id, p.amount, p.currency, p.status, p.created_at,
                b.booking_id, d.name AS destination_name
         FROM payments p
         LEFT JOIN bookings b ON p.booking_id=b.booking_id
         LEFT JOIN destinations d ON b.destination_id=d.destination_id
         WHERE p.user_id=? ORDER BY p.created_at DESC LIMIT 10`, [id]),
      q1(`SELECT latitude, longitude, captured_at
          FROM user_location_updates
          WHERE user_identifier=CONCAT('user_',?)
          ORDER BY captured_at DESC LIMIT 1`, [id]),
    ]);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, user, emergencyContacts, bookings, payments, lastLocation });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── PUT /api/admin/users/:id/block ──────────────────────────────────────────
router.put('/users/:id/block', async (req, res) => {
  try {
    const { id } = req.params;
    await q('UPDATE users SET is_blocked=1 WHERE user_id=?', [id]);
    await logAction(req, 'USER_BLOCKED', 'user', id, { reason: req.body?.reason });
    res.json({ success: true, message: 'User blocked' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/users/:id/unblock ────────────────────────────────────────
router.put('/users/:id/unblock', async (req, res) => {
  try {
    const { id } = req.params;
    await q('UPDATE users SET is_blocked=0 WHERE user_id=?', [id]);
    await logAction(req, 'USER_UNBLOCKED', 'user', id, {});
    res.json({ success: true, message: 'User unblocked' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/users/:id/suspend ────────────────────────────────────────
router.put('/users/:id/suspend', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body ?? {};
    await q('UPDATE users SET suspended_at=NOW(), suspended_reason=? WHERE user_id=?', [reason ?? '', id]);
    await logAction(req, 'USER_SUSPENDED', 'user', id, { reason });
    res.json({ success: true, message: 'User suspended' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/users/:id/unsuspend ──────────────────────────────────────
router.put('/users/:id/unsuspend', async (req, res) => {
  try {
    const { id } = req.params;
    await q('UPDATE users SET suspended_at=NULL, suspended_reason=NULL WHERE user_id=?', [id]);
    await logAction(req, 'USER_UNSUSPENDED', 'user', id, {});
    res.json({ success: true, message: 'User unsuspended' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── DELETE /api/admin/users/:id ─────────────────────────────────────────────
router.delete('/users/:id', requireRole('super_admin'), async (req, res) => {
  try {
    const { id } = req.params;
    if (parseInt(id) === (req.user?.userId || req.user?.adminId)) {
      return res.status(400).json({ success: false, message: 'Cannot delete yourself' });
    }
    const user = await q1('SELECT full_name, email FROM users WHERE user_id=?', [id]);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    await q('DELETE FROM users WHERE user_id=?', [id]);
    await logAction(req, 'USER_DELETED', 'user', id, { name: user.full_name, email: user.email });
    res.json({ success: true, message: 'User deleted' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/users/:id/make-admin ─────────────────────────────────────
router.put('/users/:id/make-admin', requireRole('super_admin'), async (req, res) => {
  try {
    const { id } = req.params;
    await q('UPDATE users SET is_admin=1 WHERE user_id=?', [id]);
    await logAction(req, 'USER_PROMOTED_ADMIN', 'user', id, {});
    res.json({ success: true, message: 'User promoted to admin' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/bookings ──────────────────────────────────────────────────
router.get('/bookings', async (req, res) => {
  try {
    const { status, search } = req.query;
    let sql = `
      SELECT b.booking_id, b.status, b.booking_date, b.travel_date,
             b.estimated_duration_days, b.num_travelers, b.total_amount,
             b.payment_status, b.created_at,
             u.user_id, u.full_name, u.email,
             d.name AS destination_name, d.city
      FROM bookings b
      JOIN  users u ON b.user_id=u.user_id
      JOIN  destinations d ON b.destination_id=d.destination_id
      WHERE 1=1`;
    const params = [];
    if (status) { sql += ' AND b.status=?'; params.push(status); }
    if (search) {
      sql += ' AND (u.full_name LIKE ? OR d.name LIKE ?)';
      const s = `%${search}%`; params.push(s, s);
    }
    sql += ' ORDER BY b.created_at DESC LIMIT 200';
    const bookings = await q(sql, params);
    res.json({ success: true, bookings });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/bookings/:id/cancel ──────────────────────────────────────
router.put('/bookings/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body ?? {};
    await q(
      "UPDATE bookings SET status='Cancelled', cancelled_at=NOW(), cancellation_reason=? WHERE booking_id=?",
      [reason ?? 'Cancelled by admin', id]
    );
    await logAction(req, 'BOOKING_CANCELLED', 'booking', id, { reason });
    res.json({ success: true, message: 'Booking cancelled' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/emergency-alerts ─────────────────────────────────────────
router.get('/emergency-alerts', async (req, res) => {
  try {
    const { workflow_status } = req.query;
    let sql = `
      SELECT ea.id, ea.status, ea.workflow_status, ea.latitude, ea.longitude,
             ea.message, ea.trip_id, ea.trip_type, ea.created_at, ea.resolved_at,
             ea.resolution_notes, ea.acknowledged_at, ea.in_progress_at,
             ea.assigned_admin_id,
             u.user_id, u.full_name, u.email, u.phone_number,
             gb.trip_name
      FROM emergency_alerts ea
      JOIN  users u ON ea.user_id=u.user_id
      LEFT JOIN group_bookings gb ON ea.trip_type='group' AND ea.trip_id=gb.group_booking_id
      WHERE 1=1`;
    const params = [];
    if (workflow_status) { sql += ' AND ea.workflow_status=?'; params.push(workflow_status); }
    sql += ' ORDER BY ea.created_at DESC LIMIT 100';
    const alerts = await q(sql, params);

    // Enrich with emergency contacts
    const enriched = await Promise.all(alerts.map(async (alert) => {
      const contacts = await q(
        `SELECT ec.contact_name, ec.contact_phone, ec.relationship
         FROM emergency_contacts ec WHERE ec.user_id=?`, [alert.user_id]
      );
      return { ...alert, emergency_contacts: contacts };
    }));
    res.json({ success: true, alerts: enriched });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/emergency-alerts/:id/workflow ────────────────────────────
router.put('/emergency-alerts/:id/workflow', async (req, res) => {
  try {
    const { id } = req.params;
    const { workflow_status, resolution_notes } = req.body ?? {};
    const valid = ['New', 'Acknowledged', 'In Progress', 'Resolved'];
    if (!valid.includes(workflow_status)) {
      return res.status(400).json({ success: false, message: 'Invalid workflow_status' });
    }
    const adminId = req.user?.adminId || req.user?.userId || null;
    const parts = ['workflow_status=?', 'assigned_admin_id=?'];
    const params = [workflow_status, adminId];
    if (workflow_status === 'Acknowledged') parts.push('acknowledged_at=NOW()');
    else if (workflow_status === 'In Progress') parts.push('in_progress_at=NOW()');
    else if (workflow_status === 'Resolved') {
      parts.push("status='Resolved'", 'resolved_at=NOW()', 'resolution_notes=?');
      params.push(resolution_notes ?? '');
    }
    params.push(id);
    await q(`UPDATE emergency_alerts SET ${parts.join(',')} WHERE id=?`, params);
    if (global.io) {
      global.io.to('emergency:admin').emit('emergency:workflow_updated', {
        alert_id: parseInt(id), workflow_status, timestamp: new Date().toISOString(),
      });
      if (workflow_status === 'Resolved') {
        global.io.to('emergency:admin').emit('emergency:resolved', {
          alert_id: parseInt(id), timestamp: new Date().toISOString(),
        });
      }
    }
    await logAction(req, `SOS_${workflow_status.toUpperCase().replace(' ', '_')}`, 'emergency_alert', id, { resolution_notes });
    res.json({ success: true, message: `Alert moved to ${workflow_status}` });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/emergency-alerts/:id/resolve (legacy) ────────────────────
router.put('/emergency-alerts/:id/resolve', async (req, res) => {
  try {
    const { id } = req.params;
    const { resolution_notes } = req.body ?? {};
    await q(
      "UPDATE emergency_alerts SET status='Resolved', resolved_at=NOW(), workflow_status='Resolved', resolution_notes=? WHERE id=?",
      [resolution_notes ?? '', id]
    );
    if (global.io) {
      global.io.to('emergency:admin').emit('emergency:resolved', {
        alert_id: parseInt(id), timestamp: new Date().toISOString(),
      });
    }
    await logAction(req, 'SOS_RESOLVED', 'emergency_alert', id, {});
    res.json({ success: true, message: 'Alert resolved' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/emergency-map ─────────────────────────────────────────────
router.get('/emergency-map', async (req, res) => {
  try {
    const alerts = await q(`
      SELECT ea.id, ea.user_id, ea.trip_id, ea.trip_type,
             ea.latitude, ea.longitude, ea.message, ea.status, ea.created_at,
             u.full_name AS user_name, u.phone_number AS user_phone, gb.trip_name
      FROM emergency_alerts ea
      JOIN  users u ON u.user_id=ea.user_id
      LEFT JOIN group_bookings gb ON ea.trip_type='group' AND ea.trip_id=gb.group_booking_id
      WHERE ea.status='Active'
      ORDER BY ea.created_at DESC`);
    const enriched = await Promise.all(alerts.map(async (alert) => {
      if (alert.trip_type !== 'group' || !alert.trip_id) return { ...alert, group_members: [] };
      const members = await q(`
        SELECT u2.user_id, u2.full_name AS user_name,
               ulu.latitude, ulu.longitude, ulu.captured_at AS last_seen
        FROM group_booking_members gbm
        JOIN  users u2 ON u2.user_id=gbm.user_id
        LEFT JOIN user_location_updates ulu
               ON ulu.user_identifier=CONCAT('user_',u2.user_id)
              AND ulu.captured_at=(SELECT MAX(i.captured_at) FROM user_location_updates i WHERE i.user_identifier=CONCAT('user_',u2.user_id))
        WHERE gbm.group_booking_id=?`, [alert.trip_id]);
      return { ...alert, group_members: members };
    }));
    res.json({ success: true, alerts: enriched });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /api/admin/trips ─────────────────────────────────────────────────────
router.get('/trips', async (req, res) => {
  try {
    const trips = await q(`
      SELECT gb.group_booking_id, gb.trip_name, gb.status,
             gb.start_date, gb.end_date, gb.created_at, gb.max_members,
             u.full_name AS organizer, u.email AS organizer_email,
             COUNT(gbm.user_id) AS member_count,
             d.name AS destination_name
      FROM group_bookings gb
      JOIN  users u ON gb.created_by=u.user_id
      LEFT JOIN group_booking_members gbm ON gb.group_booking_id=gbm.group_booking_id
      LEFT JOIN destinations d ON gb.destination_id=d.destination_id
      GROUP BY gb.group_booking_id
      ORDER BY gb.created_at DESC LIMIT 200`);
    res.json({ success: true, trips });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/payments ──────────────────────────────────────────────────
router.get('/payments', async (req, res) => {
  try {
    const { status, search, refund_pending } = req.query;
    let sql = `
      SELECT p.id, p.user_id, p.booking_id, p.amount, p.currency, p.status,
             p.stripe_payment_intent_id, p.created_at, p.updated_at,
             p.refund_requested_at, p.refund_approved_at, p.refund_rejected_at,
             p.refund_admin_notes,
             u.full_name, u.email,
             d.name AS destination_name
      FROM payments p
      JOIN  users u ON p.user_id=u.user_id
      LEFT JOIN bookings b ON p.booking_id=b.booking_id
      LEFT JOIN destinations d ON b.destination_id=d.destination_id
      WHERE 1=1`;
    const params = [];
    if (status) { sql += ' AND p.status=?'; params.push(status); }
    if (refund_pending === 'true') {
      sql += ' AND p.refund_requested_at IS NOT NULL AND p.refund_approved_at IS NULL AND p.refund_rejected_at IS NULL';
    }
    if (search) {
      sql += ' AND (u.full_name LIKE ? OR u.email LIKE ?)';
      const s = `%${search}%`; params.push(s, s);
    }
    sql += ' ORDER BY p.refund_requested_at DESC, p.created_at DESC LIMIT 200';
    const payments = await q(sql, params);
    res.json({ success: true, payments });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/payments/:id/approve-refund ───────────────────────────────
router.put('/payments/:id/approve-refund', async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body ?? {};
    const payment = await q1('SELECT * FROM payments WHERE id=?', [id]);
    if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });

    let stripeRefundId = null;
    try {
      const stripe = process.env.STRIPE_SECRET_KEY ? require('stripe')(process.env.STRIPE_SECRET_KEY) : null;
      if (stripe && payment.stripe_payment_intent_id) {
        const refund = await stripe.refunds.create({ payment_intent: payment.stripe_payment_intent_id });
        stripeRefundId = refund.id;
      }
    } catch (_) {}

    await q("UPDATE payments SET status='refunded', refund_approved_at=NOW(), refund_admin_notes=? WHERE id=?", [notes ?? '', id]);
    if (payment.booking_id) {
      await q("UPDATE bookings SET status='Refunded' WHERE booking_id=?", [payment.booking_id]);
    }
    await logAction(req, 'REFUND_APPROVED', 'payment', id, { notes, stripeRefundId });
    res.json({ success: true, message: 'Refund approved and processed', stripe_refund_id: stripeRefundId });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── PUT /api/admin/payments/:id/reject-refund ───────────────────────────────
router.put('/payments/:id/reject-refund', async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body ?? {};
    await q("UPDATE payments SET refund_rejected_at=NOW(), refund_admin_notes=? WHERE id=?", [notes ?? '', id]);
    await logAction(req, 'REFUND_REJECTED', 'payment', id, { notes });
    res.json({ success: true, message: 'Refund rejected' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/analytics ─────────────────────────────────────────────────
router.get('/analytics', async (req, res) => {
  try {
    const [totals, recentUsers, bookingsByStatus, monthlyBookings, monthlyRevenue, monthlySos, popularDests] = await Promise.all([
      q1(`SELECT (SELECT COUNT(*) FROM users) AS total_users,
                 (SELECT COUNT(*) FROM bookings) AS total_bookings,
                 (SELECT COUNT(*) FROM group_bookings) AS total_group_bookings,
                 (SELECT COUNT(*) FROM emergency_alerts) AS total_sos,
                 (SELECT COALESCE(SUM(amount),0) FROM payments WHERE status='succeeded') AS total_revenue`),
      q(`SELECT DATE(created_at) AS d, COUNT(*) AS c FROM users WHERE created_at >= DATE_SUB(NOW(),INTERVAL 30 DAY) GROUP BY DATE(created_at) ORDER BY d`),
      q(`SELECT status, COUNT(*) AS c FROM bookings GROUP BY status`),
      q(`SELECT DATE_FORMAT(created_at,'%Y-%m') AS m, COUNT(*) AS c FROM bookings GROUP BY m ORDER BY m DESC LIMIT 12`),
      q(`SELECT DATE_FORMAT(created_at,'%Y-%m') AS m, COALESCE(SUM(amount),0) AS c FROM payments WHERE status='succeeded' GROUP BY m ORDER BY m DESC LIMIT 12`),
      q(`SELECT DATE_FORMAT(created_at,'%Y-%m') AS m, COUNT(*) AS c FROM emergency_alerts GROUP BY m ORDER BY m DESC LIMIT 12`),
      q(`SELECT d.name, d.city, COUNT(b.booking_id) AS c FROM destinations d LEFT JOIN bookings b ON b.destination_id=d.destination_id GROUP BY d.destination_id ORDER BY c DESC LIMIT 10`),
    ]);
    res.json({
      success: true,
      analytics: {
        totals,
        recentUsers,
        bookingsByStatus,
        monthlyBookings: [...monthlyBookings].reverse(),
        monthlyRevenue:  [...monthlyRevenue].reverse(),
        monthlySos:      [...monthlySos].reverse(),
        popularDestinations: popularDests,
      },
    });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/activity-logs ────────────────────────────────────────────
router.get('/activity-logs', async (req, res) => {
  try {
    const { action, limit = 100 } = req.query;
    let sql = 'SELECT * FROM admin_activity_logs WHERE 1=1';
    const params = [];
    if (action) { sql += ' AND action=?'; params.push(action); }
    sql += ' ORDER BY created_at DESC LIMIT ?';
    params.push(parseInt(limit));
    const logs = await q(sql, params);
    res.json({ success: true, logs });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── POST /api/admin/broadcast-notification ───────────────────────────────────
router.post('/broadcast-notification', requireRole('super_admin'), async (req, res) => {
  try {
    const { title, message, type = 'admin_broadcast' } = req.body ?? {};
    if (!title || !message) return res.status(400).json({ success: false, error: 'title and message required' });
    const result = await q(
      `INSERT INTO notifications (user_id, title, message, type)
       SELECT user_id, ?, ?, ? FROM users WHERE is_blocked=0 OR is_blocked IS NULL`,
      [title, message, type]
    );
    if (global.io) global.io.emit('notification:new', { title, message, type });
    await logAction(req, 'BROADCAST_SENT', 'system', null, { title, sentTo: result.affectedRows ?? 0 });
    res.json({ success: true, sent_to: result.affectedRows ?? 0, message: 'Broadcast sent' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/reports/users ────────────────────────────────────────────
router.get('/reports/users', async (req, res) => {
  try {
    const users = await q(`
      SELECT u.user_id, u.full_name, u.email, u.phone_number,
             u.is_blocked, u.suspended_at, u.created_at, u.last_login_at,
             COUNT(DISTINCT b.booking_id) AS bookings,
             COUNT(DISTINCT gbm.group_booking_id) AS group_trips,
             COALESCE(SUM(p.amount),0) AS total_spent
      FROM users u
      LEFT JOIN bookings b ON b.user_id=u.user_id
      LEFT JOIN group_booking_members gbm ON gbm.user_id=u.user_id
      LEFT JOIN payments p ON p.user_id=u.user_id AND p.status='succeeded'
      GROUP BY u.user_id ORDER BY u.created_at DESC`);
    res.json({ success: true, users });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/reports/revenue ──────────────────────────────────────────
router.get('/reports/revenue', async (req, res) => {
  try {
    const [summary, monthly, byDest] = await Promise.all([
      q1(`SELECT COALESCE(SUM(CASE WHEN status='succeeded' THEN amount END),0) AS total_revenue,
                 COALESCE(SUM(CASE WHEN status='refunded'  THEN amount END),0) AS total_refunded,
                 COUNT(CASE WHEN status='succeeded' THEN 1 END)                AS successful_payments,
                 COUNT(CASE WHEN status='failed'    THEN 1 END)                AS failed_payments
          FROM payments`),
      q(`SELECT DATE_FORMAT(created_at,'%Y-%m') AS month,
                COALESCE(SUM(CASE WHEN status='succeeded' THEN amount END),0) AS revenue,
                COUNT(*) AS transactions
         FROM payments GROUP BY month ORDER BY month DESC LIMIT 12`),
      q(`SELECT d.name AS destination, COUNT(b.booking_id) AS bookings,
                COALESCE(SUM(p.amount),0) AS revenue
         FROM destinations d
         LEFT JOIN bookings b ON b.destination_id=d.destination_id
         LEFT JOIN payments p ON p.booking_id=b.booking_id AND p.status='succeeded'
         GROUP BY d.destination_id ORDER BY revenue DESC LIMIT 10`),
    ]);
    res.json({ success: true, summary, monthly, byDestination: byDest });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── GET /api/admin/reports/sos ──────────────────────────────────────────────
router.get('/reports/sos', async (req, res) => {
  try {
    const alerts = await q(`
      SELECT ea.id, ea.status, ea.workflow_status, ea.latitude, ea.longitude,
             ea.message, ea.created_at, ea.resolved_at, ea.resolution_notes,
             u.full_name, u.email, u.phone_number, gb.trip_name
      FROM emergency_alerts ea
      JOIN  users u ON ea.user_id=u.user_id
      LEFT JOIN group_bookings gb ON ea.trip_type='group' AND ea.trip_id=gb.group_booking_id
      ORDER BY ea.created_at DESC`);
    res.json({ success: true, alerts });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── Legacy endpoints ─────────────────────────────────────────────────────────
router.get('/sos-alerts', async (req, res) => {
  try {
    const alerts = await q(`SELECT sa.*, u.full_name FROM sos_alerts sa JOIN users u ON sa.user_id=u.user_id ORDER BY sa.created_at DESC LIMIT 50`);
    res.json({ success: true, alerts });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/bookings/stats', async (req, res) => {
  try {
    const stats = await q1(`SELECT COUNT(*) AS total_bookings, SUM(status='Pending') AS pending, SUM(status='Active') AS active, SUM(status='Completed') AS completed, SUM(status='Cancelled') AS cancelled FROM bookings`);
    res.json({ success: true, stats: stats || {} });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.get('/group-bookings/stats', async (req, res) => {
  try {
    const stats = await q1(`
      SELECT COUNT(DISTINCT gb.group_booking_id) AS total_group_bookings,
             SUM(gb.status='Planning') AS planning, SUM(gb.status='Active') AS active,
             SUM(gb.status='Completed') AS completed,
             COUNT(DISTINCT gbm.user_id) AS total_members,
             COUNT(DISTINCT gts.session_id) AS active_tracking_sessions
      FROM group_bookings gb
      LEFT JOIN group_booking_members gbm ON gb.group_booking_id=gbm.group_booking_id
      LEFT JOIN group_tracking_sessions gts ON gb.group_booking_id=gts.group_booking_id AND gts.status='active'`);
    res.json({ success: true, stats: stats || {} });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ─── Tour Packages Management ─────────────────────────────────────────────────
const TourPackage = require('../models/tourPackage');

const _parsePkg = (row) => ({
  ...row,
  destinations: (() => { try { return typeof row.destinations === 'object' ? row.destinations : JSON.parse(row.destinations || '[]'); } catch(_) { return []; } })(),
  itinerary:    (() => { try { return typeof row.itinerary    === 'object' ? row.itinerary    : JSON.parse(row.itinerary    || '[]'); } catch(_) { return []; } })(),
  includes:     (() => { try { return typeof row.includes     === 'object' ? row.includes     : JSON.parse(row.includes     || '[]'); } catch(_) { return []; } })(),
});

// GET /api/admin/tours
router.get('/tours', async (req, res) => {
  try {
    const [rows] = await TourPackage.getAll();
    res.json({ success: true, packages: rows.map(_parsePkg) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/admin/tours
router.post('/tours', async (req, res) => {
  try {
    const data = { ...req.body, created_by_admin: req.user?.adminId || req.user?.userId };
    const [result] = await TourPackage.create(data);
    await logAction(req, 'create_tour_package', 'tour_package', result.insertId, { title: data.title });
    res.status(201).json({ success: true, package_id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/admin/tours/:id
router.put('/tours/:id', async (req, res) => {
  try {
    await TourPackage.update(req.params.id, req.body);
    await logAction(req, 'update_tour_package', 'tour_package', req.params.id, { title: req.body.title });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/admin/tours/:id
router.delete('/tours/:id', async (req, res) => {
  try {
    await TourPackage.deactivate(req.params.id);
    await logAction(req, 'delete_tour_package', 'tour_package', req.params.id, {});
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ─── Virtual Tour Admin Routes ────────────────────────────────────────────────

const vtCtrl = require('../controllers/virtualTourController');

router.get('/virtual-tours',                            vtCtrl.adminListTours);
router.post('/virtual-tours',                           vtCtrl.adminCreateTour);
router.put('/virtual-tours/:id',                        vtCtrl.adminUpdateTour);
router.delete('/virtual-tours/:id',                     vtCtrl.adminDeleteTour);

router.post('/virtual-tours/:tourId/scenes',            vtCtrl.adminAddScene);
router.put('/virtual-tours/scenes/:sceneId',            vtCtrl.adminUpdateScene);
router.delete('/virtual-tours/scenes/:sceneId',         vtCtrl.adminDeleteScene);

router.post('/virtual-tours/scenes/:sceneId/hotspots',  vtCtrl.adminAddHotspot);
router.put('/virtual-tours/hotspots/:hotspotId',        vtCtrl.adminUpdateHotspot);
router.delete('/virtual-tours/hotspots/:hotspotId',     vtCtrl.adminDeleteHotspot);

module.exports = router;
