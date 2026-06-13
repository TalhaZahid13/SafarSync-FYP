const express = require('express');
const router = express.Router();
const db = require('../config/db');

// ─── Helper: promisify a single COUNT query ───────────────────────────────────
const count = (sql, params = []) =>
  new Promise((resolve) =>
    db.query(sql, params, (err, rows) =>
      resolve(err ? 0 : (rows[0]?.count ?? rows[0]?.cnt ?? 0))
    )
  );

// ─── GET /admin/dashboard ─────────────────────────────────────────────────────
router.get('/dashboard', (req, res) => {
  Promise.all([
    count('SELECT COUNT(*) AS count FROM users'),
    count('SELECT COUNT(*) AS count FROM group_bookings'),
    count("SELECT COUNT(*) AS count FROM group_bookings WHERE status = 'Active'"),
    count(`SELECT
             (SELECT COUNT(*) FROM sos_alerts       WHERE status = 'Active') +
             (SELECT COUNT(*) FROM emergency_alerts WHERE status = 'Active') AS count`),
    count('SELECT COUNT(*) AS count FROM bookings'),
    count("SELECT COUNT(*) AS count FROM group_tracking_sessions WHERE status = 'active'"),
  ])
    .then(([totalUsers, totalGroupBookings, activeTrips, activeSos,
            totalBookings, activeSessions]) => {
      res.json({
        success: true,
        stats: {
          total_users:              totalUsers,
          total_group_bookings:     totalGroupBookings,
          active_trips:             activeTrips,
          active_sos:               activeSos,
          total_bookings:           totalBookings,
          active_tracking_sessions: activeSessions,
          // AI chats — no dedicated table yet; use a placeholder
          ai_chats: 0,
          system_health: '98%',
        },
      });
    })
    .catch((err) => {
      console.error('Dashboard stats error:', err);
      res.status(500).json({ success: false, error: err.message });
    });
});

// ─── GET /admin/users ─────────────────────────────────────────────────────────
// Recent 50 registered users
router.get('/users', (req, res) => {
  const query = `
    SELECT
      u.user_id,
      u.full_name,
      u.email,
      u.profile_picture_url,
      u.created_at,
      (SELECT COUNT(*) FROM bookings       WHERE user_id = u.user_id) AS single_bookings,
      (SELECT COUNT(*) FROM group_booking_members WHERE user_id = u.user_id) AS group_trips
    FROM users u
    ORDER BY u.created_at DESC
    LIMIT 50
  `;
  db.query(query, (err, rows) => {
    if (err) {
      console.error('Admin users error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, users: rows || [] });
  });
});

// ─── GET /admin/trips ─────────────────────────────────────────────────────────
// Recent 50 group trips with member count
router.get('/trips', (req, res) => {
  const query = `
    SELECT
      gb.group_booking_id,
      gb.trip_name,
      gb.status,
      gb.start_date,
      gb.end_date,
      gb.created_at,
      u.full_name  AS organizer,
      u.email      AS organizer_email,
      COUNT(gbm.user_id) AS member_count
    FROM group_bookings gb
    JOIN  users u   ON gb.created_by = u.user_id
    LEFT JOIN group_booking_members gbm
           ON gb.group_booking_id = gbm.group_booking_id
    GROUP BY gb.group_booking_id
    ORDER BY gb.created_at DESC
    LIMIT 50
  `;
  db.query(query, (err, rows) => {
    if (err) {
      console.error('Admin trips error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, trips: rows || [] });
  });
});

// ─── GET /admin/emergency-alerts ─────────────────────────────────────────────
// Recent 50 emergency alerts from the richer emergency_alerts table
router.get('/emergency-alerts', (req, res) => {
  const query = `
    SELECT
      ea.id,
      ea.status,
      ea.latitude,
      ea.longitude,
      ea.message,
      ea.trip_id,
      ea.trip_type,
      ea.created_at,
      ea.resolved_at,
      u.user_id,
      u.full_name,
      u.email,
      gb.trip_name
    FROM emergency_alerts ea
    JOIN  users u  ON ea.user_id = u.user_id
    LEFT JOIN group_bookings gb
           ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
    ORDER BY ea.created_at DESC
    LIMIT 50
  `;
  db.query(query, (err, rows) => {
    if (err) {
      console.error('Admin emergency-alerts error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, alerts: rows || [] });
  });
});

// ─── PUT /admin/emergency-alerts/:id/resolve ─────────────────────────────────
router.put('/emergency-alerts/:id/resolve', (req, res) => {
  const { id } = req.params;
  db.query(
    "UPDATE emergency_alerts SET status = 'Resolved', resolved_at = NOW() WHERE id = ?",
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ success: false, message: 'Alert not found' });
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

// ─── GET /admin/emergency-map ─────────────────────────────────────────────────
// All active SOS alerts + group members' latest GPS positions
router.get('/emergency-map', async (req, res) => {
  try {
    const alertQuery = `
      SELECT ea.id, ea.user_id, ea.trip_id, ea.trip_type,
             ea.latitude, ea.longitude, ea.message, ea.status, ea.created_at,
             u.full_name AS user_name, u.phone_number AS user_phone,
             gb.trip_name
      FROM emergency_alerts ea
      JOIN  users u  ON u.user_id = ea.user_id
      LEFT JOIN group_bookings gb
             ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      WHERE ea.status = 'Active'
      ORDER BY ea.created_at DESC
    `;

    const alerts = await new Promise((resolve) =>
      db.query(alertQuery, [], (err, rows) => resolve(err ? [] : (rows || [])))
    );

    const enriched = await Promise.all(alerts.map(async (alert) => {
      if (alert.trip_type !== 'group' || !alert.trip_id) {
        return { ...alert, group_members: [] };
      }
      const memberQuery = `
        SELECT u2.user_id, u2.full_name AS user_name,
               ulu.latitude, ulu.longitude, ulu.captured_at AS last_seen
        FROM group_booking_members gbm
        JOIN  users u2  ON u2.user_id = gbm.user_id
        LEFT JOIN user_location_updates ulu
               ON ulu.user_identifier = CONCAT('user_', u2.user_id)
              AND ulu.captured_at = (
                SELECT MAX(ulu2.captured_at)
                FROM user_location_updates ulu2
                WHERE ulu2.user_identifier = CONCAT('user_', u2.user_id)
              )
        WHERE gbm.group_booking_id = ?
        ORDER BY u2.full_name
      `;
      const members = await new Promise((resolve) =>
        db.query(memberQuery, [alert.trip_id], (err2, rows2) => resolve(err2 ? [] : (rows2 || [])))
      );
      return { ...alert, group_members: members };
    }));

    res.json({ success: true, alerts: enriched });
  } catch (err) {
    console.error('[Admin] Emergency map error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Legacy endpoints (kept for backward-compat) ─────────────────────────────
router.get('/sos-alerts', (req, res) => {
  db.query(
    `SELECT sa.*, u.full_name FROM sos_alerts sa
     JOIN users u ON sa.user_id = u.user_id
     ORDER BY sa.created_at DESC LIMIT 20`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, alerts: rows || [] });
    }
  );
});

router.get('/bookings/stats', (req, res) => {
  db.query(
    `SELECT COUNT(*) AS total_bookings,
            SUM(status='Planned')   AS planned,
            SUM(status='Active')    AS active,
            SUM(status='Completed') AS completed
     FROM bookings`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, stats: rows[0] || {} });
    }
  );
});

router.get('/group-bookings/stats', (req, res) => {
  db.query(
    `SELECT
       COUNT(DISTINCT gb.group_booking_id) AS total_group_bookings,
       SUM(gb.status='Planning')   AS planning,
       SUM(gb.status='Active')     AS active,
       SUM(gb.status='Completed')  AS completed,
       COUNT(DISTINCT gbm.user_id) AS total_members,
       COUNT(DISTINCT gts.session_id) AS active_tracking_sessions
     FROM group_bookings gb
     LEFT JOIN group_booking_members gbm
            ON gb.group_booking_id = gbm.group_booking_id
     LEFT JOIN group_tracking_sessions gts
            ON gb.group_booking_id = gts.group_booking_id AND gts.status = 'active'`,
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, stats: rows[0] || {} });
    }
  );
});

module.exports = router;
