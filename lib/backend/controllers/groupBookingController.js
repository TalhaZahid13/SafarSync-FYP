const GroupBooking = require('../models/groupBooking');
const db = require('../config/db');

const createGroupBooking = (req, res) => {
  const { trip_name, description, start_date, end_date } = req.body;
  const created_by = req.user.userId;

  if (!trip_name) {
    return res.status(400).json({ error: 'trip_name is required' });
  }

  GroupBooking.create(trip_name, created_by, description || '', start_date || null, end_date || null, (err, result) => {
    if (err) {
      console.error('Group booking creation error:', err);
      return res.status(500).json({ error: 'Failed to create group booking' });
    }

    res.status(201).json({
      success: true,
      group_booking_id: result.insertId,
      message: 'Group booking created successfully'
    });
  });
};

const getGroupBooking = (req, res) => {
  const { group_booking_id } = req.params;

  GroupBooking.getById(group_booking_id, (err, groupBooking) => {
    if (err) {
      console.error('Group booking fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch group booking' });
    }

    if (!groupBooking) {
      return res.status(404).json({ error: 'Group booking not found' });
    }

    res.json({ success: true, group_booking: groupBooking });
  });
};

const getUserGroupBookings = (req, res) => {
  const user_id = req.user.userId;

  GroupBooking.getUserGroupBookings(user_id, (err, groupBookings) => {
    if (err) {
      console.error('Group bookings fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch group bookings' });
    }

    res.json({ success: true, group_bookings: groupBookings || [] });
  });
};

const joinGroupBooking = (req, res) => {
  const { group_booking_id } = req.params;
  const user_id = req.user.userId;

  GroupBooking.addMember(group_booking_id, user_id, (err) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(400).json({ error: 'Already a member' });
      }
      console.error('Member add error:', err);
      return res.status(500).json({ error: 'Failed to join group' });
    }

    res.json({ success: true, message: 'Joined group booking successfully' });
  });
};

const getGroupBookingMembers = (req, res) => {
  const { group_booking_id } = req.params;

  GroupBooking.getMembers(group_booking_id, (err, members) => {
    if (err) {
      console.error('Members fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch members' });
    }

    res.json({ success: true, members: members || [], member_count: members ? members.length : 0 });
  });
};

const updateGroupBookingStatus = (req, res) => {
  const { group_booking_id } = req.params;
  const { status } = req.body;

  if (!['Planning', 'Active', 'Completed'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  GroupBooking.updateStatus(group_booking_id, status, (err) => {
    if (err) {
      console.error('Status update error:', err);
      return res.status(500).json({ error: 'Failed to update status' });
    }

    res.json({ success: true, message: 'Status updated' });
  });
};

const startGroupTracking = (req, res) => {
  const { group_booking_id } = req.body;

  const query = `
    INSERT INTO group_tracking_sessions (group_booking_id, status)
    VALUES (?, 'active')
  `;

  db.query(query, [group_booking_id], (err, result) => {
    if (err) {
      console.error('Tracking session error:', err);
      return res.status(500).json({ error: 'Failed to start tracking' });
    }

    if (global.io) {
      global.io.emit('tracking:started', { group_booking_id });
    }

    res.json({ success: true, session_id: result.insertId });
  });
};

const getGroupMemberLocations = (req, res) => {
  const { group_booking_id } = req.params;

  GroupBooking.getMemberLocations(group_booking_id, (err, locations) => {
    if (err) {
      console.error('Locations fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch member locations' });
    }

    res.json({ success: true, member_locations: locations || [] });
  });
};

const getAdminGroupBookingStats = (req, res) => {
  const query = `
    SELECT
      COUNT(DISTINCT gb.group_booking_id) as total_group_bookings,
      SUM(CASE WHEN gb.status = 'Planning' THEN 1 ELSE 0 END) as planning,
      SUM(CASE WHEN gb.status = 'Active' THEN 1 ELSE 0 END) as active,
      SUM(CASE WHEN gb.status = 'Completed' THEN 1 ELSE 0 END) as completed,
      COUNT(DISTINCT gbm.user_id) as total_members,
      COUNT(DISTINCT gts.session_id) as active_tracking_sessions
    FROM group_bookings gb
    LEFT JOIN group_booking_members gbm ON gb.group_booking_id = gbm.group_booking_id
    LEFT JOIN group_tracking_sessions gts ON gb.group_booking_id = gts.group_booking_id
      AND gts.status = 'active'
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Stats query error:', err);
      return res.status(500).json({ error: 'Failed to fetch stats' });
    }

    res.json({ success: true, stats: results[0] || {} });
  });
};

module.exports = {
  createGroupBooking,
  getGroupBooking,
  getUserGroupBookings,
  joinGroupBooking,
  getGroupBookingMembers,
  updateGroupBookingStatus,
  startGroupTracking,
  getGroupMemberLocations,
  getAdminGroupBookingStats
};
