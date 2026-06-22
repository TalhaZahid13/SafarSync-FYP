const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');

const SETUP_KEY = process.env.ADMIN_SETUP_KEY || 'safarsync_admin_setup_2024';

const _sign = (payload) =>
  jwt.sign({ ...payload, type: 'admin' }, process.env.JWT_SECRET, { expiresIn: '7d' });
const adminLogin = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  db.query(
    'SELECT * FROM admins WHERE email = ? AND is_active = 1 LIMIT 1',
    [email],
    async (err, rows) => {
      if (err) {
        console.error('[AdminAuth] DB error:', err.message);
        return res.status(500).json({ error: 'Database error' });
      }
      if (!rows || rows.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const admin = rows[0];
      const isMatch = await bcrypt.compare(password, admin.password_hash);
      if (!isMatch) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      db.query('UPDATE admins SET last_login = NOW() WHERE admin_id = ?', [admin.admin_id], () => {});

      const token = _sign({
        adminId: admin.admin_id,
        email: admin.email,
        name: admin.full_name,
        role: admin.role,
        isAdmin: true,
      });

      return res.json({
        success: true,
        token,
        admin: {
          admin_id: admin.admin_id,
          email: admin.email,
          full_name: admin.full_name,
          role: admin.role,
        },
      });
    }
  );
};

const adminSignup = async (req, res) => {
  const { email, password, full_name, role = 'moderator', setup_key } = req.body;

  if (setup_key !== SETUP_KEY) {
    return res.status(403).json({ error: 'Invalid setup key' });
  }
  if (!email || !password || !full_name) {
    return res.status(400).json({ error: 'email, password, and full_name are required' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  db.query('SELECT admin_id FROM admins WHERE email = ? LIMIT 1', [email], async (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows && rows.length > 0) {
      return res.status(409).json({ error: 'An admin with this email already exists' });
    }

    const hash = await bcrypt.hash(password, 12);
    db.query(
      'INSERT INTO admins (email, password_hash, full_name, role) VALUES (?, ?, ?, ?)',
      [email, hash, full_name, role],
      (err2, result) => {
        if (err2) {
          console.error('[AdminAuth] Insert error:', err2.message);
          return res.status(500).json({ error: 'Failed to create admin account' });
        }
        return res.status(201).json({
          success: true,
          admin_id: result.insertId,
          message: 'Admin account created successfully',
        });
      }
    );
  });
};

const adminForgotPassword = (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  db.query(
    'SELECT admin_id, full_name FROM admins WHERE email = ? AND is_active = 1 LIMIT 1',
    [email],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });

      const respond = () =>
        res.json({ success: true, message: 'If that email is registered, a reset code has been sent.' });

      if (!rows || rows.length === 0) return respond();

      const admin = rows[0];
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
      const expires = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

      db.query(
        'UPDATE admins SET reset_otp = ?, reset_otp_expires = ? WHERE admin_id = ?',
        [otpHash, expires, admin.admin_id],
        (updateErr) => {
          if (updateErr) return respond(); 
          try {
            const { sendAdminOtpEmail } = require('../services/emailService');
            sendAdminOtpEmail({
              toEmail: email,
              toName: admin.full_name,
              otp,
            }).catch(console.error);
          } catch (_) {}

          respond();
        }
      );
    }
  );
};

const adminResetPassword = async (req, res) => {
  const { email, otp, new_password } = req.body;
  if (!email || !otp || !new_password) {
    return res.status(400).json({ error: 'email, otp, and new_password are required' });
  }
  if (new_password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  const otpHash = crypto.createHash('sha256').update(otp).digest('hex');

  db.query(
    'SELECT admin_id FROM admins WHERE email = ? AND reset_otp = ? AND reset_otp_expires > NOW() AND is_active = 1 LIMIT 1',
    [email, otpHash],
    async (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) {
        return res.status(400).json({ error: 'Invalid or expired reset code' });
      }

      const hash = await bcrypt.hash(new_password, 12);
      db.query(
        'UPDATE admins SET password_hash = ?, reset_otp = NULL, reset_otp_expires = NULL WHERE admin_id = ?',
        [hash, rows[0].admin_id],
        (updateErr) => {
          if (updateErr) return res.status(500).json({ error: 'Failed to update password' });
          return res.json({ success: true, message: 'Password updated successfully' });
        }
      );
    }
  );
};

const adminGetMe = (req, res) => {
  const adminId = req.user?.adminId;
  if (!adminId) return res.status(401).json({ error: 'Admin authentication required' });

  db.query(
    'SELECT admin_id, email, full_name, role, last_login, created_at FROM admins WHERE admin_id = ? AND is_active = 1 LIMIT 1',
    [adminId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(404).json({ error: 'Admin not found' });
      return res.json({ success: true, admin: rows[0] });
    }
  );
};

module.exports = { adminLogin, adminSignup, adminForgotPassword, adminResetPassword, adminGetMe };
