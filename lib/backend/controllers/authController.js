const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { verifyFirebaseToken } = require('../config/firebaseAdmin');

const _signJwt = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });

const exchangeFirebaseToken = async (req, res) => {
  const { firebase_id_token, phone_number, blood_group } = req.body;

  if (!firebase_id_token) {
    return res.status(400).json({ error: 'firebase_id_token is required' });
  }

  let firebaseUser;
  try {
    firebaseUser = await verifyFirebaseToken(firebase_id_token);
  } catch (err) {
    console.error('[Auth] Firebase token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Firebase token' });
  }

  const { uid, email, name } = firebaseUser;

  db.query(
    'SELECT user_id, full_name, email, is_admin FROM users WHERE firebase_uid = ? OR email = ? LIMIT 1',
    [uid, email],
    (err, rows) => {
      if (err) {
        console.error('[Auth] DB lookup error:', err.message);
        return res.status(500).json({ error: 'Database error' });
      }

      if (rows && rows.length > 0) {
        const user = rows[0];
        db.query(
          'UPDATE users SET firebase_uid = ?, updated_at = NOW() WHERE user_id = ?',
          [uid, user.user_id],
          () => {}
        );

        const token = _signJwt({
          userId: user.user_id,
          email: user.email,
          name: user.full_name,
          isAdmin: !!user.is_admin,
        });

        return res.json({
          success: true,
          token,
          user: {
            user_id: user.user_id,
            email: user.email,
            full_name: user.full_name,
            is_admin: !!user.is_admin,
          },
        });
      }

      const insertQuery = `
        INSERT INTO users (firebase_uid, email, full_name, phone_number, blood_group, password_hash, is_active, is_admin)
        VALUES (?, ?, ?, ?, ?, '', TRUE, FALSE)
      `;
      db.query(
        insertQuery,
        [uid, email, name || email.split('@')[0], phone_number || null, blood_group || null],
        (err2, result) => {
          if (err2) {
            console.error('[Auth] User insert error:', err2.message);
            return res.status(500).json({ error: 'Failed to create user' });
          }

          const newUserId = result.insertId;
          const token = _signJwt({
            userId: newUserId,
            email,
            name: name || email.split('@')[0],
            isAdmin: false,
          });

          return res.status(201).json({
            success: true,
            token,
            user: {
              user_id: newUserId,
              email,
              full_name: name || email.split('@')[0],
              is_admin: false,
            },
          });
        }
      );
    }
  );
};

const loginUser = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  db.query('SELECT * FROM Traveler WHERE email = ?', [email], async (err, results) => {
    if (err) return res.status(500).json({ error: 'Internal server error' });
    if (results.length === 0) return res.status(404).json({ message: 'No user found with this email' });

    const user = results[0];
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

    const token = _signJwt({ userId: user.userId, email: user.email, name: user.name });
    res.json({ token });
  });
};

const registerUser = async (req, res) => {
  const { email, password, name, phoneNumber, bloodGroup } = req.body;

  if (!email || !password || !name) {
    return res.status(400).json({ message: 'Email, password, and name are required' });
  }

  db.query('SELECT * FROM Traveler WHERE email = ?', [email], async (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length > 0) return res.status(400).json({ message: 'User already exists' });

    const hashedPassword = await bcrypt.hash(password, 10);
    db.query(
      'INSERT INTO Traveler (email, passwordHash, name, phoneNumber, bloodGroup) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, name, phoneNumber, bloodGroup],
      (err) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.status(201).json({ message: 'User registered successfully' });
      }
    );
  });
};

const getMe = (req, res) => {
  const userId = req.user.userId;
  db.query(
    'SELECT user_id, email, full_name, phone_number, profile_picture_url, blood_group, bio, is_admin, created_at FROM users WHERE user_id = ?',
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(404).json({ error: 'User not found' });
      res.json({ success: true, user: rows[0] });
    }
  );
};

module.exports = { loginUser, registerUser, exchangeFirebaseToken, getMe };
