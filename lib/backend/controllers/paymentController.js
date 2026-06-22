const db = require('../config/db');
const Booking = require('../models/booking');

const stripe = process.env.STRIPE_SECRET_KEY
  ? require('stripe')(process.env.STRIPE_SECRET_KEY)
  : null;

const stripeRequired = (res) => {
  if (!stripe) {
    res.status(500).json({ error: 'Stripe not configured. Set STRIPE_SECRET_KEY in .env' });
    return false;
  }
  return true;
};

const createPaymentIntent = async (req, res) => {
  if (!stripeRequired(res)) return;

  const { booking_id, amount } = req.body;
  const user_id = req.user.userId;

  if (!booking_id || !amount) {
    return res.status(400).json({ error: 'booking_id and amount are required' });
  }
  if (amount < 50) {
    return res.status(400).json({ error: 'Amount must be at least 50 cents' });
  }

  try {
    const booking = await Booking.getById(booking_id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.user_id !== user_id) return res.status(403).json({ error: 'Forbidden' });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      metadata: { booking_id: String(booking_id), user_id: String(user_id) },
    });

    await db.promise().query(
      `INSERT INTO payments (user_id, booking_id, stripe_payment_intent_id, amount, currency, status)
       VALUES (?, ?, ?, ?, 'usd', 'pending')
       ON DUPLICATE KEY UPDATE status = 'pending', updated_at = CURRENT_TIMESTAMP`,
      [user_id, booking_id, paymentIntent.id, Math.round(amount) / 100]
    );

    await Booking.markAwaitingPayment(booking_id);

    res.json({
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error('createPaymentIntent error:', err);
    res.status(500).json({ error: err.message || 'Failed to create payment intent' });
  }
};

const confirmPayment = async (req, res) => {
  if (!stripeRequired(res)) return;

  const { booking_id, payment_intent_id } = req.body;
  const user_id = req.user.userId;

  if (!booking_id || !payment_intent_id) {
    return res.status(400).json({ error: 'booking_id and payment_intent_id are required' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);
    if (paymentIntent.status !== 'succeeded') {
      return res.status(400).json({ error: `Payment not completed. Status: ${paymentIntent.status}` });
    }
    if (String(paymentIntent.metadata.user_id) !== String(user_id)) {
      return res.status(403).json({ error: 'Payment does not belong to this user' });
    }

    await Booking.markPaymentPaid(booking_id, payment_intent_id);

    const [[payRow]] = await db.promise().query(
      'SELECT id FROM payments WHERE stripe_payment_intent_id = ?',
      [payment_intent_id]
    );
    if (payRow) {
      await db.promise().query(
        `UPDATE payments SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP
         WHERE stripe_payment_intent_id = ?`,
        [payment_intent_id]
      );
      await db.promise().query(
        `INSERT INTO transactions (payment_id, amount, status, transaction_reference)
         VALUES (?, ?, 'completed', ?)`,
        [payRow.id, paymentIntent.amount / 100, payment_intent_id]
      );
    }

    res.json({
      success: true,
      message: 'Payment confirmed. Booking is now Confirmed.',
      payment_id: payRow?.id ?? null,
    });
  } catch (err) {
    console.error('confirmPayment error:', err);
    res.status(500).json({ error: err.message || 'Failed to confirm payment' });
  }
};

const handleWebhook = async (req, res) => {
  if (!stripeRequired(res)) return;

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    if (webhookSecret) {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } else {
      event = req.body;
    }
  } catch (err) {
    return res.status(400).json({ error: `Webhook signature verification failed: ${err.message}` });
  }

  try {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const pi = event.data.object;
        const bookingId = pi.metadata?.booking_id;
        if (bookingId) {
          await Booking.markPaymentPaid(bookingId, pi.id);
          await db.promise().query(
            `UPDATE payments SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP
             WHERE stripe_payment_intent_id = ?`,
            [pi.id]
          );
        }
        break;
      }
      case 'payment_intent.payment_failed': {
        const pi = event.data.object;
        await db.promise().query(
          `UPDATE payments SET status = 'failed', updated_at = CURRENT_TIMESTAMP
           WHERE stripe_payment_intent_id = ?`,
          [pi.id]
        );
        break;
      }
      case 'charge.refunded': {
        const charge = event.data.object;
        const piId = charge.payment_intent;
        if (piId) {
          const [[payRow]] = await db.promise().query(
            'SELECT id, booking_id FROM payments WHERE stripe_payment_intent_id = ?',
            [piId]
          );
          if (payRow) {
            await db.promise().query(
              `UPDATE payments SET status = 'refunded', refund_approved_at = NOW(),
               updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
              [payRow.id]
            );
            if (payRow.booking_id) {
              await Booking.markRefunded(payRow.booking_id);
            }
            await db.promise().query(
              `INSERT INTO transactions (payment_id, amount, status, transaction_reference)
               VALUES (?, ?, 'refunded', ?)`,
              [payRow.id, charge.amount_refunded / 100, charge.id]
            );
          }
        }
        break;
      }
      case 'payment_intent.canceled': {
        const pi = event.data.object;
        await db.promise().query(
          `UPDATE payments SET status = 'failed', updated_at = CURRENT_TIMESTAMP
           WHERE stripe_payment_intent_id = ?`,
          [pi.id]
        );
        if (pi.metadata?.booking_id) {
          await Booking.updateStatus(pi.metadata.booking_id, 'Cancelled');
        }
        break;
      }
    }

    res.json({ received: true });
  } catch (err) {
    console.error('Webhook handling error:', err);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};

const getPaymentHistory = async (req, res) => {
  const user_id = req.user.userId;
  try {
    const [rows] = await db.promise().query(
      `SELECT p.*, b.booking_id, d.name AS destination_name
       FROM payments p
       LEFT JOIN bookings b ON p.booking_id = b.booking_id
       LEFT JOIN destinations d ON b.destination_id = d.destination_id
       WHERE p.user_id = ?
       ORDER BY p.created_at DESC`,
      [user_id]
    );
    res.json({ success: true, payments: rows });
  } catch (err) {
    console.error('getPaymentHistory error:', err);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
};

const requestRefund = async (req, res) => {
  const { booking_id } = req.body;
  const user_id = req.user.userId;

  if (!booking_id) return res.status(400).json({ error: 'booking_id is required' });

  try {
    const booking = await Booking.getById(booking_id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.user_id !== user_id) return res.status(403).json({ error: 'Forbidden' });
    if (booking.payment_status !== 'Paid') {
      return res.status(400).json({ error: 'No paid payment to refund' });
    }
    if (!booking.payment_intent_id) {
      return res.status(400).json({ error: 'No payment intent found for this booking' });
    }

    const [[existing]] = await db.promise().query(
      'SELECT id, refund_requested_at, refund_approved_at FROM payments WHERE stripe_payment_intent_id = ?',
      [booking.payment_intent_id]
    );
    if (!existing) return res.status(404).json({ error: 'Payment record not found' });
    if (existing.refund_approved_at) {
      return res.status(400).json({ error: 'Refund already approved' });
    }
    if (existing.refund_requested_at) {
      return res.status(400).json({ error: 'Refund already requested — awaiting admin approval' });
    }

    await db.promise().query(
      'UPDATE payments SET refund_requested_at = NOW(), updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [existing.id]
    );

    res.json({
      success: true,
      message: 'Refund request submitted. Our team will review it within 24-48 hours.',
    });
  } catch (err) {
    console.error('requestRefund error:', err);
    res.status(500).json({ error: err.message || 'Failed to request refund' });
  }
};

const getPaymentReceipt = async (req, res) => {
  const { payment_id } = req.params;
  const user_id = req.user.userId;

  try {
    const [[payment]] = await db.promise().query(
      `SELECT p.*, b.booking_id, b.num_travelers, b.travel_date, b.booking_date,
              d.name AS destination_name, u.full_name, u.email,
              t.transaction_reference, t.created_at AS transaction_date
       FROM payments p
       LEFT JOIN bookings b ON p.booking_id = b.booking_id
       LEFT JOIN destinations d ON b.destination_id = d.destination_id
       LEFT JOIN users u ON p.user_id = u.user_id
       LEFT JOIN transactions t ON t.payment_id = p.id AND t.status = 'completed'
       WHERE p.id = ? AND p.user_id = ?`,
      [payment_id, user_id]
    );

    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    res.json({ success: true, receipt: payment });
  } catch (err) {
    console.error('getPaymentReceipt error:', err);
    res.status(500).json({ error: 'Failed to fetch receipt' });
  }
};

module.exports = {
  createPaymentIntent,
  confirmPayment,
  handleWebhook,
  getPaymentHistory,
  requestRefund,
  getPaymentReceipt
};
