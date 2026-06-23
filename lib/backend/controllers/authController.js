const jwt = require('jsonwebtoken');
const db  = require('../config/db');
const { verifyFirebaseToken } = require('../config/firebaseAdmin');

const _signJwt = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });

// Map Firebase sign_in_provider values → our stored enum
const _mapProvider = (firebaseProvider, clientHint) => {
  if (clientHint) {
    const h = clientHint.toUpperCase();
    if (['EMAIL', 'GOOGLE', 'APPLE', 'FACEBOOK'].includes(h)) return h;
  }
  if (!firebaseProvider) return 'EMAIL';
  if (firebaseProvider === 'password')     return 'EMAIL';
  if (firebaseProvider === 'google.com')   return 'GOOGLE';
  if (firebaseProvider === 'apple.com')    return 'APPLE';
  if (firebaseProvider === 'facebook.com') return 'FACEBOOK';
  return 'EMAIL';
};

// ─── POST /api/auth/firebase-exchange ────────────────────────────────────────
// Called after every Firebase sign-in (Email, Google, Apple).
// Verifies the Firebase ID token, upserts the user in MySQL, returns a JWT.
const exchangeFirebaseToken = async (req, res) => {
  const {
    firebase_id_token,
    phone_number,
    blood_group,
    full_name: bodyName,
    auth_provider: clientProvider,
    profile_picture_url: clientPhoto,
  } = req.body;

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

  const { uid, email, name: fbName, picture: fbPicture, provider: fbProvider } = firebaseUser;
  const authProvider = _mapProvider(fbProvider, clientProvider);
  const displayName  = bodyName || fbName || email.split('@')[0];
  const photoUrl     = clientPhoto || fbPicture || null;

  db.query(
    `SELECT user_id, full_name, email, is_admin, role, firebase_uid, auth_provider, profile_picture_url
     FROM users WHERE firebase_uid = ? OR email = ? LIMIT 1`,
    [uid, email],
    (err, rows) => {
      if (err) {
        console.error('[Auth] DB lookup error:', err.message);
        return res.status(500).json({ error: 'Database error' });
      }

      if (rows && rows.length > 0) {
        // ── Existing user — refresh token fields ────────────────────────
        const user = rows[0];

        const setClauses = [
          'firebase_uid = ?',
          'auth_provider = ?',
          'last_login_at = NOW()',
          'updated_at = NOW()',
        ];
        const vals = [uid, authProvider];

        // For social logins, update profile picture if not already set by the user
        if (photoUrl && authProvider !== 'EMAIL' && !user.profile_picture_url) {
          setClauses.push('profile_picture_url = ?');
          vals.push(photoUrl);
        }

        vals.push(user.user_id);
        db.query(`UPDATE users SET ${setClauses.join(', ')} WHERE user_id = ?`, vals, () => {});

        const token = _signJwt({
          userId:      user.user_id,
          firebaseUid: uid,
          email:       user.email,
          name:        user.full_name,
          role:        user.role || 'user',
          isAdmin:     !!user.is_admin,
        });

        return res.json({
          success: true,
          token,
          user: {
            user_id:             user.user_id,
            email:               user.email,
            full_name:           user.full_name,
            firebase_uid:        uid,
            auth_provider:       authProvider,
            role:                user.role || 'user',
            is_admin:            !!user.is_admin,
            profile_picture_url: user.profile_picture_url || photoUrl || null,
          },
        });
      }

      // ── New user — create MySQL record ─────────────────────────────────
      db.query(
        `INSERT INTO users
           (firebase_uid, email, full_name, phone_number, blood_group,
            password_hash, profile_picture_url, auth_provider, role,
            is_active, is_admin, last_login_at)
         VALUES (?, ?, ?, ?, ?, '', ?, ?, 'user', TRUE, FALSE, NOW())`,
        [uid, email, displayName, phone_number || null, blood_group || null, photoUrl, authProvider],
        (err2, result) => {
          if (err2) {
            console.error('[Auth] User insert error:', err2.message);
            return res.status(500).json({ error: 'Failed to create user' });
          }

          const newUserId = result.insertId;
          const token = _signJwt({
            userId:      newUserId,
            firebaseUid: uid,
            email,
            name:        displayName,
            role:        'user',
            isAdmin:     false,
          });

          return res.status(201).json({
            success: true,
            token,
            user: {
              user_id:             newUserId,
              email,
              full_name:           displayName,
              firebase_uid:        uid,
              auth_provider:       authProvider,
              role:                'user',
              is_admin:            false,
              profile_picture_url: photoUrl,
            },
          });
        }
      );
    }
  );
};

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────
const getMe = (req, res) => {
  db.query(
    `SELECT user_id, email, full_name, phone_number, profile_picture_url,
            blood_group, bio, is_admin, role, auth_provider, firebase_uid,
            theme_preference, created_at, last_login_at
     FROM users WHERE user_id = ?`,
    [req.user.userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (!rows || rows.length === 0) return res.status(404).json({ error: 'User not found' });
      res.json({ success: true, user: rows[0] });
    }
  );
};

// ─── Legacy stubs (Firebase auth replaced these entirely) ────────────────────
const loginUser = (_req, res) =>
  res.status(410).json({ error: 'Use Firebase Authentication + POST /auth/firebase-exchange' });

const registerUser = (_req, res) =>
  res.status(410).json({ error: 'Use Firebase Authentication + POST /auth/firebase-exchange' });

module.exports = { loginUser, registerUser, exchangeFirebaseToken, getMe };
