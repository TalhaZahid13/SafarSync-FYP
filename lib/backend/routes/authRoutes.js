const express = require('express');
const { authenticate } = require('../middleware/authMiddleware');
const {
  loginUser,
  registerUser,
  exchangeFirebaseToken,
  getMe,
} = require('../controllers/authController');

const router = express.Router();

// Firebase token exchange — call this after every Firebase login
router.post('/firebase-exchange', exchangeFirebaseToken);

// Legacy endpoints
router.post('/signup', registerUser);
router.post('/login', loginUser);

// Current user info (protected)
router.get('/me', authenticate, getMe);

router.get('/', (req, res) => res.json({ message: 'Auth routes active' }));

module.exports = router;
