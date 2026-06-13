const db = require('../config/db');

const Invitation = {
  create: (groupBookingId, senderId, receiverId, callback) => {
    const query = `
      INSERT INTO group_invitations (group_booking_id, sender_id, receiver_id, status)
      VALUES (?, ?, ?, 'Pending')
    `;
    db.query(query, [groupBookingId, senderId, receiverId], callback);
  },

  findByReceiver: (receiverId, callback) => {
    const query = `
      SELECT gi.*, gb.trip_name, gb.description, gb.start_date, gb.status as trip_status,
             u.full_name as sender_name, u.email as sender_email,
             u.profile_picture_url as sender_avatar
      FROM group_invitations gi
      JOIN group_bookings gb ON gi.group_booking_id = gb.group_booking_id
      JOIN users u ON gi.sender_id = u.user_id
      WHERE gi.receiver_id = ?
      ORDER BY gi.created_at DESC
    `;
    db.query(query, [receiverId], callback);
  },

  findBySender: (senderId, callback) => {
    const query = `
      SELECT gi.*, gb.trip_name,
             u.full_name as receiver_name, u.email as receiver_email
      FROM group_invitations gi
      JOIN group_bookings gb ON gi.group_booking_id = gb.group_booking_id
      JOIN users u ON gi.receiver_id = u.user_id
      WHERE gi.sender_id = ?
      ORDER BY gi.created_at DESC
    `;
    db.query(query, [senderId], callback);
  },

  findById: (id, callback) => {
    const query = `
      SELECT gi.*, gb.trip_name, gb.created_by,
             sender.full_name as sender_name, sender.email as sender_email,
             receiver.full_name as receiver_name, receiver.email as receiver_email
      FROM group_invitations gi
      JOIN group_bookings gb ON gi.group_booking_id = gb.group_booking_id
      JOIN users sender ON gi.sender_id = sender.user_id
      JOIN users receiver ON gi.receiver_id = receiver.user_id
      WHERE gi.id = ?
    `;
    db.query(query, [id], (err, results) => {
      callback(err, results && results.length > 0 ? results[0] : null);
    });
  },

  updateStatus: (id, receiverId, status, callback) => {
    const query = `
      UPDATE group_invitations
      SET status = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ? AND receiver_id = ?
    `;
    db.query(query, [status, id, receiverId], callback);
  },

  getUserByEmail: (email, callback) => {
    const query = 'SELECT user_id, full_name, email FROM users WHERE email = ? AND is_active = TRUE LIMIT 1';
    db.query(query, [email], (err, results) => {
      callback(err, results && results.length > 0 ? results[0] : null);
    });
  },

  checkAlreadyMember: (groupBookingId, userId, callback) => {
    const query = `
      SELECT id FROM group_booking_members WHERE group_booking_id = ? AND user_id = ?
    `;
    db.query(query, [groupBookingId, userId], (err, results) => {
      callback(err, results && results.length > 0);
    });
  },

  getPendingCount: (receiverId, callback) => {
    const query = `
      SELECT COUNT(*) as count FROM group_invitations
      WHERE receiver_id = ? AND status = 'Pending'
    `;
    db.query(query, [receiverId], (err, results) => {
      callback(err, results ? results[0].count : 0);
    });
  },
};

module.exports = Invitation;
