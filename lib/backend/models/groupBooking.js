const db = require('../config/db');

const GroupBooking = {
  create: (tripName, createdBy, description, startDate, endDate, callback) => {
    const query = `
      INSERT INTO group_bookings (trip_name, created_by, description, start_date, end_date, status)
      VALUES (?, ?, ?, ?, ?, 'Planning')
    `;
    db.query(query, [tripName, createdBy, description, startDate, endDate], (err, result) => {
      if (err) return callback(err);

      // Add creator as member
      const addMemberQuery = `
        INSERT INTO group_booking_members (group_booking_id, user_id)
        VALUES (?, ?)
      `;
      db.query(addMemberQuery, [result.insertId, createdBy], (err) => {
        callback(err, result);
      });
    });
  },

  getById: (groupBookingId, callback) => {
    const query = `
      SELECT gb.*, u.full_name as created_by_name, u.profile_picture_url as creator_profile
      FROM group_bookings gb
      JOIN users u ON gb.created_by = u.user_id
      WHERE gb.group_booking_id = ?
    `;
    db.query(query, [groupBookingId], (err, results) => {
      if (err) return callback(err);
      if (!results || results.length === 0) return callback(null, null);

      const groupBooking = results[0];

      // Get members
      const membersQuery = `
        SELECT u.user_id, u.full_name, u.email, u.profile_picture_url, gbm.joined_at
        FROM group_booking_members gbm
        JOIN users u ON gbm.user_id = u.user_id
        WHERE gbm.group_booking_id = ?
        ORDER BY gbm.joined_at
      `;
      db.query(membersQuery, [groupBookingId], (err, members) => {
        if (err) return callback(err);
        groupBooking.members = members || [];
        groupBooking.member_count = members ? members.length : 0;
        callback(null, groupBooking);
      });
    });
  },

  getUserGroupBookings: (userId, callback) => {
    const query = `
      SELECT gb.*, u.full_name as created_by_name
      FROM group_bookings gb
      JOIN users u ON gb.created_by = u.user_id
      WHERE gb.created_by = ? OR gb.group_booking_id IN (
        SELECT group_booking_id FROM group_booking_members WHERE user_id = ?
      )
      ORDER BY gb.created_at DESC
    `;
    db.query(query, [userId, userId], (err, results) => {
      if (err) return callback(err);

      if (!results || results.length === 0) return callback(null, []);

      let processed = 0;
      results.forEach((gb, index) => {
        const memberQuery = `
          SELECT COUNT(*) as count FROM group_booking_members WHERE group_booking_id = ?
        `;
        db.query(memberQuery, [gb.group_booking_id], (err, memberResult) => {
          if (!err && memberResult) {
            results[index].member_count = memberResult[0].count;
          }
          processed++;
          if (processed === results.length) {
            callback(null, results);
          }
        });
      });
    });
  },

  addMember: (groupBookingId, userId, callback) => {
    const query = `
      INSERT INTO group_booking_members (group_booking_id, user_id)
      VALUES (?, ?)
    `;
    db.query(query, [groupBookingId, userId], callback);
  },

  getMembers: (groupBookingId, callback) => {
    const query = `
      SELECT u.user_id, u.full_name, u.email, u.profile_picture_url, gbm.joined_at
      FROM group_booking_members gbm
      JOIN users u ON gbm.user_id = u.user_id
      WHERE gbm.group_booking_id = ?
      ORDER BY gbm.joined_at
    `;
    db.query(query, [groupBookingId], callback);
  },

  updateStatus: (groupBookingId, status, callback) => {
    const query = `
      UPDATE group_bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE group_booking_id = ?
    `;
    db.query(query, [status, groupBookingId], callback);
  },

  getMemberLocations: (groupBookingId, callback) => {
    const query = `
      SELECT u.user_id, u.full_name, u.profile_picture_url,
             ulu.latitude, ulu.longitude, ulu.city, ulu.country,
             ulu.captured_at, ulu.accuracy_meters
      FROM group_booking_members gbm
      JOIN users u ON gbm.user_id = u.user_id
      LEFT JOIN user_location_updates ulu ON ulu.user_identifier = CONCAT('user_', u.user_id)
        AND ulu.captured_at = (
          SELECT MAX(inner_ulu.captured_at)
          FROM user_location_updates inner_ulu
          WHERE inner_ulu.user_identifier = CONCAT('user_', u.user_id)
        )
      WHERE gbm.group_booking_id = ?
      ORDER BY u.full_name
    `;
    db.query(query, [groupBookingId], callback);
  }
};

module.exports = GroupBooking;
