-- SafarSync v2 Migration
-- Run this against your existing safarsync database.
-- All statements are idempotent (safe to run multiple times).

USE safarsync;

-- ─── 1. users table: add missing columns ─────────────────────────────────────
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS firebase_uid    VARCHAR(128)  UNIQUE NULL,
  ADD COLUMN IF NOT EXISTS is_admin        TINYINT(1)    NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_blocked      TINYINT(1)    NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS bio             TEXT          NULL,
  ADD COLUMN IF NOT EXISTS blood_group     VARCHAR(10)   NULL,
  ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users (firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email        ON users (email);

-- ─── 2. emergency_contacts: add contact_email ────────────────────────────────
ALTER TABLE emergency_contacts
  ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255) NULL;

-- ─── 3. user_preferences: ensure updated_at and unique key ───────────────────
ALTER TABLE user_preferences
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP;

-- Ensure there's a unique constraint on user_id so ON DUPLICATE KEY UPDATE works
ALTER TABLE user_preferences
  ADD CONSTRAINT IF NOT EXISTS uq_user_preferences_user_id UNIQUE (user_id);

-- ─── 4. group_chat_messages (new) ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_chat_messages (
  message_id        INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
  group_booking_id  INT           NOT NULL,
  user_id           INT           NOT NULL,
  message           TEXT          NOT NULL,
  message_type      ENUM('text','image','location','system') NOT NULL DEFAULT 'text',
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_gcm_group (group_booking_id, created_at),
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)          REFERENCES users(user_id)                   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 5. virtual_tours (new) ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS virtual_tours (
  tour_id          INT            NOT NULL AUTO_INCREMENT PRIMARY KEY,
  destination_id   INT            NULL,
  title            VARCHAR(255)   NOT NULL,
  description      TEXT           NULL,
  thumbnail_url    VARCHAR(500)   NULL,
  tour_url         VARCHAR(500)   NULL,
  tour_type        ENUM('360','video','ar','vr') NOT NULL DEFAULT 'video',
  duration_minutes INT            NULL,
  is_active        TINYINT(1)     NOT NULL DEFAULT 1,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 6. sasta_tours (new) ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sasta_tours (
  package_id       INT            NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title            VARCHAR(255)   NOT NULL,
  description      TEXT           NULL,
  destination_name VARCHAR(255)   NOT NULL,
  price_pkr        DECIMAL(10,2)  NOT NULL DEFAULT 0,
  duration_days    INT            NOT NULL DEFAULT 1,
  max_persons      INT            NOT NULL DEFAULT 1,
  included_items   JSON           NULL,
  thumbnail_url    VARCHAR(500)   NULL,
  departure_city   VARCHAR(100)   NULL,
  is_active        TINYINT(1)     NOT NULL DEFAULT 1,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sasta_price (price_pkr)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 7. mental_health_chat_history (new) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS mental_health_chat_history (
  id              INT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id         INT      NOT NULL,
  user_message    TEXT     NOT NULL,
  ai_response     TEXT     NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_mhch_user (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 8. admin_logs (new) ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_logs (
  log_id      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  admin_id    INT          NOT NULL,
  action      VARCHAR(100) NOT NULL,
  target_type VARCHAR(50)  NULL,
  target_id   INT          NULL,
  details     JSON         NULL,
  ip_address  VARCHAR(45)  NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_admin_logs_admin (admin_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── 9. notifications: ensure type column exists ─────────────────────────────
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'general';

-- ─── 10. Seed: promote first user to admin for initial setup ─────────────────
-- Uncomment and edit the email below to promote your admin account:
-- UPDATE users SET is_admin = 1 WHERE email = 'admin@example.com' LIMIT 1;
