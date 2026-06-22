const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
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
  getAdminGroupBookingStats,
} = require('../controllers/groupBookingController');

router.post('/create', authenticate, createGroupBooking);
router.get('/list', authenticate, getUserGroupBookings);
router.post('/tracking/start', authenticate, startGroupTracking);
router.get('/admin/stats', authenticate, getAdminGroupBookingStats);
router.get('/:group_booking_id', authenticate, getGroupBooking);
router.post('/:group_booking_id/join', authenticate, joinGroupBooking);
router.post('/:group_booking_id/close', authenticate, closeGroup);
router.get('/:group_booking_id/members', authenticate, getGroupBookingMembers);
router.delete('/:group_booking_id/members/:user_id', authenticate, removeMember);
router.put('/:group_booking_id/members/role', authenticate, changeMemberRole);
router.get('/:group_booking_id/locations', authenticate, getGroupMemberLocations);
router.put('/:group_booking_id/status', authenticate, updateGroupBookingStatus);

module.exports = router;
