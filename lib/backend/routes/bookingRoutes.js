const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createBooking,
  getBooking,
  getUserBookings,
  updateBookingStatus,
  getAdminBookingStats
} = require('../controllers/bookingController');

router.post('/create', authenticate, createBooking);
router.get('/list', authenticate, getUserBookings);
router.get('/admin/stats', authenticate, getAdminBookingStats);
router.get('/:booking_id', authenticate, getBooking);
router.put('/:booking_id/status', authenticate, updateBookingStatus);

module.exports = router;
