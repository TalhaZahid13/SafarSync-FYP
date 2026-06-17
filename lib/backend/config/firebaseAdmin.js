const admin = require('firebase-admin');

let _devMode = false;

const initFirebaseAdmin = () => {
  if (admin.getApps().length > 0) return; // already initialized

  try {
    const keyEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    if (keyEnv && keyEnv.trim()) {
      const serviceAccount = JSON.parse(
        keyEnv.startsWith('{') ? keyEnv : Buffer.from(keyEnv, 'base64').toString('utf8')
      );
      admin.initializeApp({ credential: admin.cert(serviceAccount) });
      console.log('[Firebase Admin] Initialized with service account');
    } else {
      // Dev-mode: no service account — tokens decoded but NOT verified.
      // Set FIREBASE_SERVICE_ACCOUNT_KEY in .env for production.
      _devMode = true;
      console.warn('[Firebase Admin] No service account key. Running in DEV mode (tokens not verified).');
    }
  } catch (e) {
    _devMode = true;
    console.error('[Firebase Admin] Init error, falling back to DEV mode:', e.message);
  }
};

/**
 * Verify (or decode in DEV mode) a Firebase ID token.
 * Returns { uid, email, name } or throws.
 */
const verifyFirebaseToken = async (idToken) => {
  if (_devMode || admin.getApps().length === 0) {
    // DEV MODE: decode JWT payload without verifying signature
    const parts = idToken.split('.');
    if (parts.length !== 3) throw new Error('Invalid ID token format');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    return {
      uid: payload.user_id || payload.sub,
      email: payload.email || '',
      name: payload.name || '',
    };
  }

  const { getAuth } = require('firebase-admin/auth');
  const decoded = await getAuth().verifyIdToken(idToken);
  return {
    uid: decoded.uid,
    email: decoded.email || '',
    name: decoded.name || decoded.displayName || '',
  };
};

module.exports = { initFirebaseAdmin, verifyFirebaseToken };
