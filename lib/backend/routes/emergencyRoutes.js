const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const {
  triggerSOS,
  resolveSOS,
  cancelSOS,
  getMyAlerts,
  getActiveAlert,
  getAllAlerts,
} = require('../controllers/emergencyController');

// Static routes before parametric
router.get('/admin/all', authenticate, getAllAlerts);
router.get('/active', authenticate, getActiveAlert);
router.get('/my-alerts', authenticate, getMyAlerts);
router.post('/trigger', authenticate, triggerSOS);

// Parametric routes last
router.put('/:id/resolve', authenticate, resolveSOS);
router.put('/:id/cancel', authenticate, cancelSOS);

module.exports = router;
