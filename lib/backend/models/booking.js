const db = require('../config/db');

const Booking = {
  create: (userId, destinationId, bookingDate, travelDate, numTravelers, duration, notes, totalAmount) => {
    const query = `
      INSERT INTO bookings
        (user_id, destination_id, booking_date, travel_date, num_travelers,
         estimated_duration_days, notes, total_amount, status, payment_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending', 'Unpaid')
    `;
    return db.promise().query(query, [
      userId, destinationId, bookingDate, travelDate || null,
      numTravelers || 1, duration || 1, notes || '', totalAmount || 0
    ]);
  },

  getById: (bookingId) => {
    const query = `
      SELECT b.*, d.name AS destination_name, d.image_url, d.latitude, d.longitude,
             d.average_cost, u.full_name, u.email
      FROM bookings b
      JOIN destinations d ON b.destination_id = d.destination_id
      JOIN users u ON b.user_id = u.user_id
      WHERE b.booking_id = ?
    `;
    return db.promise().query(query, [bookingId]).then(([rows]) => rows[0] || null);
  },

  getUserBookings: (userId) => {
    const query = `
      SELECT b.*, d.name AS destination_name, d.image_url, d.latitude, d.longitude
      FROM bookings b
      JOIN destinations d ON b.destination_id = d.destination_id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    `;
    return db.promise().query(query, [userId]).then(([rows]) => rows);
  },

  updateStatus: (bookingId, status) => {
    return db.promise().query(
      'UPDATE bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE booking_id = ?',
      [status, bookingId]
    );
  },

  markPaymentPaid: (bookingId, paymentIntentId) => {
    return db.promise().query(
      `UPDATE bookings
       SET payment_status = 'Paid', payment_intent_id = ?,
           status = 'Confirmed', updated_at = CURRENT_TIMESTAMP
       WHERE booking_id = ?`,
      [paymentIntentId, bookingId]
    );
  },

  markAwaitingPayment: (bookingId) => {
    return db.promise().query(
      `UPDATE bookings SET status = 'Awaiting Payment', updated_at = CURRENT_TIMESTAMP
       WHERE booking_id = ? AND status = 'Pending'`,
      [bookingId]
    );
  },

  cancelBooking: (bookingId, userId, reason) => {
    return db.promise().query(
      `UPDATE bookings
       SET status = 'Cancelled', cancelled_at = CURRENT_TIMESTAMP,
           cancellation_reason = ?, updated_at = CURRENT_TIMESTAMP
       WHERE booking_id = ? AND user_id = ?
         AND status NOT IN ('Completed', 'Cancelled', 'Refunded')`,
      [reason || '', bookingId, userId]
    );
  },

  markRefunded: (bookingId) => {
    return db.promise().query(
      `UPDATE bookings
       SET status = 'Refunded', payment_status = 'Refunded',
           updated_at = CURRENT_TIMESTAMP
       WHERE booking_id = ?`,
      [bookingId]
    );
  },

  getAdminStats: () => {
    const query = `
      SELECT
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN status = 'Awaiting Payment' THEN 1 ELSE 0 END) AS awaiting_payment,
        SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed,
        SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active,
        SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN payment_status = 'Paid' THEN total_amount ELSE 0 END) AS total_revenue
      FROM bookings
    `;
    return db.promise().query(query).then(([rows]) => rows[0] || {});
  }
};

module.exports = Booking;
