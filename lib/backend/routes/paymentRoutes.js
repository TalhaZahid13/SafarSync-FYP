const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  createPaymentIntent,
  confirmPayment,
  handleWebhook,
  getPaymentHistory,
  requestRefund,
  getPaymentReceipt,
} = require('../controllers/paymentController');

// Stripe webhook — raw body required for signature verification
router.post('/webhook', express.raw({ type: 'application/json' }), handleWebhook);

router.post('/create-intent', authenticate, createPaymentIntent);
router.post('/confirm', authenticate, confirmPayment);
router.post('/refund', authenticate, requestRefund);
router.get('/history', authenticate, getPaymentHistory);
router.get('/:payment_id/receipt', authenticate, getPaymentReceipt);

module.exports = router;
