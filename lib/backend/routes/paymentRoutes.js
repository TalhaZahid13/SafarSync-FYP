const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const { createPaymentIntent, confirmPayment } = require('../controllers/paymentController');

router.post('/create-intent', authenticate, createPaymentIntent);
router.post('/confirm', authenticate, confirmPayment);

module.exports = router;
