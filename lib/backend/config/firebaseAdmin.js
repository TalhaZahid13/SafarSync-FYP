const admin = require('firebase-admin');

let _devMode = false;

const initFirebaseAdmin = () => {
  if (admin.getApps().length > 0) return;

  try {
    const keyEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    if (keyEnv && keyEnv.trim()) {
      const serviceAccount = JSON.parse(
        keyEnv.startsWith('{') ? keyEnv : Buffer.from(keyEnv, 'base64').toString('utf8')
      );
      admin.initializeApp({ credential: admin.cert(serviceAccount) });
      console.log('[Firebase Admin] Initialized with service account');
    } else {
      _devMode = true;
      console.warn('[Firebase Admin] No service account key. Running in DEV mode (tokens not verified).');
    }
  } catch (e) {
    _devMode = true;
    console.error('[Firebase Admin] Init error, falling back to DEV mode:', e.message);
  }
};

const verifyFirebaseToken = async (idToken) => {
  if (_devMode || admin.getApps().length === 0) {
    const parts = idToken.split('.');
    if (parts.length !== 3) throw new Error('Invalid ID token format');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    return {
      uid:      payload.user_id || payload.sub,
      email:    payload.email   || '',
      name:     payload.name    || '',
      picture:  payload.picture || null,
      provider: payload.firebase?.sign_in_provider || 'password',
    };
  }

  const { getAuth } = require('firebase-admin/auth');
  const decoded = await getAuth().verifyIdToken(idToken);
  return {
    uid:      decoded.uid,
    email:    decoded.email || '',
    name:     decoded.name  || decoded.displayName || '',
    picture:  decoded.picture || null,
    provider: decoded.firebase?.sign_in_provider || 'password',
  };
};

// Delete a Firebase Auth user by UID (used during account deletion)
const deleteFirebaseUser = async (uid) => {
  if (!uid) return;
  try {
    if (_devMode || admin.getApps().length === 0) {
      console.warn('[Firebase Admin] DEV mode — skipping Firebase user deletion for uid:', uid);
      return;
    }
    const { getAuth } = require('firebase-admin/auth');
    await getAuth().deleteUser(uid);
    console.log('[Firebase Admin] Deleted Firebase user:', uid);
  } catch (err) {
    console.error('[Firebase Admin] Failed to delete Firebase user:', uid, err.message);
  }
};

// Update Firebase Auth display name / photo URL (used during profile update)
const updateFirebaseUser = async (uid, { displayName, photoURL } = {}) => {
  if (!uid) return;
  try {
    if (_devMode || admin.getApps().length === 0) return;
    const { getAuth } = require('firebase-admin/auth');
    const updates = {};
    if (displayName !== undefined && displayName !== null) updates.displayName = displayName;
    if (photoURL    !== undefined && photoURL    !== null) updates.photoURL    = photoURL;
    if (Object.keys(updates).length > 0) await getAuth().updateUser(uid, updates);
  } catch (err) {
    console.error('[Firebase Admin] Failed to update Firebase user:', uid, err.message);
  }
};

module.exports = { initFirebaseAdmin, verifyFirebaseToken, deleteFirebaseUser, updateFirebaseUser };
