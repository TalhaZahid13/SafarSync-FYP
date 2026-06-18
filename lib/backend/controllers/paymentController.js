const db = require('../config/db');

let stripe;
if (process.env.STRIPE_SECRET_KEY) {
  try {
    stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  } catch (_) {
    console.warn('Stripe package not installed. Run: npm install stripe');
  }
}

const createPaymentIntent = async (req, res) => {
  if (!stripe) {
    return res.status(500).json({
      error: 'Stripe is not configured. Add STRIPE_SECRET_KEY to .env and run: npm install stripe',
    });
  }

  const { booking_id, amount } = req.body;
  const user_id = req.user.userId;

  if (!booking_id || !amount) {
    return res.status(400).json({ error: 'booking_id and amount are required' });
  }

  if (amount < 50) {
    return res.status(400).json({ error: 'Amount must be at least 50 cents' });
  }

  try {
    const [rows] = await db.promise().query(
      'SELECT booking_id FROM bookings WHERE booking_id = ? AND user_id = ?',
      [booking_id, user_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      metadata: {
        booking_id: String(booking_id),
        user_id: String(user_id),
      },
    });

    res.json({
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error('Stripe createPaymentIntent error:', err);
    res.status(500).json({ error: err.message || 'Failed to create payment intent' });
  }
};

const confirmPayment = async (req, res) => {
  if (!stripe) {
    return res.status(500).json({ error: 'Stripe is not configured' });
  }

  const { booking_id, payment_intent_id } = req.body;
  const user_id = req.user.userId;

  if (!booking_id || !payment_intent_id) {
    return res.status(400).json({ error: 'booking_id and payment_intent_id are required' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    if (paymentIntent.status !== 'succeeded') {
      return res.status(400).json({
        error: `Payment not completed. Status: ${paymentIntent.status}`,
      });
    }

    // Verify the paymentIntent belongs to this user
    if (String(paymentIntent.metadata.user_id) !== String(user_id)) {
      return res.status(403).json({ error: 'Payment does not belong to this user' });
    }

    await db.promise().query(
      `UPDATE bookings
       SET payment_status = 'Paid', payment_intent_id = ?, updated_at = CURRENT_TIMESTAMP
       WHERE booking_id = ? AND user_id = ?`,
      [payment_intent_id, booking_id, user_id]
    );

    res.json({ success: true, message: 'Payment confirmed' });
  } catch (err) {
    console.error('Payment confirmation error:', err);
    res.status(500).json({ error: err.message || 'Failed to confirm payment' });
  }
};

module.exports = { createPaymentIntent, confirmPayment };
