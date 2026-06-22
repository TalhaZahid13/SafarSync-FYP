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
  logEmergencyEvent,
  pushTrackingPoint,
  getTrackingHistory,
  acknowledgeEmergency,
  getAllEvents,
} = require('../controllers/emergencyController');

// Static routes before parametric
router.get('/admin/all',    authenticate, getAllAlerts);
router.get('/admin/events', authenticate, getAllEvents);
router.get('/active',       authenticate, getActiveAlert);
router.get('/my-alerts',    authenticate, getMyAlerts);
router.post('/trigger',     authenticate, triggerSOS);
router.post('/event',       authenticate, logEmergencyEvent);
router.post('/tracking',    authenticate, pushTrackingPoint);

// Parametric routes last
router.get('/:id/tracking',    authenticate, getTrackingHistory);
router.put('/:id/resolve',     authenticate, resolveSOS);
router.put('/:id/cancel',      authenticate, cancelSOS);
router.put('/:id/acknowledge', authenticate, acknowledgeEmergency);

module.exports = router;
