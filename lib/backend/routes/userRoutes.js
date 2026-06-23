const express = require('express');
const multer  = require('multer');
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
  updateThemePreference,
  uploadProfilePhoto,
} = require('../controllers/userController');

const _upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

const router = express.Router();

router.get('/profile',      authenticate, getProfile);
router.put('/profile',      authenticate, updateProfile);
router.post('/profile/photo', authenticate, _upload.single('photo'), uploadProfilePhoto);
router.get('/stats',        authenticate, getStats);
router.get('/preferences',  authenticate, getPreferences);
router.put('/preferences',  authenticate, updatePreferences);
router.get('/search',       authenticate, searchByEmail);
router.put('/change-password', authenticate, changePassword);
router.delete('/account',         authenticate, deleteAccount);
router.put('/theme-preference',   authenticate, updateThemePreference);

router.get('/', (req, res) => res.json({ message: 'User routes active' }));

module.exports = router;
