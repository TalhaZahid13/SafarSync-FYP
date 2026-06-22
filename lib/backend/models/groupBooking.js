const db = require('../config/db');

const GroupBooking = {
  create: async (tripName, createdBy, description, startDate, endDate, maxMembers, destinationId) => {
    const [result] = await db.promise().query(
      `INSERT INTO group_bookings
         (trip_name, created_by, description, start_date, end_date, max_members, destination_id, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'Planning')`,
      [tripName, createdBy, description || '', startDate || null, endDate || null,
       maxMembers || 20, destinationId || null]
    );
    await db.promise().query(
      `INSERT INTO group_booking_members (group_booking_id, user_id, role)
       VALUES (?, ?, 'organizer')`,
      [result.insertId, createdBy]
    );
    return result;
  },

  getById: async (groupBookingId) => {
    const [[gb]] = await db.promise().query(
      `SELECT gb.*, u.full_name AS created_by_name, u.profile_picture_url AS creator_profile,
              d.name AS destination_name
       FROM group_bookings gb
       JOIN users u ON gb.created_by = u.user_id
       LEFT JOIN destinations d ON gb.destination_id = d.destination_id
       WHERE gb.group_booking_id = ?`,
      [groupBookingId]
    );
    if (!gb) return null;

    const [members] = await db.promise().query(
      `SELECT u.user_id, u.full_name, u.email, u.profile_picture_url,
              gbm.joined_at, gbm.role
       FROM group_booking_members gbm
       JOIN users u ON gbm.user_id = u.user_id
       WHERE gbm.group_booking_id = ?
       ORDER BY FIELD(gbm.role,'organizer','member'), gbm.joined_at`,
      [groupBookingId]
    );
    gb.members = members;
    gb.member_count = members.length;
    return gb;
  },

  getUserGroupBookings: async (userId) => {
    const [rows] = await db.promise().query(
      `SELECT gb.*, u.full_name AS created_by_name,
              (SELECT COUNT(*) FROM group_booking_members WHERE group_booking_id = gb.group_booking_id) AS member_count,
              (SELECT role FROM group_booking_members WHERE group_booking_id = gb.group_booking_id AND user_id = ?) AS my_role
       FROM group_bookings gb
       JOIN users u ON gb.created_by = u.user_id
       WHERE gb.created_by = ?
          OR gb.group_booking_id IN (SELECT group_booking_id FROM group_booking_members WHERE user_id = ?)
       ORDER BY gb.created_at DESC`,
      [userId, userId, userId]
    );
    return rows;
  },

  addMember: async (groupBookingId, userId) => {
    const [[gb]] = await db.promise().query(
      'SELECT max_members FROM group_bookings WHERE group_booking_id = ?',
      [groupBookingId]
    );
    if (!gb) throw new Error('Group not found');

    const [[countRow]] = await db.promise().query(
      'SELECT COUNT(*) AS cnt FROM group_booking_members WHERE group_booking_id = ?',
      [groupBookingId]
    );
    if (countRow.cnt >= gb.max_members) throw new Error('Group is full');

    const [result] = await db.promise().query(
      'INSERT INTO group_booking_members (group_booking_id, user_id, role) VALUES (?, ?, "member")',
      [groupBookingId, userId]
    );
    return result;
  },

  removeMember: async (groupBookingId, userId, requesterId) => {
    const [[requesterRow]] = await db.promise().query(
      'SELECT role FROM group_booking_members WHERE group_booking_id = ? AND user_id = ?',
      [groupBookingId, requesterId]
    );
    if (!requesterRow || requesterRow.role !== 'organizer') {
      throw new Error('Only the organizer can remove members');
    }
    return db.promise().query(
      'DELETE FROM group_booking_members WHERE group_booking_id = ? AND user_id = ? AND role != "organizer"',
      [groupBookingId, userId]
    );
  },

  changeMemberRole: async (groupBookingId, userId, newRole, requesterId) => {
    const [[requesterRow]] = await db.promise().query(
      'SELECT role FROM group_booking_members WHERE group_booking_id = ? AND user_id = ?',
      [groupBookingId, requesterId]
    );
    if (!requesterRow || requesterRow.role !== 'organizer') {
      throw new Error('Only the organizer can change roles');
    }
    return db.promise().query(
      'UPDATE group_booking_members SET role = ? WHERE group_booking_id = ? AND user_id = ?',
      [newRole, groupBookingId, userId]
    );
  },

  getMembers: async (groupBookingId) => {
    const [rows] = await db.promise().query(
      `SELECT u.user_id, u.full_name, u.email, u.profile_picture_url,
              gbm.joined_at, gbm.role
       FROM group_booking_members gbm
       JOIN users u ON gbm.user_id = u.user_id
       WHERE gbm.group_booking_id = ?
       ORDER BY FIELD(gbm.role,'organizer','member'), gbm.joined_at`,
      [groupBookingId]
    );
    return rows;
  },

  updateStatus: async (groupBookingId, status) => {
    return db.promise().query(
      'UPDATE group_bookings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE group_booking_id = ?',
      [status, groupBookingId]
    );
  },

  getMemberLocations: async (groupBookingId) => {
    const [rows] = await db.promise().query(
      `SELECT u.user_id, u.full_name, u.profile_picture_url,
              ulu.latitude, ulu.longitude, ulu.city, ulu.country,
              ulu.captured_at, ulu.accuracy_meters
       FROM group_booking_members gbm
       JOIN users u ON gbm.user_id = u.user_id
       LEFT JOIN user_location_updates ulu
         ON ulu.user_identifier = CONCAT('user_', u.user_id)
        AND ulu.captured_at = (
          SELECT MAX(inner_ulu.captured_at)
          FROM user_location_updates inner_ulu
          WHERE inner_ulu.user_identifier = CONCAT('user_', u.user_id)
        )
       WHERE gbm.group_booking_id = ?
       ORDER BY u.full_name`,
      [groupBookingId]
    );
    return rows;
  }
};

module.exports = GroupBooking;
