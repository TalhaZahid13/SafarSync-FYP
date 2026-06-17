const express = require('express');
const { authenticate } = require('../middleware/authMiddleware');
const {
  getProfile,
  updateProfile,
  getStats,
  getPreferences,
  updatePreferences,
  searchByEmail,
  changePassword,
  deleteAccount,
} = require('../controllers/userController');

const router = express.Router();

router.get('/profile',      authenticate, getProfile);
router.put('/profile',      authenticate, updateProfile);
router.get('/stats',        authenticate, getStats);
router.get('/preferences',  authenticate, getPreferences);
router.put('/preferences',  authenticate, updatePreferences);
router.get('/search',       authenticate, searchByEmail);
router.put('/change-password', authenticate, changePassword);
router.delete('/account',   authenticate, deleteAccount);

router.get('/', (req, res) => res.json({ message: 'User routes active' }));

module.exports = router;
