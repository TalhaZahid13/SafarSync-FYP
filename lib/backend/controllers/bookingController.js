const Booking = require('../models/booking');
const db = require('../config/db');

const createBooking = (req, res) => {
  const { destination_id, booking_date, duration_days, notes } = req.body;
  const user_id = req.user.userId;

  if (!destination_id || !booking_date) {
    return res.status(400).json({ error: 'destination_id and booking_date are required' });
  }

  Booking.create(user_id, destination_id, booking_date, duration_days || 1, notes || '', (err, result) => {
    if (err) {
      console.error('Booking creation error:', err);
      return res.status(500).json({ error: 'Failed to create booking' });
    }

    res.status(201).json({
      success: true,
      booking_id: result.insertId,
      message: 'Booking created successfully'
    });
  });
};

const getBooking = (req, res) => {
  const { booking_id } = req.params;

  Booking.getById(booking_id, (err, booking) => {
    if (err) {
      console.error('Booking fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch booking' });
    }

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json({ success: true, booking });
  });
};

const getUserBookings = (req, res) => {
  const user_id = req.user.userId;

  Booking.getUserBookings(user_id, (err, bookings) => {
    if (err) {
      console.error('Bookings fetch error:', err);
      return res.status(500).json({ error: 'Failed to fetch bookings' });
    }

    res.json({ success: true, bookings: bookings || [] });
  });
};

const updateBookingStatus = (req, res) => {
  const { booking_id } = req.params;
  const { status } = req.body;

  if (!['Planned', 'Active', 'Completed'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  Booking.updateStatus(booking_id, status, (err, result) => {
    if (err) {
      console.error('Status update error:', err);
      return res.status(500).json({ error: 'Failed to update status' });
    }

    res.json({ success: true, message: 'Status updated' });
  });
};

const getAdminBookingStats = (req, res) => {
  const query = `
    SELECT
      COUNT(*) as total_bookings,
      SUM(CASE WHEN status = 'Planned' THEN 1 ELSE 0 END) as planned,
      SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active,
      SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed
    FROM bookings
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
  createBooking,
  getBooking,
  getUserBookings,
  updateBookingStatus,
  getAdminBookingStats
};
