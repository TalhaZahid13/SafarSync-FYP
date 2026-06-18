const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const { requireRole } = require('../middleware/rbacMiddleware');

// All admin routes require authentication + admin role
router.use(authenticate, adminOnly);

// ─── Helper ───────────────────────────────────────────────────────────────────
const count = (sql, params = []) =>
  new Promise((resolve) =>
    db.query(sql, params, (err, rows) =>
      resolve(err ? 0 : (rows[0]?.count ?? rows[0]?.cnt ?? 0))
    )
  );

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────────
router.get('/dashboard', (req, res) => {
  Promise.all([
    count('SELECT COUNT(*) AS count FROM users'),
    count('SELECT COUNT(*) AS count FROM group_bookings'),
    count("SELECT COUNT(*) AS count FROM group_bookings WHERE status = 'Active'"),
    count(`SELECT
             (SELECT COUNT(*) FROM sos_alerts WHERE status = 'Active') +
             (SELECT COUNT(*) FROM emergency_alerts WHERE status = 'Active') AS count`),
    count('SELECT COUNT(*) AS count FROM bookings'),
    count("SELECT COUNT(*) AS count FROM group_tracking_sessions WHERE status = 'active'"),
    count('SELECT COUNT(*) AS count FROM ai_chat_history'),
    count('SELECT COUNT(*) AS count FROM group_chat_messages'),
  ])
    .then(([totalUsers, totalGroupBookings, activeTrips, activeSos,
            totalBookings, activeSessions, aiChats, chatMessages]) => {
      res.json({
        success: true,
        stats: {
          total_users:              totalUsers,
          total_group_bookings:     totalGroupBookings,
          active_trips:             activeTrips,
          active_sos:               activeSos,
          total_bookings:           totalBookings,
          active_tracking_sessions: activeSessions,
          ai_chats:                 aiChats,
          chat_messages:            chatMessages,
          system_health:            '98%',
        },
      });
    })
    .catch((err) => res.status(500).json({ success: false, error: err.message }));
});

// ─── GET /api/admin/users ─────────────────────────────────────────────────────
router.get('/users', (req, res) => {
  const search = req.query.search ? `%${req.query.search}%` : null;
  let query = `
    SELECT
      u.user_id, u.full_name, u.email, u.phone_number, u.profile_picture_url,
      u.is_admin, u.is_blocked, u.created_at,
      (SELECT COUNT(*) FROM bookings       WHERE user_id = u.user_id) AS single_bookings,
      (SELECT COUNT(*) FROM group_booking_members WHERE user_id = u.user_id) AS group_trips
    FROM users u
  `;
  const params = [];
  if (search) {
    query += ' WHERE u.full_name LIKE ? OR u.email LIKE ?';
    params.push(search, search);
  }
  query += ' ORDER BY u.created_at DESC LIMIT 100';

  db.query(query, params, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, users: rows || [] });
  });
});

// ─── PUT /api/admin/users/:id/block ──────────────────────────────────────────
router.put('/users/:id/block', (req, res) => {
  const { id } = req.params;
  db.query(
    'UPDATE users SET is_blocked = TRUE WHERE user_id = ?',
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
      res.json({ success: true, message: 'User blocked' });
    }
  );
});

// ─── PUT /api/admin/users/:id/unblock ────────────────────────────────────────
router.put('/users/:id/unblock', (req, res) => {
  const { id } = req.params;
  db.query(
    'UPDATE users SET is_blocked = FALSE WHERE user_id = ?',
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
      res.json({ success: true, message: 'User unblocked' });
    }
  );
});

// ─── DELETE /api/admin/users/:id ─────────────────────────────────────────────
router.delete('/users/:id', requireRole('super_admin'), (req, res) => {
  const { id } = req.params;
  // Prevent self-deletion
  if (parseInt(id) === req.user.userId) {
    return res.status(400).json({ success: false, message: 'Cannot delete yourself' });
  }
  db.query('DELETE FROM users WHERE user_id = ?', [id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User deleted' });
  });
});

// ─── PUT /api/admin/users/:id/make-admin ─────────────────────────────────────
router.put('/users/:id/make-admin', requireRole('super_admin'), (req, res) => {
  const { id } = req.params;
  db.query(
    'UPDATE users SET is_admin = TRUE WHERE user_id = ?',
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
      res.json({ success: true, message: 'User promoted to admin' });
    }
  );
});

// ─── GET /api/admin/trips ─────────────────────────────────────────────────────
router.get('/trips', (req, res) => {
  const query = `
    SELECT
      gb.group_booking_id, gb.trip_name, gb.status,
      gb.start_date, gb.end_date, gb.created_at,
      u.full_name AS organizer, u.email AS organizer_email,
      COUNT(gbm.user_id) AS member_count
    FROM group_bookings gb
    JOIN  users u ON gb.created_by = u.user_id
    LEFT JOIN group_booking_members gbm ON gb.group_booking_id = gbm.group_booking_id
    GROUP BY gb.group_booking_id
    ORDER BY gb.created_at DESC
    LIMIT 100
  `;
  db.query(query, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, trips: rows || [] });
  });
});

// ─── GET /api/admin/bookings ──────────────────────────────────────────────────
router.get('/bookings', (req, res) => {
  const query = `
    SELECT b.booking_id, b.status, b.booking_date, b.estimated_duration_days, b.created_at,
           u.full_name, u.email,
           d.name AS destination_name, d.city
    FROM bookings b
    JOIN users u ON b.user_id = u.user_id
    JOIN destinations d ON b.destination_id = d.destination_id
    ORDER BY b.created_at DESC
    LIMIT 100
  `;
  db.query(query, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, bookings: rows || [] });
  });
});

// ─── GET /api/admin/emergency-alerts ─────────────────────────────────────────
router.get('/emergency-alerts', (req, res) => {
  const query = `
    SELECT ea.id, ea.status, ea.latitude, ea.longitude, ea.message,
           ea.trip_id, ea.trip_type, ea.created_at, ea.resolved_at,
           u.user_id, u.full_name, u.email, u.phone_number,
           gb.trip_name
    FROM emergency_alerts ea
    JOIN  users u ON ea.user_id = u.user_id
    LEFT JOIN group_bookings gb ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
    ORDER BY ea.created_at DESC
    LIMIT 100
  `;
  db.query(query, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, alerts: rows || [] });
  });
});

// ─── PUT /api/admin/emergency-alerts/:id/resolve ─────────────────────────────
router.put('/emergency-alerts/:id/resolve', (req, res) => {
  const { id } = req.params;
  db.query(
    "UPDATE emergency_alerts SET status = 'Resolved', resolved_at = NOW() WHERE id = ?",
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Alert not found' });
      if (global.io) {
        global.io.to('emergency:admin').emit('emergency:resolved', {
          alert_id: parseInt(id),
          timestamp: new Date().toISOString(),
        });
      }
      res.json({ success: true, message: 'Alert resolved' });
    }
  );
});

// ─── GET /api/admin/emergency-map ─────────────────────────────────────────────
router.get('/emergency-map', async (req, res) => {
  try {
    const alertQuery = `
      SELECT ea.id, ea.user_id, ea.trip_id, ea.trip_type,
             ea.latitude, ea.longitude, ea.message, ea.status, ea.created_at,
             u.full_name AS user_name, u.phone_number AS user_phone, gb.trip_name
      FROM emergency_alerts ea
      JOIN  users u ON u.user_id = ea.user_id
      LEFT JOIN group_bookings gb ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      WHERE ea.status = 'Active'
      ORDER BY ea.created_at DESC
    `;
    const alerts = await new Promise((resolve) =>
      db.query(alertQuery, [], (err, rows) => resolve(err ? [] : (rows || [])))
    );

    const enriched = await Promise.all(alerts.map(async (alert) => {
      if (alert.trip_type !== 'group' || !alert.trip_id) return { ...alert, group_members: [] };
      const memberQuery = `
        SELECT u2.user_id, u2.full_name AS user_name,
               ulu.latitude, ulu.longitude, ulu.captured_at AS last_seen
        FROM group_booking_members gbm
        JOIN  users u2 ON u2.user_id = gbm.user_id
        LEFT JOIN user_location_updates ulu
               ON ulu.user_identifier = CONCAT('user_', u2.user_id)
              AND ulu.captured_at = (
                SELECT MAX(i.captured_at) FROM user_location_updates i
                WHERE i.user_identifier = CONCAT('user_', u2.user_id)
              )
        WHERE gbm.group_booking_id = ?
      `;
      const members = await new Promise((resolve) =>
        db.query(memberQuery, [alert.trip_id], (err2, rows2) => resolve(err2 ? [] : (rows2 || [])))
      );
      return { ...alert, group_members: members };
    }));

    res.json({ success: true, alerts: enriched });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── GET /api/admin/analytics ─────────────────────────────────────────────────
router.get('/analytics', async (req, res) => {
  try {
    const [
      totalUsers, totalBookings, totalGroupBookings,
      activeTrips, totalSOS, totalAiChats,
      recentUsers, bookingsByStatus, monthlyBookings,
    ] = await Promise.all([
      new Promise((r) => db.query('SELECT COUNT(*) AS c FROM users', (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query('SELECT COUNT(*) AS c FROM bookings', (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query('SELECT COUNT(*) AS c FROM group_bookings', (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query("SELECT COUNT(*) AS c FROM group_bookings WHERE status='Active'", (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query('SELECT COUNT(*) AS c FROM emergency_alerts', (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query('SELECT COUNT(*) AS c FROM ai_chat_history', (e, rows) => r(e ? 0 : rows[0].c))),
      new Promise((r) => db.query('SELECT DATE(created_at) AS d, COUNT(*) AS c FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) GROUP BY DATE(created_at) ORDER BY d', (e, rows) => r(e ? [] : (rows || [])))),
      new Promise((r) => db.query("SELECT status, COUNT(*) AS c FROM bookings GROUP BY status", (e, rows) => r(e ? [] : (rows || [])))),
      new Promise((r) => db.query("SELECT DATE_FORMAT(created_at, '%Y-%m') AS m, COUNT(*) AS c FROM bookings GROUP BY m ORDER BY m DESC LIMIT 12", (e, rows) => r(e ? [] : (rows || [])))),
    ]);

    res.json({
      success: true,
      analytics: {
        totals: { totalUsers, totalBookings, totalGroupBookings, activeTrips, totalSOS, totalAiChats },
        recentUsers,
        bookingsByStatus,
        monthlyBookings,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /api/admin/broadcast-notification ───────────────────────────────────
router.post('/broadcast-notification', requireRole('super_admin'), (req, res) => {
  const { title, message, type = 'admin_broadcast' } = req.body;
  if (!title || !message) {
    return res.status(400).json({ success: false, error: 'title and message required' });
  }

  // Insert notification for all users
  const insertQuery = `
    INSERT INTO notifications (user_id, title, message, type)
    SELECT user_id, ?, ?, ? FROM users WHERE is_blocked = FALSE OR is_blocked IS NULL
  `;
  db.query(insertQuery, [title, message, type], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });

    // Socket.io broadcast to all connected clients
    if (global.io) {
      global.io.emit('notification:new', { title, message, type });
    }

    res.json({ success: true, sent_to: result.affectedRows, message: 'Broadcast sent' });
  });
});

// ─── Legacy compatibility endpoints (no auth change) ─────────────────────────
router.get('/sos-alerts', (req, res) => {
  db.query(
    `SELECT sa.*, u.full_name FROM sos_alerts sa JOIN users u ON sa.user_id = u.user_id ORDER BY sa.created_at DESC LIMIT 50`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, alerts: rows || [] });
    }
  );
});

router.get('/bookings/stats', (req, res) => {
  db.query(
    `SELECT COUNT(*) AS total_bookings,
            SUM(status='Planned') AS planned, SUM(status='Active') AS active, SUM(status='Completed') AS completed
     FROM bookings`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, stats: rows[0] || {} });
    }
  );
});

router.get('/group-bookings/stats', (req, res) => {
  db.query(
    `SELECT COUNT(DISTINCT gb.group_booking_id) AS total_group_bookings,
       SUM(gb.status='Planning') AS planning, SUM(gb.status='Active') AS active,
       SUM(gb.status='Completed') AS completed,
       COUNT(DISTINCT gbm.user_id) AS total_members,
       COUNT(DISTINCT gts.session_id) AS active_tracking_sessions
     FROM group_bookings gb
     LEFT JOIN group_booking_members gbm ON gb.group_booking_id = gbm.group_booking_id
     LEFT JOIN group_tracking_sessions gts ON gb.group_booking_id = gts.group_booking_id AND gts.status = 'active'`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, stats: rows[0] || {} });
    }
  );
});

module.exports = router;
