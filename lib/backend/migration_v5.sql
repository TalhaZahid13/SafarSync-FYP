-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║           SafarSync  —  Migration V5  (Admin Control Center)        ║
-- ║   Run AFTER migration_v4.sql                                        ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ── Admin Activity Logs ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_activity_logs (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  admin_id      INT          NOT NULL,
  admin_name    VARCHAR(255) NOT NULL DEFAULT '',
  action        VARCHAR(100) NOT NULL,
  target_type   VARCHAR(50)  DEFAULT NULL,
  target_id     INT          DEFAULT NULL,
  details       TEXT         DEFAULT NULL,
  ip_address    VARCHAR(45)  DEFAULT NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_aal_admin    (admin_id),
  INDEX idx_aal_created  (created_at),
  INDEX idx_aal_action   (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── User — suspend + last login ────────────────────────────────────────────────
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS suspended_at     TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS suspended_reason VARCHAR(500) NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS last_login_at    TIMESTAMP NULL DEFAULT NULL;

-- ── Emergency Alerts — full workflow ──────────────────────────────────────────
ALTER TABLE emergency_alerts
  ADD COLUMN IF NOT EXISTS workflow_status   ENUM('New','Acknowledged','In Progress','Resolved')
                                             NOT NULL DEFAULT 'New',
  ADD COLUMN IF NOT EXISTS resolution_notes  TEXT NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS acknowledged_at   TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS in_progress_at    TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS assigned_admin_id INT NULL DEFAULT NULL;

-- Back-fill existing 'Active' alerts to workflow_status = 'New'
UPDATE emergency_alerts
SET workflow_status = 'New'
WHERE workflow_status = 'New' AND status = 'Active';

-- Back-fill existing 'Resolved' alerts
UPDATE emergency_alerts
SET workflow_status = 'Resolved'
WHERE status = 'Resolved' AND workflow_status = 'New';

-- ── SOS Alerts — workflow (mirrors emergency_alerts) ──────────────────────────
ALTER TABLE sos_alerts
  ADD COLUMN IF NOT EXISTS workflow_status  ENUM('New','Acknowledged','In Progress','Resolved')
                                            NOT NULL DEFAULT 'New',
  ADD COLUMN IF NOT EXISTS resolution_notes TEXT NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS assigned_admin_id INT NULL DEFAULT NULL;

-- ── Payments — refund request tracking ────────────────────────────────────────
ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS refund_requested_at TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_approved_at  TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_rejected_at  TIMESTAMP NULL DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS refund_admin_notes  VARCHAR(500) NULL DEFAULT NULL;

-- ── Ensure payments.group_booking_id column ───────────────────────────────────
ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS group_booking_id INT NULL DEFAULT NULL;

-- ── Destinations — ensure average_cost column exists ─────────────────────────
ALTER TABLE destinations
  ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10,2) NULL DEFAULT NULL;
