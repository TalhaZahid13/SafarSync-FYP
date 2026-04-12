const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const notificationController = require('../controllers/notificationController');

// Get notifications
router.get('/', authenticate, notificationController.getNotifications);

// Mark as read
router.put('/:id/read', authenticate, notificationController.markAsRead);

// Delete notification
router.delete('/:id', authenticate, notificationController.deleteNotification);

// Mark all as read
router.put('/read/all', authenticate, notificationController.markAllAsRead);

module.exports = router;
