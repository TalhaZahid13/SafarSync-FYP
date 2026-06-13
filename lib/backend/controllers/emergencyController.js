const db = require('../config/db');
const EmergencyAlert = require('../models/emergencyAlert');
const { sendEmergencyAlertEmail, sendEmergencyContactEmail } = require('../services/emailService');

// ─── Shared: insert a notification row + emit socket ─────────────────────────
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

// ─── Async: enrich alert with user context, then fan-out notifications ────────
const _dispatchEmergencyNotifications = (alertId, userId, lat, lng, msg, trip_id, trip_type) => {
  // Step 1: fetch the triggering user's full info + trip name
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

    // Step 2: enriched socket broadcast to admin monitoring room
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
      // Legacy broadcast
      global.io.emit('sos_alert', {
        alert_id: alertId,
        user_id: userId,
        latitude: lat,
        longitude: lng,
        timestamp: new Date().toISOString(),
      });
    }

    // Step 3: self-confirmation notification (in DB for the inbox)
    _notify(
      userId,
      '🚨 SOS Alert Sent',
      'Your emergency alert has been broadcast to all admins. Stay safe — help is coming.',
      'emergency_sos_sent',
      `/emergency/${alertId}`
    );

    // Step 6: email all emergency contacts that have an email address
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

    // Step 4: notify all DB admins
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

        // Per-admin: in-app notification + email
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

        // Step 5: if ADMIN_EMAIL set in .env and not already in DB admins, email it too
        const envEmail = process.env.ADMIN_EMAIL;
        if (envEmail && !adminList.some(a => a.email === envEmail)) {
          sendEmergencyAlertEmail({ toEmail: envEmail, toName: 'SafarSync Admin', ...emailPayload });
        }
      }
    );
  });
};

// ─── POST /api/emergency/trigger ──────────────────────────────────────────────
const triggerSOS = (req, res) => {
  const userId = req.user.userId;
  const { latitude = 0, longitude = 0, message, trip_id, trip_type } = req.body;

  EmergencyAlert.trigger(userId, trip_id, trip_type, latitude, longitude, message, (err, result) => {
    if (err) {
      console.error('SOS trigger error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }

    const alertId = result.insertId;

    // Respond immediately — notifications fire asynchronously
    res.status(201).json({
      success: true,
      alert_id: alertId,
      message: 'SOS activated — emergency contacts notified',
    });

    _dispatchEmergencyNotifications(alertId, userId, latitude, longitude, message, trip_id, trip_type);
  });
};

// ─── PUT /api/emergency/:id/resolve ──────────────────────────────────────────
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

    // Self-notification: alert resolved
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

// ─── PUT /api/emergency/:id/cancel ───────────────────────────────────────────
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

// ─── GET /api/emergency/my-alerts ────────────────────────────────────────────
const getMyAlerts = (req, res) => {
  const userId = req.user.userId;
  EmergencyAlert.getByUser(userId, 20, (err, alerts) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alerts: alerts || [] });
  });
};

// ─── GET /api/emergency/active ───────────────────────────────────────────────
const getActiveAlert = (req, res) => {
  const userId = req.user.userId;
  EmergencyAlert.getActiveByUser(userId, (err, alert) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alert: alert || null });
  });
};

// ─── GET /api/emergency/admin/all ────────────────────────────────────────────
const getAllAlerts = (req, res) => {
  EmergencyAlert.getAll(50, (err, alerts) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    res.json({ success: true, alerts: alerts || [] });
  });
};

module.exports = {
  triggerSOS,
  resolveSOS,
  cancelSOS,
  getMyAlerts,
  getActiveAlert,
  getAllAlerts,
};
