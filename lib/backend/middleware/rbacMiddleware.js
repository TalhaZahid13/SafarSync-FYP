const requireRole = (...allowedRoles) =>
  (req, res, next) => {
    const role = req.user?.role;
    if (!role || !allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        error: `This action requires one of these roles: ${allowedRoles.join(', ')}`,
      });
    }
    next();
  };

module.exports = { requireRole };
