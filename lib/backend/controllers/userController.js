const db = require('../config/db');
const bcrypt = require('bcryptjs');


const getProfile = (req, res) => {
  const userId = req.user.userId;
  const query = `
    SELECT u.user_id, u.email, u.full_name, u.phone_number,
           u.profile_picture_url, u.blood_group, u.bio, u.created_at, u.is_admin,
           (SELECT COUNT(*) FROM bookings WHERE user_id = u.user_id) AS total_bookings,
           (SELECT COUNT(*) FROM group_booking_members WHERE user_id = u.user_id) AS group_trips,
           (SELECT COUNT(*) FROM wishlists WHERE user_id = u.user_id) AS wishlist_count,
           (SELECT COUNT(*) FROM emergency_alerts WHERE user_id = u.user_id AND status = 'Active') AS active_sos
    FROM users u
    WHERE u.user_id = ?
  `;
  db.query(query, [userId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!rows || rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json({ success: true, user: rows[0] });
  });
};

// ─── PUT /api/users/profile ───────────────────────────────────────────────────
const updateProfile = (req, res) => {
  const userId = req.user.userId;
  const { full_name, phone_number, blood_group, bio, profile_picture_url } = req.body;

  const fields = [];
  const values = [];

  if (full_name !== undefined) { fields.push('full_name = ?'); values.push(full_name); }
  if (phone_number !== undefined) { fields.push('phone_number = ?'); values.push(phone_number); }
  if (blood_group !== undefined) { fields.push('blood_group = ?'); values.push(blood_group); }
  if (bio !== undefined) { fields.push('bio = ?'); values.push(bio); }
  if (profile_picture_url !== undefined) { fields.push('profile_picture_url = ?'); values.push(profile_picture_url); }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }

  fields.push('updated_at = NOW()');
  values.push(userId);

  db.query(
    `UPDATE users SET ${fields.join(', ')} WHERE user_id = ?`,
    values,
    (err) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json({ success: true, message: 'Profile updated' });
    }
  );
};

// ─── GET /api/users/stats ─────────────────────────────────────────────────────
const getStats = (req, res) => {
  const userId = req.user.userId;
  const query = `
    SELECT
      (SELECT COUNT(*) FROM bookings WHERE user_id = ?) AS total_bookings,
      (SELECT COUNT(*) FROM bookings WHERE user_id = ? AND status = 'Completed') AS completed_trips,
      (SELECT COUNT(*) FROM group_booking_members WHERE user_id = ?) AS group_trips,
      (SELECT COUNT(*) FROM wishlists WHERE user_id = ?) AS wishlist_count,
      (SELECT COUNT(*) FROM emergency_alerts WHERE user_id = ?) AS total_sos,
      (SELECT COUNT(*) FROM ai_chat_history WHERE user_id = ?) AS ai_chats
  `;
  db.query(query, [userId, userId, userId, userId, userId, userId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ success: true, stats: rows[0] || {} });
  });
};

// ─── GET /api/users/preferences ──────────────────────────────────────────────
const getPreferences = (req, res) => {
  const userId = req.user.userId;
  db.query(
    'SELECT * FROM user_preferences WHERE user_id = ?',
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) {
        return res.json({ success: true, preferences: {
          language: 'en', theme: 'dark', notifications_enabled: true,
          weather_alerts: true, traffic_alerts: true, emergency_sharing_enabled: true,
        }});
      }
      const pref = rows[0];
      if (typeof pref.preferred_categories === 'string') {
        try { pref.preferred_categories = JSON.parse(pref.preferred_categories); } catch (_) {}
      }
      res.json({ success: true, preferences: pref });
    }
  );
};

// ─── PUT /api/users/preferences ──────────────────────────────────────────────
const updatePreferences = (req, res) => {
  const userId = req.user.userId;
  const {
    language, theme, notifications_enabled, weather_alerts,
    traffic_alerts, emergency_sharing_enabled, preferred_categories,
  } = req.body;

  const query = `
    INSERT INTO user_preferences
      (user_id, language, theme, notifications_enabled, weather_alerts,
       traffic_alerts, emergency_sharing_enabled, preferred_categories)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      language = VALUES(language), theme = VALUES(theme),
      notifications_enabled = VALUES(notifications_enabled),
      weather_alerts = VALUES(weather_alerts),
      traffic_alerts = VALUES(traffic_alerts),
      emergency_sharing_enabled = VALUES(emergency_sharing_enabled),
      preferred_categories = VALUES(preferred_categories),
      updated_at = NOW()
  `;
  db.query(query, [
    userId, language, theme, notifications_enabled, weather_alerts,
    traffic_alerts, emergency_sharing_enabled,
    preferred_categories ? JSON.stringify(preferred_categories) : null,
  ], (err) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ success: true, message: 'Preferences updated' });
  });
};

// ─── GET /api/users/search?email=xxx ─────────────────────────────────────────
const searchByEmail = (req, res) => {
  const { email } = req.query;
  if (!email) return res.status(400).json({ error: 'email query parameter required' });

  db.query(
    'SELECT user_id, full_name, email, profile_picture_url FROM users WHERE email = ? AND is_blocked = FALSE LIMIT 1',
    [email],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(404).json({ error: 'User not found' });
      res.json({ success: true, user: rows[0] });
    }
  );
};

// ─── PUT /api/users/change-password ──────────────────────────────────────────
const changePassword = async (req, res) => {
  const userId = req.user.userId;
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).json({ error: 'current_password and new_password are required' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  db.query('SELECT password_hash FROM users WHERE user_id = ?', [userId], async (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!rows || rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const hash = rows[0].password_hash;
    if (hash) {
      const valid = await bcrypt.compare(current_password, hash);
      if (!valid) return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const newHash = await bcrypt.hash(new_password, 10);
    db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [newHash, userId], (err2) => {
      if (err2) return res.status(500).json({ error: 'Database error' });
      res.json({ success: true, message: 'Password changed' });
    });
  });
};

// ─── DELETE /api/users/account ────────────────────────────────────────────────
const deleteAccount = (req, res) => {
  const userId = req.user.userId;
  db.query('DELETE FROM users WHERE user_id = ?', [userId], (err) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ success: true, message: 'Account deleted' });
  });
};

const VALID_THEMES = ['default', 'snow', 'desert', 'beach', 'mountain', 'forest', 'urban'];

const updateThemePreference = (req, res) => {
  const userId = req.user.userId;
  const { theme_preference } = req.body;
  if (!VALID_THEMES.includes(theme_preference)) {
    return res.status(400).json({ error: 'Invalid theme_preference' });
  }
  db.query(
    'UPDATE users SET theme_preference = ? WHERE user_id = ?',
    [theme_preference, userId],
    (err) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json({ success: true, theme_preference });
    },
  );
};

module.exports = {
  getProfile,
  updateProfile,
  getStats,
  getPreferences,
  updatePreferences,
  searchByEmail,
  changePassword,
  deleteAccount,
  updateThemePreference,
};
