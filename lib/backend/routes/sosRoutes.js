const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const db = require('../config/db');

// Trigger SOS
router.post('/trigger', authenticate, (req, res) => {
  const user_id = req.user.userId;
  const { latitude, longitude } = req.body;

  const query = `
    INSERT INTO sos_alerts (user_id, latitude, longitude, status)
    VALUES (?, ?, ?, 'Active')
  `;

  db.query(query, [user_id, latitude || 0, longitude || 0], (err, result) => {
    if (err) {
      console.error('SOS error:', err);
      return res.status(500).json({ error: err.message });
    }

    // Notify via socket.io if available
    if (global.io) {
      global.io.emit('sos_alert', {
        user_id: user_id,
        alert_id: result.insertId,
        latitude: latitude,
        longitude: longitude,
        timestamp: new Date()
      });
    }

    res.json({
      success: true,
      alert_id: result.insertId,
      message: 'SOS activated - Emergency contacts notified'
    });
  });
});

// Get recent SOS alerts
router.get('/recent', (req, res) => {
  const query = `
    SELECT
      sa.alert_id,
      sa.user_id,
      sa.status,
      sa.created_at,
      u.full_name
    FROM sos_alerts sa
    JOIN users u ON sa.user_id = u.user_id
    WHERE sa.status = 'Active'
    ORDER BY sa.created_at DESC
    LIMIT 20
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('SOS fetch error:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ success: true, alerts: results || [] });
  });
});

// Resolve SOS
router.post('/:alert_id/resolve', authenticate, (req, res) => {
  const { alert_id } = req.params;

  const query = `UPDATE sos_alerts SET status = 'Resolved' WHERE alert_id = ?`;

  db.query(query, [alert_id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true, message: 'SOS resolved' });
  });
});

module.exports = router;
