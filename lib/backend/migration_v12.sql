-- migration_v12: Fix virtual_tours schema conflict + add AI tables
-- Run after migration_v11.sql

USE safarsync;

-- ─── Fix virtual_tours PK column name (v2 used tour_id, v8 uses id) ───────────

DROP PROCEDURE IF EXISTS _safarsync_v12_fix_vt;
DELIMITER //
CREATE PROCEDURE _safarsync_v12_fix_vt()
BEGIN
  -- Rename tour_id → id if still on v2 schema
  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'virtual_tours' AND COLUMN_NAME = 'tour_id'
  ) THEN
    ALTER TABLE virtual_tours CHANGE tour_id id INT NOT NULL AUTO_INCREMENT;
  END IF;

  -- Drop v2-only columns if they exist
  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'virtual_tours' AND COLUMN_NAME = 'tour_url'
  ) THEN
    ALTER TABLE virtual_tours DROP COLUMN tour_url;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'virtual_tours' AND COLUMN_NAME = 'tour_type'
  ) THEN
    ALTER TABLE virtual_tours DROP COLUMN tour_type;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'virtual_tours' AND COLUMN_NAME = 'duration_minutes'
  ) THEN
    ALTER TABLE virtual_tours DROP COLUMN duration_minutes;
  END IF;

  -- Ensure is_active column exists (v8 schema requires it)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'virtual_tours' AND COLUMN_NAME = 'is_active'
  ) THEN
    ALTER TABLE virtual_tours ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
  END IF;
END //
DELIMITER ;
CALL _safarsync_v12_fix_vt();
DROP PROCEDURE IF EXISTS _safarsync_v12_fix_vt;

-- ─── AI Chat History ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_chat_history (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  user_message TEXT NOT NULL,
  ai_response  TEXT NOT NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ai_chat_user (user_id, created_at),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── AI Recommendations ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_recommendations (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  user_id          INT NOT NULL,
  destination_id   INT,
  title            VARCHAR(255) NOT NULL,
  description      TEXT,
  confidence_score FLOAT DEFAULT 0.0,
  category         VARCHAR(100),
  viewed           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ai_rec_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
