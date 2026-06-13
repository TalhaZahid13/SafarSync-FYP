const db = require('../config/db');

const EmergencyAlert = {
  trigger: (userId, tripId, tripType, latitude, longitude, message, callback) => {
    const query = `
      INSERT INTO emergency_alerts
        (user_id, trip_id, trip_type, latitude, longitude, message, status)
      VALUES (?, ?, ?, ?, ?, ?, 'Active')
    `;
    db.query(
      query,
      [userId, tripId || null, tripType || null, latitude, longitude, message || null],
      callback
    );
  },

  updateStatus: (id, userId, status, callback) => {
    const resolvedAt = status === 'Resolved' ? new Date() : null;
    const query = `
      UPDATE emergency_alerts
      SET status = ?, resolved_at = ?
      WHERE id = ? AND user_id = ?
    `;
    db.query(query, [status, resolvedAt, id, userId], callback);
  },

  getActiveByUser: (userId, callback) => {
    const query = `
      SELECT ea.*, u.full_name, u.email,
             gb.trip_name
      FROM emergency_alerts ea
      JOIN users u ON ea.user_id = u.user_id
      LEFT JOIN group_bookings gb
        ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      WHERE ea.user_id = ? AND ea.status = 'Active'
      ORDER BY ea.created_at DESC
      LIMIT 1
    `;
    db.query(query, [userId], (err, results) => {
      if (err) return callback(err);
      callback(null, results[0] || null);
    });
  },

  getByUser: (userId, limit, callback) => {
    const query = `
      SELECT ea.*, gb.trip_name
      FROM emergency_alerts ea
      LEFT JOIN group_bookings gb
        ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      WHERE ea.user_id = ?
      ORDER BY ea.created_at DESC
      LIMIT ?
    `;
    db.query(query, [userId, limit], callback);
  },

  getById: (id, callback) => {
    const query = `
      SELECT ea.*, u.full_name, u.email, gb.trip_name
      FROM emergency_alerts ea
      JOIN users u ON ea.user_id = u.user_id
      LEFT JOIN group_bookings gb
        ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      WHERE ea.id = ?
    `;
    db.query(query, [id], (err, results) => {
      if (err) return callback(err);
      callback(null, results[0] || null);
    });
  },

  getAll: (limit, callback) => {
    const query = `
      SELECT ea.*, u.full_name, u.email, gb.trip_name
      FROM emergency_alerts ea
      JOIN users u ON ea.user_id = u.user_id
      LEFT JOIN group_bookings gb
        ON ea.trip_type = 'group' AND ea.trip_id = gb.group_booking_id
      ORDER BY ea.created_at DESC
      LIMIT ?
    `;
    db.query(query, [limit], callback);
  },

  countActive: (callback) => {
    db.query(
      'SELECT COUNT(*) as count FROM emergency_alerts WHERE status = "Active"',
      callback
    );
  },
};

module.exports = EmergencyAlert;
