const db = require('../config/db');

const Booking = {
  create: (userId, destinationId, bookingDate, duration, notes, callback) => {
    const query = `
      INSERT INTO bookings (user_id, destination_id, booking_date, estimated_duration_days, notes, status)
      VALUES (?, ?, ?, ?, ?, 'Planned')
    `;
    db.query(query, [userId, destinationId, bookingDate, duration, notes], callback);
  },

  getById: (bookingId, callback) => {
    const query = `
      SELECT b.*, d.name as destination_name, d.latitude, d.longitude,
             u.full_name, u.email
      FROM bookings b
      JOIN destinations d ON b.destination_id = d.destination_id
      JOIN users u ON b.user_id = u.user_id
      WHERE b.booking_id = ?
    `;
    db.query(query, [bookingId], (err, results) => {
      callback(err, results && results.length > 0 ? results[0] : null);
    });
  },

  getUserBookings: (userId, callback) => {
    const query = `
      SELECT b.*, d.name as destination_name, d.image_url, d.latitude, d.longitude
      FROM bookings b
      JOIN destinations d ON b.destination_id = d.destination_id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    `;
    db.query(query, [userId], callback);
  },

  updateStatus: (bookingId, status, callback) => {
    const query = `
      UPDATE bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE booking_id = ?
    `;
    db.query(query, [status, bookingId], callback);
  },

  getAll: (callback) => {
    const query = `
      SELECT COUNT(*) as total FROM bookings
    `;
    db.query(query, callback);
  }
};

module.exports = Booking;
