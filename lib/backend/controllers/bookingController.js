const Booking = require('../models/booking');
const db = require('../config/db');

const VALID_STATUSES = [
  'Pending', 'Awaiting Payment', 'Confirmed',
  'Active', 'Completed', 'Cancelled', 'Refunded'
];

const ALLOWED_TRANSITIONS = {
  'Pending':          ['Awaiting Payment', 'Confirmed', 'Cancelled'],
  'Awaiting Payment': ['Confirmed', 'Cancelled', 'Refunded'],
  'Confirmed':        ['Active', 'Cancelled', 'Refunded'],
  'Active':           ['Completed', 'Cancelled'],
  'Completed':        [],
  'Cancelled':        ['Refunded'],
  'Refunded':         [],
};

const createBooking = async (req, res) => {
  const {
    destination_id, booking_date, travel_date, num_travelers, duration_days, notes,
    booking_type, item_name, item_price_per_unit, total_amount,
  } = req.body;
  const user_id = req.user.userId;

  if (!booking_date) {
    return res.status(400).json({ error: 'booking_date is required' });
  }

  const isHotelOrRestaurant = booking_type === 'hotel' || booking_type === 'restaurant';

  if (!isHotelOrRestaurant && !destination_id) {
    return res.status(400).json({ error: 'destination_id is required for destination bookings' });
  }

  try {
    let effectiveDestId = destination_id || null;
    let effectiveTotal;
    const days = parseInt(duration_days) || 1;
    const travelers = parseInt(num_travelers) || 1;

    if (isHotelOrRestaurant) {
      // Hotel / Restaurant: use provided price, no destination lookup
      const pricePerUnit = parseFloat(item_price_per_unit) || 0;
      effectiveTotal = total_amount ? parseFloat(total_amount) : pricePerUnit * days * travelers;
      const typeLabel = booking_type === 'hotel' ? 'Hotel' : 'Restaurant';
      const itemLabel = item_name ? `[${typeLabel}: ${item_name}]` : `[${typeLabel} Booking]`;
      const combinedNotes = notes ? `${itemLabel} ${notes}` : itemLabel;

      const [result] = await Booking.create(
        user_id, effectiveDestId, booking_date, travel_date || null,
        travelers, days, combinedNotes, effectiveTotal
      );
      return res.status(201).json({
        success: true,
        booking_id: result.insertId,
        total_amount: effectiveTotal,
        booking_type,
        item_name,
      });
    }

    // Standard destination booking
    let destRows = [];
    try {
      [destRows] = await db.promise().query(
        'SELECT destinationId AS destination_id, average_cost FROM destination WHERE destinationId = ?',
        [destination_id]
      );
    } catch (_) {}
    if (destRows.length === 0) {
      try {
        [destRows] = await db.promise().query(
          'SELECT destination_id, average_cost FROM destinations WHERE destination_id = ?',
          [destination_id]
        );
      } catch (_) {}
    }
    if (destRows.length === 0) {
      return res.status(404).json({ error: 'Destination not found' });
    }

    const pricePerDay = parseFloat(destRows[0].average_cost) || 50;
    effectiveTotal = pricePerDay * days * travelers;

    const [result] = await Booking.create(
      user_id, destination_id, booking_date, travel_date || null,
      travelers, days, notes || '', effectiveTotal
    );

    res.status(201).json({
      success: true,
      booking_id: result.insertId,
      total_amount: effectiveTotal,
      message: 'Booking created'
    });
  } catch (err) {
    console.error('Booking creation error:', err.message || err);
    // Surface FK / column errors as a hint so the client can show something useful
    const msg = err.code === 'ER_NO_REFERENCED_ROW_2'
      ? 'Destination not found in database'
      : err.code === 'ER_BAD_FIELD_ERROR'
      ? 'Database schema outdated — run migration_v16.sql'
      : err.code === 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD'
      ? 'Database schema outdated — run migration_v16.sql'
      : 'Failed to create booking';
    res.status(500).json({ error: msg });
  }
};

const getBooking = async (req, res) => {
  try {
    const booking = await Booking.getById(req.params.booking_id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json({ success: true, booking });
  } catch (err) {
    console.error('Booking fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch booking' });
  }
};

const getUserBookings = async (req, res) => {
  try {
    const bookings = await Booking.getUserBookings(req.user.userId);
    res.json({ success: true, bookings });
  } catch (err) {
    console.error('Bookings fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
};

const updateBookingStatus = async (req, res) => {
  const { booking_id } = req.params;
  const { status } = req.body;
  const is_admin = req.user?.isAdmin || req.user?.role === 'admin' || req.user?.adminId;

  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `Invalid status. Valid: ${VALID_STATUSES.join(', ')}` });
  }

  try {
    const booking = await Booking.getById(booking_id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    if (!is_admin && booking.user_id !== req.user.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const currentStatus = booking.status;
    const allowed = ALLOWED_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(status)) {
      return res.status(400).json({
        error: `Cannot transition from '${currentStatus}' to '${status}'. Allowed: ${allowed.join(', ') || 'none'}`,
      });
    }

    await Booking.updateStatus(booking_id, status);
    res.json({ success: true, message: 'Status updated' });
  } catch (err) {
    console.error('Status update error:', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
};

const cancelBooking = async (req, res) => {
  const { booking_id } = req.params;
  const { reason } = req.body;
  const user_id = req.user.userId;

  try {
    const booking = await Booking.getById(booking_id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.user_id !== user_id) return res.status(403).json({ error: 'Forbidden' });

    const nonCancellable = ['Completed', 'Cancelled', 'Refunded'];
    if (nonCancellable.includes(booking.status)) {
      return res.status(400).json({ error: `Cannot cancel a ${booking.status} booking` });
    }

    const [result] = await Booking.cancelBooking(booking_id, user_id, reason || '');
    if (result.affectedRows === 0) {
      return res.status(400).json({ error: 'Booking could not be cancelled' });
    }

    res.json({ success: true, message: 'Booking cancelled' });
  } catch (err) {
    console.error('Cancel booking error:', err);
    res.status(500).json({ error: 'Failed to cancel booking' });
  }
};
const getAdminBookingStats = async (req, res) => {
  try {
    const stats = await Booking.getAdminStats();
    res.json({ success: true, stats });
  } catch (err) {
    console.error('Stats query error:', err);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
};

module.exports = {
  createBooking,
  getBooking,
  getUserBookings,
  updateBookingStatus,
  cancelBooking,
  getAdminBookingStats
};
