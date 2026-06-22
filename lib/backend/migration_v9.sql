-- Migration v9: Advanced SOS system tables
-- Run after migration_v8.sql

-- Emergency Events: logs individual emergency actions (calls, ICE shares) separately from full SOS alerts
CREATE TABLE IF NOT EXISTS emergency_events (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  user_id         INT NOT NULL,
  type            ENUM('ambulance','police','tourist_police','ice_share','full_sos') NOT NULL,
  latitude        DECIMAL(10,8) DEFAULT NULL,
  longitude       DECIMAL(11,8) DEFAULT NULL,
  status          ENUM('Pending','Acknowledged') NOT NULL DEFAULT 'Pending',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ee_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ee_user_id ON emergency_events (user_id);
CREATE INDEX IF NOT EXISTS idx_ee_created  ON emergency_events (created_at DESC);

-- Emergency Tracking: live GPS breadcrumbs for active full-SOS alerts
CREATE TABLE IF NOT EXISTS emergency_tracking (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  emergency_id  INT NOT NULL,
  latitude      DECIMAL(10,8) NOT NULL,
  longitude     DECIMAL(11,8) NOT NULL,
  timestamp     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_et_alert FOREIGN KEY (emergency_id) REFERENCES emergency_alerts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_et_emergency ON emergency_tracking (emergency_id);
CREATE INDEX IF NOT EXISTS idx_et_timestamp  ON emergency_tracking (timestamp);
