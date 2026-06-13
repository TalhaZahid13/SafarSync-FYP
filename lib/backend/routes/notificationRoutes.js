const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const notificationController = require('../controllers/notificationController');

// Unread count — must be before /:id routes
router.get('/unread-count', authenticate, (req, res) => {
  const db = require('../config/db');
  db.query(
    'SELECT COUNT(*) AS count FROM notifications WHERE user_id = ? AND is_read = FALSE',
    [req.user.userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, count: rows[0]?.count ?? 0 });
    }
  );
});

// Get notifications
router.get('/', authenticate, notificationController.getNotifications);

// Mark as read
router.put('/:id/read', authenticate, notificationController.markAsRead);

// Delete notification
router.delete('/:id', authenticate, notificationController.deleteNotification);

// Mark all as read
router.put('/read/all', authenticate, notificationController.markAllAsRead);

module.exports = router;
