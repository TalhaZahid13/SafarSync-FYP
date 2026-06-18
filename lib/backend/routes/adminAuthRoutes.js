const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  adminLogin,
  adminSignup,
  adminForgotPassword,
  adminResetPassword,
  adminGetMe,
} = require('../controllers/adminAuthController');

router.post('/login', adminLogin);
router.post('/signup', adminSignup);
router.post('/forgot-password', adminForgotPassword);
router.post('/reset-password', adminResetPassword);
router.get('/me', authenticate, adminGetMe);

module.exports = router;
