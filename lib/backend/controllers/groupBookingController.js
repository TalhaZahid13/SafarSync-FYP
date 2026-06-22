const GroupBooking = require('../models/groupBooking');
const db = require('../config/db');

const VALID_STATUSES = ['Planning', 'Open', 'Full', 'Active', 'Completed', 'Cancelled'];
const createGroupBooking = async (req, res) => {
  const { trip_name, description, start_date, end_date, max_members, destination_id } = req.body;
  const created_by = req.user.userId;

  if (!trip_name) {
    return res.status(400).json({ error: 'trip_name is required' });
  }

  try {
    const result = await GroupBooking.create(
      trip_name, created_by, description || '',
      start_date || null, end_date || null,
      max_members || 20, destination_id || null
    );
    res.status(201).json({
      success: true,
      group_booking_id: result.insertId,
      message: 'Group trip created successfully'
    });
  } catch (err) {
    console.error('Group booking creation error:', err);
    res.status(500).json({ error: 'Failed to create group trip' });
  }
};

const getGroupBooking = async (req, res) => {
  try {
    const groupBooking = await GroupBooking.getById(req.params.group_booking_id);
    if (!groupBooking) return res.status(404).json({ error: 'Group trip not found' });
    res.json({ success: true, group_booking: groupBooking });
  } catch (err) {
    console.error('Group booking fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch group trip' });
  }
};

const getUserGroupBookings = async (req, res) => {
  try {
    const groupBookings = await GroupBooking.getUserGroupBookings(req.user.userId);
    res.json({ success: true, group_bookings: groupBookings });
  } catch (err) {
    console.error('Group bookings fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch group trips' });
  }
};

const joinGroupBooking = async (req, res) => {
  const { group_booking_id } = req.params;
  const user_id = req.user.userId;

  try {
    await GroupBooking.addMember(group_booking_id, user_id);
    res.json({ success: true, message: 'Joined group trip successfully' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Already a member of this group' });
    }
    if (err.message === 'Group is full') {
      return res.status(400).json({ error: 'Group has reached maximum capacity' });
    }
    console.error('Member add error:', err);
    res.status(500).json({ error: 'Failed to join group' });
  }
};

const removeMember = async (req, res) => {
  const { group_booking_id, user_id: targetUserId } = req.params;
  const requesterId = req.user.userId;

  try {
    await GroupBooking.removeMember(group_booking_id, targetUserId, requesterId);
    res.json({ success: true, message: 'Member removed' });
  } catch (err) {
    if (err.message.includes('Only the organizer')) {
      return res.status(403).json({ error: err.message });
    }
    console.error('Remove member error:', err);
    res.status(500).json({ error: 'Failed to remove member' });
  }
};

const changeMemberRole = async (req, res) => {
  const { group_booking_id } = req.params;
  const { user_id: targetUserId, role } = req.body;
  const requesterId = req.user.userId;

  if (!['organizer', 'member'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role. Must be organizer or member' });
  }

  try {
    await GroupBooking.changeMemberRole(group_booking_id, targetUserId, role, requesterId);
    res.json({ success: true, message: 'Role updated' });
  } catch (err) {
    if (err.message.includes('Only the organizer')) {
      return res.status(403).json({ error: err.message });
    }
    console.error('Change role error:', err);
    res.status(500).json({ error: 'Failed to change role' });
  }
};

const closeGroup = async (req, res) => {
  const { group_booking_id } = req.params;
  const user_id = req.user.userId;

  try {
    const gb = await GroupBooking.getById(group_booking_id);
    if (!gb) return res.status(404).json({ error: 'Group not found' });
    if (gb.created_by !== user_id) return res.status(403).json({ error: 'Only the organizer can close the group' });

    await GroupBooking.updateStatus(group_booking_id, 'Cancelled');
    res.json({ success: true, message: 'Group closed' });
  } catch (err) {
    console.error('Close group error:', err);
    res.status(500).json({ error: 'Failed to close group' });
  }
};

const getGroupBookingMembers = async (req, res) => {
  try {
    const members = await GroupBooking.getMembers(req.params.group_booking_id);
    res.json({ success: true, members, member_count: members.length });
  } catch (err) {
    console.error('Members fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch members' });
  }
};

const updateGroupBookingStatus = async (req, res) => {
  const { group_booking_id } = req.params;
  const { status } = req.body;

  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Invalid status. Valid: ${VALID_STATUSES.join(', ')}` });
  }

  try {
    await GroupBooking.updateStatus(group_booking_id, status);
    res.json({ success: true, message: 'Status updated' });
  } catch (err) {
    console.error('Status update error:', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
};

const startGroupTracking = async (req, res) => {
  const { group_booking_id } = req.body;
  try {
    const [result] = await db.promise().query(
      "INSERT INTO group_tracking_sessions (group_booking_id, status) VALUES (?, 'active')",
      [group_booking_id]
    );
    if (global.io) global.io.emit('tracking:started', { group_booking_id });
    res.json({ success: true, session_id: result.insertId });
  } catch (err) {
    console.error('Tracking session error:', err);
    res.status(500).json({ error: 'Failed to start tracking' });
  }
};

const getGroupMemberLocations = async (req, res) => {
  try {
    const locations = await GroupBooking.getMemberLocations(req.params.group_booking_id);
    res.json({ success: true, member_locations: locations });
  } catch (err) {
    console.error('Locations fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch member locations' });
  }
};

const getAdminGroupBookingStats = async (req, res) => {
  try {
    const [[stats]] = await db.promise().query(`
      SELECT
        COUNT(DISTINCT gb.group_booking_id) AS total_group_bookings,
        SUM(CASE WHEN gb.status = 'Planning' THEN 1 ELSE 0 END) AS planning,
        SUM(CASE WHEN gb.status = 'Active' THEN 1 ELSE 0 END) AS active,
        SUM(CASE WHEN gb.status = 'Completed' THEN 1 ELSE 0 END) AS completed,
        COUNT(DISTINCT gbm.user_id) AS total_members,
        COUNT(DISTINCT gts.session_id) AS active_tracking_sessions
      FROM group_bookings gb
      LEFT JOIN group_booking_members gbm ON gb.group_booking_id = gbm.group_booking_id
      LEFT JOIN group_tracking_sessions gts
        ON gb.group_booking_id = gts.group_booking_id AND gts.status = 'active'
    `);
    res.json({ success: true, stats: stats || {} });
  } catch (err) {
    console.error('Stats query error:', err);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
};

module.exports = {
  createGroupBooking,
  getGroupBooking,
  getUserGroupBookings,
  joinGroupBooking,
  removeMember,
  changeMemberRole,
  closeGroup,
  getGroupBookingMembers,
  updateGroupBookingStatus,
  startGroupTracking,
  getGroupMemberLocations,
  getAdminGroupBookingStats
};
