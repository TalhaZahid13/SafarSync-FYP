const db = require('../config/db');
const EmergencyAlert = require('../models/emergencyAlert');
const { sendEmergencyAlertEmail, sendEmergencyContactEmail } = require('../services/emailService');

const _notify = (userId, title, message, type, actionUrl = null) => {
  db.query(
    'INSERT INTO notifications (user_id, title, message, type, action_url) VALUES (?, ?, ?, ?, ?)',
    [userId, title, message, type, actionUrl],
    (err) => { if (err) console.error('[Notification] Insert error:', err.message); }
  );
  if (global.io) {
    global.io.to(`user:${userId}`).emit('notification:new', { title, message, type });
  }
};

const _dispatchEmergencyNotifications = (alertId, userId, lat, lng, msg, trip_id, trip_type) => {
  const userQuery = `
    SELECT u.full_name, u.phone_number, u.email,
           CASE WHEN ? = 'group' THEN gb.trip_name ELSE NULL END AS trip_name
    FROM users u
    LEFT JOIN group_bookings gb ON gb.group_booking_id = ?
    WHERE u.user_id = ?
  `;
  db.query(userQuery, [trip_type || '', trip_id || 0, userId], (err, rows) => {
    if (err || !rows || !rows.length) {
      console.error('[Emergency] User context fetch error:', err?.message);
      return;
    }
    const user = rows[0];
    const tripName = user.trip_name || (trip_id ? `Trip #${trip_id}` : null);
    const locationLabel = `${parseFloat(lat).toFixed(5)}, ${parseFloat(lng).toFixed(5)}`;
    const timestamp = new Date().toLocaleString('en-PK', { timeZone: 'Asia/Karachi' });

    if (global.io) {
      global.io.to('emergency:admin').emit('emergency:sos', {
        alert_id:   alertId,
        user_id:    userId,
        user_name:  user.full_name,
        user_phone: user.phone_number || 'N/A',
        user_email: user.email,
        trip_name:  tripName || null,
        latitude:   lat,
        longitude:  lng,
        message:    msg || null,
        timestamp:  new Date().toISOString(),
      });
      global.io.emit('sos_alert', {
        alert_id: alertId,
        user_id: userId,
        latitude: lat,
        longitude: lng,
        timestamp: new Date().toISOString(),
      });
    }

    _notify(
      userId,
      '🚨 SOS Alert Sent',
      'Your emergency alert has been broadcast to all admins. Stay safe — help is coming.',
      'emergency_sos_sent',
      `/emergency/${alertId}`
    );

    db.query(
      `SELECT contact_name, contact_phone, contact_email, relationship
       FROM emergency_contacts
       WHERE user_id = ? AND contact_email IS NOT NULL AND contact_email != ''`,
      [userId],
      (err6, contacts) => {
        if (err6) { console.error('[Emergency] Contact email fetch error:', err6.message); return; }
        const emailPayloadContact = {
          userName:  user.full_name,
          userPhone: user.phone_number || 'N/A',
          tripName,
          latitude:  lat,
          longitude: lng,
          alertId,
          message:   msg,
          timestamp,
        };
        for (const c of (contacts || [])) {
          sendEmergencyContactEmail({
            toEmail:      c.contact_email,
            toName:       c.contact_name,
            relationship: c.relationship,
            ...emailPayloadContact,
          });
        }
        if ((contacts || []).length > 0) {
          console.log(`[Emergency] Emailed ${contacts.length} emergency contact(s) for user ${userId}`);
        }
      }
    );

    db.query(
      'SELECT user_id, full_name, email FROM users WHERE is_admin = TRUE',
      (err2, admins) => {
        if (err2) console.error('[Emergency] Admin fetch error:', err2.message);

        const adminList = admins || [];
        const adminNotificationBody =
          `${user.full_name} triggered SOS! ` +
          `Phone: ${user.phone_number || 'N/A'}` +
          (tripName ? ` | Trip: ${tripName}` : '') +
          ` | Location: ${locationLabel}`;

        const emailPayload = {
          userName:  user.full_name,
          userPhone: user.phone_number || 'N/A',
          userEmail: user.email,
          tripName,
          latitude:  lat,
          longitude: lng,
          alertId,
          message:   msg,
          timestamp,
        };

        for (const admin of adminList) {
          _notify(
            admin.user_id,
            `🚨 Emergency SOS — ${user.full_name}`,
            adminNotificationBody,
            'emergency_sos_admin',
            `/admin/emergency/${alertId}`
          );
          sendEmergencyAlertEmail({ toEmail: admin.email, toName: admin.full_name, ...emailPayload });
        }

        const envEmail = process.env.ADMIN_EMAIL;
        if (envEmail && !adminList.some(a => a.email === envEmail)) {
          sendEmergencyAlertEmail({ toEmail: envEmail, toName: 'SafarSync Admin', ...emailPayload });
        }
      }
    );
  });
};

const triggerSOS = (req, res) => {
  const userId = req.user.userId;
  const { latitude = 0, longitude = 0, message, trip_id, trip_type } = req.body;

  EmergencyAlert.trigger(userId, trip_id, trip_type, latitude, longitude, message, (err, result) => {
    if (err) {
      console.error('SOS trigger error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }

    const alertId = result.insertId;


    res.status(201).json({
      success: true,
      alert_id: alertId,
      message: 'SOS activated — emergency contacts notified',
    });

    _dispatchEmergencyNotifications(alertId, userId, latitude, longitude, message, trip_id, trip_type);
  });
};

const resolveSOS = (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  EmergencyAlert.updateStatus(id, userId, 'Resolved', (err, result) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Alert not found' });
    }

    if (global.io) {
      global.io.to('emergency:admin').emit('emergency:resolved', {
        alert_id: parseInt(id),
        user_id: userId,
        timestamp: new Date().toISOString(),
      });
    }

    _notify(
      userId,
      '✅ Emergency Resolved',
      'Your emergency alert has been marked as resolved. Stay safe.',
      'emergency_resolved',
      `/emergency/${id}`
    );

    res.json({ success: true, message: 'Emergency resolved' });
  });
};

const cancelSOS = (req, res) => {
  const userId = req.user.userId;
  const { id } = req.params;

  EmergencyAlert.updateStatus(id, userId, 'Cancelled', (err, result) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Alert not found' });
    }
    res.json({ success: true, message: 'Emergency cancelled' });
  });
};

const getMyAlerts = (req, res) => {
  const userId = req.user.userId;
  EmergencyAlert.getByUser(userId, 20, (err, alerts) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alerts: alerts || [] });
  });
};

const getActiveAlert = (req, res) => {
  const userId = req.user.userId;
  EmergencyAlert.getActiveByUser(userId, (err, alert) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alert: alert || null });
  });
};

const getAllAlerts = (req, res) => {
  EmergencyAlert.getAll(50, (err, alerts) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alerts: alerts || [] });
  });
};

const VALID_EVENT_TYPES = ['ambulance', 'police', 'tourist_police', 'ice_share', 'full_sos'];

const logEmergencyEvent = (req, res) => {
  const userId = req.user.userId;
  const { type, latitude = 0, longitude = 0 } = req.body;

  if (!VALID_EVENT_TYPES.includes(type)) {
    return res.status(400).json({ success: false, message: 'Invalid event type' });
  }

  db.query(
    'INSERT INTO emergency_events (user_id, type, latitude, longitude) VALUES (?, ?, ?, ?)',
    [userId, type, latitude, longitude],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: err.message });

      res.status(201).json({ success: true, event_id: result.insertId });

      db.query(
        'SELECT full_name, phone_number FROM users WHERE user_id = ?',
        [userId],
        (_, rows) => {
          const user = rows?.[0] || {};
          if (global.io) {
            global.io.to('emergency:admin').emit('emergency:event', {
              event_id:   result.insertId,
              user_id:    userId,
              user_name:  user.full_name  || 'Unknown',
              user_phone: user.phone_number || 'N/A',
              type,
              latitude,
              longitude,
              timestamp: new Date().toISOString(),
            });
          }
        }
      );
    }
  );
};

const pushTrackingPoint = (req, res) => {
  const userId = req.user.userId;
  const { emergency_id, latitude, longitude } = req.body;

  if (!emergency_id || latitude === undefined || longitude === undefined) {
    return res.status(400).json({ success: false, message: 'emergency_id, latitude, longitude are required' });
  }

  db.query(
    'SELECT id FROM emergency_alerts WHERE id = ? AND user_id = ? AND status = "Active"',
    [emergency_id, userId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      if (!rows?.length) return res.status(404).json({ success: false, message: 'Active emergency not found' });

      db.query(
        'INSERT INTO emergency_tracking (emergency_id, latitude, longitude) VALUES (?, ?, ?)',
        [emergency_id, latitude, longitude],
        (err2, result) => {
          if (err2) return res.status(500).json({ success: false, message: err2.message });

          if (global.io) {
            global.io.to('emergency:admin').emit('emergency:tracking', {
              emergency_id,
              user_id: userId,
              latitude,
              longitude,
              timestamp: new Date().toISOString(),
            });
          }

          res.json({ success: true, tracking_id: result.insertId });
        }
      );
    }
  );
};

const getTrackingHistory = (req, res) => {
  const { id } = req.params;
  db.query(
    'SELECT id, latitude, longitude, timestamp FROM emergency_tracking WHERE emergency_id = ? ORDER BY timestamp ASC',
    [id],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      res.json({ success: true, points: rows || [] });
    }
  );
};

const acknowledgeEmergency = (req, res) => {
  const { id } = req.params;
  db.query(
    'UPDATE emergency_alerts SET status = "Acknowledged" WHERE id = ? AND status = "Active"',
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      if (global.io) {
        global.io.to('emergency:admin').emit('emergency:acknowledged', {
          alert_id:  parseInt(id),
          timestamp: new Date().toISOString(),
        });
      }
      res.json({ success: true, affected: result.affectedRows });
    }
  );
};

const getAllEvents = (req, res) => {
  db.query(
    `SELECT ee.*, u.full_name, u.phone_number
     FROM emergency_events ee
     JOIN users u ON ee.user_id = u.user_id
     ORDER BY ee.created_at DESC
     LIMIT 100`,
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: err.message });
      res.json({ success: true, events: rows || [] });
    }
  );
};

module.exports = {
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
};
