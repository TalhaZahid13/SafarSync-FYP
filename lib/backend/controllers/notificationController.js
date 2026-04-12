const db = require('../config/db');

// Get notifications
const getNotifications = (req, res) => {
  const user_id = req.user.userId;
  const { limit = 20, unread_only = false } = req.query;

  let query = 'SELECT * FROM notifications WHERE user_id = ?';
  const params = [user_id];

  if (unread_only === 'true') {
    query += ' AND is_read = FALSE';
  }

  query += ' ORDER BY created_at DESC LIMIT ?';
  params.push(parseInt(limit));

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to fetch notifications' });
    }
    res.json({ notifications: results });
  });
};

// Mark as read
const markAsRead = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;

  const query = 'UPDATE notifications SET is_read = TRUE WHERE notification_id = ? AND user_id = ?';

  db.query(query, [id, user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to update notification' });
    }
    res.json({ message: 'Notification marked as read' });
  });
};

// Delete notification
const deleteNotification = (req, res) => {
  const { id } = req.params;
  const user_id = req.user.userId;

  const query = 'DELETE FROM notifications WHERE notification_id = ? AND user_id = ?';

  db.query(query, [id, user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to delete notification' });
    }
    res.json({ message: 'Notification deleted' });
  });
};

// Mark all as read
const markAllAsRead = (req, res) => {
  const user_id = req.user.userId;

  const query = 'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE';

  db.query(query, [user_id], (err) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Failed to update notifications' });
    }
    res.json({ message: 'All notifications marked as read' });
  });
};

module.exports = {
  getNotifications,
  markAsRead,
  deleteNotification,
  markAllAsRead,
};
