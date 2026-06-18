-- SafarSync v3 Migration — Separate Admin Authentication
-- Run against the safarsync database. All statements are idempotent.

USE safarsync;

-- ─── 1. admins table (completely separate from users) ────────────────────────
CREATE TABLE IF NOT EXISTS admins (
  admin_id      INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,
  full_name     VARCHAR(255)  NOT NULL,
  role          ENUM('super_admin', 'moderator') NOT NULL DEFAULT 'moderator',
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  last_login    DATETIME      NULL,
  reset_otp     VARCHAR(255)  NULL,
  reset_otp_expires DATETIME  NULL,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 2. To create the first admin account run the Node script below:
-- (or use the POST /api/admin/auth/signup endpoint with ADMIN_SETUP_KEY)
-- node -e "
--   const bcrypt = require('bcryptjs');
--   const hash = bcrypt.hashSync('YourPassword123!', 12);
--   console.log('INSERT INTO admins (email,password_hash,full_name,role) VALUES (\'admin@safarsync.com\',\'' + hash + '\',\'SafarSync Admin\',\'super_admin\');');
-- "
