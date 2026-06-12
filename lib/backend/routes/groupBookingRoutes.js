const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createGroupBooking,
  getGroupBooking,
  getUserGroupBookings,
  joinGroupBooking,
  getGroupBookingMembers,
  updateGroupBookingStatus,
  startGroupTracking,
  getGroupMemberLocations,
  getAdminGroupBookingStats
} = require('../controllers/groupBookingController');

router.post('/create', authenticate, createGroupBooking);
router.get('/list', authenticate, getUserGroupBookings);
router.get('/:group_booking_id', authenticate, getGroupBooking);
router.post('/:group_booking_id/join', authenticate, joinGroupBooking);
router.get('/:group_booking_id/members', authenticate, getGroupBookingMembers);
router.get('/:group_booking_id/locations', authenticate, getGroupMemberLocations);
router.put('/:group_booking_id/status', authenticate, updateGroupBookingStatus);
router.post('/tracking/start', authenticate, startGroupTracking);
router.get('/admin/stats', authenticate, getAdminGroupBookingStats);

module.exports = router;
