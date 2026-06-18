const db = require('../config/db');

/**
 * Must be used AFTER authenticate middleware.
 *
 * Accepts two paths:
 *   1. Admin-table JWT  — req.user.type === 'admin' && req.user.adminId present
 *   2. User-table flag  — req.user.userId AND is_admin = 1 in the users table
 */
const adminOnly = (req, res, next) => {
  // Path 1: Pure admin JWT issued by /api/admin/auth/login
  if (req.user?.type === 'admin' && req.user?.adminId) {
    req.user.isAdmin = true;
    return next();
  }

  // Path 2: Regular user JWT where the users row has is_admin = 1
  const userId = req.user?.userId;
  if (!userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  db.query(
    'SELECT is_admin FROM users WHERE user_id = ? LIMIT 1',
    [userId],
    (err, rows) => {
      if (err) {
        console.error('[Admin middleware] DB error:', err.message);
        return res.status(500).json({ error: 'Authorization check failed' });
      }
      if (!rows || rows.length === 0) {
        return res.status(403).json({ error: 'Access denied: user not found' });
      }
      if (!rows[0].is_admin) {
        return res.status(403).json({ error: 'Access denied: admin privileges required' });
      }
      req.user.isAdmin = true;
      next();
    }
  );
};

module.exports = { adminOnly };
