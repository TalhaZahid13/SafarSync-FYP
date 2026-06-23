-- ============================================================================
-- SafarSync — Missing Tables Only
-- Generated: 2026-06-23
--
-- YOUR EXISTING TABLES (kept untouched):
--   admin, contentmanager, culturalguide, destination, destinations,
--   emergencycontact, emergencyservice, packagestop, poi, recommendation,
--   route, tourpackage, traveler, user_location_updates, wxlocgateway
--
-- THIS FILE: Creates only the tables that are missing and required by the app.
-- 100% safe — no DROP, no ALTER, no data loss.
-- ============================================================================

USE safarsync;

-- ============================================================================
-- 1. USERS
-- (The app's main user table — different from your legacy `traveler` table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  user_id              INT            NOT NULL AUTO_INCREMENT,
  firebase_uid         VARCHAR(128)   NULL UNIQUE,
  email                VARCHAR(255)   NOT NULL UNIQUE,
  password_hash        VARCHAR(255)   NOT NULL,
  full_name            VARCHAR(255)   NOT NULL,
  phone_number         VARCHAR(20)    NULL,
  profile_picture_url  VARCHAR(500)   NULL,
  blood_group          VARCHAR(10)    NULL,
  bio                  TEXT           NULL,
  is_active            TINYINT(1)     NOT NULL DEFAULT 1,
  is_admin             TINYINT(1)     NOT NULL DEFAULT 0,
  is_blocked           TINYINT(1)     NOT NULL DEFAULT 0,
  suspended_at         TIMESTAMP      NULL DEFAULT NULL,
  suspended_reason     VARCHAR(500)   NULL DEFAULT NULL,
  last_login_at        TIMESTAMP      NULL DEFAULT NULL,
  theme_preference     VARCHAR(20)    NOT NULL DEFAULT 'default',
  created_at           TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  INDEX idx_users_email        (email),
  INDEX idx_users_firebase_uid (firebase_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 2. ADMINS
-- (Separate admin login — different from your legacy `admin` table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS admins (
  admin_id          INT           NOT NULL AUTO_INCREMENT,
  email             VARCHAR(255)  NOT NULL UNIQUE,
  password_hash     VARCHAR(255)  NOT NULL,
  full_name         VARCHAR(255)  NOT NULL,
  role              ENUM('super_admin','moderator') NOT NULL DEFAULT 'moderator',
  is_active         TINYINT(1)    NOT NULL DEFAULT 1,
  last_login        DATETIME      NULL,
  reset_otp         VARCHAR(255)  NULL,
  reset_otp_expires DATETIME      NULL,
  created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (admin_id),
  INDEX idx_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 3. USER PREFERENCES
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id             INT         NOT NULL AUTO_INCREMENT,
  user_id                   INT         NOT NULL UNIQUE,
  language                  VARCHAR(10) NULL DEFAULT 'en',
  theme                     VARCHAR(50) NULL DEFAULT 'light',
  notifications_enabled     TINYINT(1)  NOT NULL DEFAULT 1,
  weather_alerts            TINYINT(1)  NOT NULL DEFAULT 1,
  traffic_alerts            TINYINT(1)  NOT NULL DEFAULT 1,
  emergency_sharing_enabled TINYINT(1)  NOT NULL DEFAULT 1,
  preferred_categories      JSON        NULL,
  updated_at                TIMESTAMP   NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (preference_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 4. BOOKINGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS bookings (
  booking_id              INT            NOT NULL AUTO_INCREMENT,
  user_id                 INT            NOT NULL,
  destination_id          INT            NOT NULL,
  booking_date            DATE           NULL,
  travel_date             DATE           NULL,
  num_travelers           INT            NOT NULL DEFAULT 1,
  package_id              INT            NULL,
  estimated_duration_days INT            NOT NULL DEFAULT 1,
  total_amount            DECIMAL(10,2)  NOT NULL DEFAULT 0,
  notes                   TEXT           NULL,
  status                  ENUM('Pending','Awaiting Payment','Confirmed','Active','Completed','Cancelled','Refunded')
                                         NOT NULL DEFAULT 'Pending',
  payment_status          ENUM('Unpaid','Paid','Refunded') NOT NULL DEFAULT 'Unpaid',
  payment_intent_id       VARCHAR(255)   NULL,
  cancelled_at            TIMESTAMP      NULL DEFAULT NULL,
  cancellation_reason     TEXT           NULL,
  created_at              TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (booking_id),
  FOREIGN KEY (user_id)        REFERENCES users(user_id)                ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id)  ON DELETE RESTRICT,
  INDEX idx_booking_user_id    (user_id),
  INDEX idx_booking_dest       (destination_id),
  INDEX idx_booking_status     (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 5. GROUP BOOKINGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_bookings (
  group_booking_id  INT            NOT NULL AUTO_INCREMENT,
  trip_name         VARCHAR(255)   NOT NULL,
  created_by        INT            NOT NULL,
  description       TEXT           NULL,
  max_members       INT            NOT NULL DEFAULT 20,
  destination_id    INT            NULL,
  total_amount      DECIMAL(10,2)  NOT NULL DEFAULT 0,
  payment_type      ENUM('individual','full') NOT NULL DEFAULT 'individual',
  start_date        DATE           NULL,
  end_date          DATE           NULL,
  status            ENUM('Planning','Open','Full','Active','Completed','Cancelled')
                                   NOT NULL DEFAULT 'Planning',
  created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (group_booking_id),
  FOREIGN KEY (created_by)     REFERENCES users(user_id)               ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_gb_created_by (created_by),
  INDEX idx_gb_status     (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 6. GROUP BOOKING MEMBERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_booking_members (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  user_id          INT       NOT NULL,
  role             ENUM('organizer','member') NOT NULL DEFAULT 'member',
  joined_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_gbm (group_booking_id, user_id),
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)          REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_gbm_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 7. GROUP INVITATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_invitations (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  sender_id        INT       NOT NULL,
  receiver_id      INT       NOT NULL,
  status           ENUM('Pending','Accepted','Declined') NOT NULL DEFAULT 'Pending',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id)        REFERENCES users(user_id)                   ON DELETE CASCADE,
  FOREIGN KEY (receiver_id)      REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_ginv_receiver (receiver_id),
  INDEX idx_ginv_group    (group_booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 8. GROUP CHAT MESSAGES
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_chat_messages (
  message_id       INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  user_id          INT       NOT NULL,
  message          TEXT      NOT NULL,
  message_type     ENUM('text','image','location','system') NOT NULL DEFAULT 'text',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id),
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)          REFERENCES users(user_id)                   ON DELETE CASCADE,
  INDEX idx_gcm_group_time (group_booking_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 9. GROUP TRACKING SESSIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_tracking_sessions (
  id               INT       NOT NULL AUTO_INCREMENT,
  group_booking_id INT       NOT NULL,
  status           ENUM('active','ended') NOT NULL DEFAULT 'active',
  started_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at         TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  INDEX idx_gts_group  (group_booking_id),
  INDEX idx_gts_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 10. PAYMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS payments (
  id                       INT            NOT NULL AUTO_INCREMENT,
  user_id                  INT            NOT NULL,
  booking_id               INT            NULL,
  group_booking_id         INT            NULL,
  stripe_payment_intent_id VARCHAR(255)   NULL UNIQUE,
  amount                   DECIMAL(10,2)  NOT NULL,
  currency                 VARCHAR(10)    NOT NULL DEFAULT 'usd',
  status                   ENUM('pending','succeeded','failed','refunded') NOT NULL DEFAULT 'pending',
  refund_requested_at      TIMESTAMP      NULL DEFAULT NULL,
  refund_approved_at       TIMESTAMP      NULL DEFAULT NULL,
  refund_rejected_at       TIMESTAMP      NULL DEFAULT NULL,
  refund_admin_notes       VARCHAR(500)   NULL DEFAULT NULL,
  created_at               TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at               TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id)         REFERENCES users(user_id)                        ON DELETE CASCADE,
  FOREIGN KEY (booking_id)      REFERENCES bookings(booking_id)                  ON DELETE SET NULL,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id)     ON DELETE SET NULL,
  INDEX idx_pay_user    (user_id),
  INDEX idx_pay_booking (booking_id),
  INDEX idx_pay_status  (status),
  INDEX idx_pay_stripe  (stripe_payment_intent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 11. TRANSACTIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS transactions (
  id                    INT            NOT NULL AUTO_INCREMENT,
  payment_id            INT            NOT NULL,
  amount                DECIMAL(10,2)  NOT NULL,
  status                ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  transaction_reference VARCHAR(255)   NULL,
  created_at            TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
  INDEX idx_txn_payment   (payment_id),
  INDEX idx_txn_reference (transaction_reference)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 12. ROUTES  (new schema — different from your legacy `route` table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS routes (
  route_id            INT            NOT NULL AUTO_INCREMENT,
  user_id             INT            NOT NULL,
  route_name          VARCHAR(255)   NOT NULL,
  description         TEXT           NULL,
  start_location      VARCHAR(255)   NULL,
  end_location        VARCHAR(255)   NULL,
  start_lat           DECIMAL(10,8)  NULL,
  start_lng           DECIMAL(11,8)  NULL,
  end_lat             DECIMAL(10,8)  NULL,
  end_lng             DECIMAL(11,8)  NULL,
  total_distance      DECIMAL(10,2)  NULL,
  estimated_duration  INT            NULL,
  route_data          JSON           NULL,
  difficulty_level    VARCHAR(50)    NULL,
  is_public           TINYINT(1)     NOT NULL DEFAULT 0,
  views_count         INT            NOT NULL DEFAULT 0,
  rating              DECIMAL(3,2)   NULL,
  created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (route_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_route_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 13. ROUTE STOPS
-- ============================================================================
CREATE TABLE IF NOT EXISTS route_stops (
  stop_id          INT            NOT NULL AUTO_INCREMENT,
  route_id         INT            NOT NULL,
  destination_id   INT            NULL,
  stop_order       INT            NOT NULL DEFAULT 0,
  latitude         DECIMAL(10,8)  NULL,
  longitude        DECIMAL(11,8)  NULL,
  stop_name        VARCHAR(255)   NULL,
  duration_at_stop INT            NULL,
  notes            TEXT           NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (stop_id),
  FOREIGN KEY (route_id)       REFERENCES routes(route_id)                  ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id)      ON DELETE SET NULL,
  INDEX idx_rstop_route (route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 14. WISHLISTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS wishlists (
  wishlist_id        INT         NOT NULL AUTO_INCREMENT,
  user_id            INT         NOT NULL,
  destination_id     INT         NOT NULL,
  notes              TEXT        NULL,
  priority           VARCHAR(50) NULL,
  planned_visit_date DATE        NULL,
  created_at         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id),
  UNIQUE KEY uq_wishlist (user_id, destination_id),
  FOREIGN KEY (user_id)       REFERENCES users(user_id)               ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_wl_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 15. REVIEWS
-- ============================================================================
CREATE TABLE IF NOT EXISTS reviews (
  review_id      INT         NOT NULL AUTO_INCREMENT,
  user_id        INT         NOT NULL,
  destination_id INT         NULL,
  route_id       INT         NULL,
  rating         INT         NOT NULL,
  title          VARCHAR(255) NULL,
  review_text    TEXT        NULL,
  images         JSON        NULL,
  helpful_count  INT         NOT NULL DEFAULT 0,
  created_at     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP   NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id),
  FOREIGN KEY (user_id)       REFERENCES users(user_id)               ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  FOREIGN KEY (route_id)       REFERENCES routes(route_id)             ON DELETE CASCADE,
  INDEX idx_rev_dest (destination_id),
  INDEX idx_rev_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 16. TOUR PACKAGES  (new schema — different from legacy `tourpackage`)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tour_packages (
  package_id       INT            NOT NULL AUTO_INCREMENT,
  title            VARCHAR(255)   NOT NULL,
  description      TEXT           NULL,
  duration_days    INT            NOT NULL DEFAULT 3,
  total_price      DECIMAL(12,2)  NOT NULL DEFAULT 0,
  price_per_day    DECIMAL(10,2)  NOT NULL DEFAULT 50.00,
  category         VARCHAR(100)   NOT NULL DEFAULT 'General',
  destinations     JSON           NULL,
  itinerary        JSON           NULL,
  max_travelers    INT            NOT NULL DEFAULT 10,
  includes         JSON           NULL,
  image_url        VARCHAR(500)   NULL,
  is_active        TINYINT(1)     NOT NULL DEFAULT 1,
  is_ai_generated  TINYINT(1)     NOT NULL DEFAULT 0,
  created_by_admin INT            NULL,
  created_at       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP      NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (package_id),
  INDEX idx_pkg_price    (total_price),
  INDEX idx_pkg_category (category),
  INDEX idx_pkg_active   (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 17. BUDGET PLANS
-- ============================================================================
CREATE TABLE IF NOT EXISTS budget_plans (
  plan_id         INT            NOT NULL AUTO_INCREMENT,
  user_id         INT            NOT NULL,
  budget_amount   DECIMAL(12,2)  NOT NULL,
  num_travelers   INT            NOT NULL DEFAULT 1,
  duration_days   INT            NOT NULL DEFAULT 3,
  start_city      VARCHAR(100)   NULL,
  preferences     VARCHAR(500)   NULL,
  generated_plan  JSON           NULL,
  created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (plan_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_bp_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 18. EMERGENCY CONTACTS  (new — different from legacy `emergencycontact`)
-- ============================================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
  contact_id    INT           NOT NULL AUTO_INCREMENT,
  user_id       INT           NOT NULL,
  contact_name  VARCHAR(255)  NOT NULL,
  contact_phone VARCHAR(20)   NOT NULL,
  contact_email VARCHAR(255)  NULL,
  relationship  VARCHAR(100)  NULL,
  is_primary    TINYINT(1)    NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (contact_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ec_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 19. EMERGENCY ALERTS  (full in-app SOS)
-- ============================================================================
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id                INT            NOT NULL AUTO_INCREMENT,
  user_id           INT            NOT NULL,
  trip_id           INT            NULL,
  trip_type         ENUM('single','group') NULL,
  latitude          DECIMAL(10,8)  NOT NULL DEFAULT 0,
  longitude         DECIMAL(11,8)  NOT NULL DEFAULT 0,
  message           TEXT           NULL,
  status            ENUM('Active','Acknowledged','Resolved','Cancelled') NOT NULL DEFAULT 'Active',
  workflow_status   ENUM('New','Acknowledged','In Progress','Resolved')  NOT NULL DEFAULT 'New',
  resolution_notes  TEXT           NULL,
  acknowledged_at   TIMESTAMP      NULL DEFAULT NULL,
  in_progress_at    TIMESTAMP      NULL DEFAULT NULL,
  assigned_admin_id INT            NULL DEFAULT NULL,
  resolved_at       TIMESTAMP      NULL DEFAULT NULL,
  created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ea_user_id (user_id),
  INDEX idx_ea_status  (status),
  INDEX idx_ea_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 20. SOS ALERTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS sos_alerts (
  id                INT            NOT NULL AUTO_INCREMENT,
  user_id           INT            NOT NULL,
  latitude          DECIMAL(10,8)  NULL,
  longitude         DECIMAL(11,8)  NULL,
  message           TEXT           NULL,
  status            ENUM('Active','Resolved','Cancelled') NOT NULL DEFAULT 'Active',
  workflow_status   ENUM('New','Acknowledged','In Progress','Resolved') NOT NULL DEFAULT 'New',
  resolution_notes  TEXT           NULL,
  assigned_admin_id INT            NULL,
  created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at       TIMESTAMP      NULL DEFAULT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_sos_user   (user_id),
  INDEX idx_sos_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 21. EMERGENCY EVENTS  (quick-dial log: ambulance / police / tourist police)
-- ============================================================================
CREATE TABLE IF NOT EXISTS emergency_events (
  id         INT            NOT NULL AUTO_INCREMENT,
  user_id    INT            NOT NULL,
  type       ENUM('ambulance','police','tourist_police','ice_share','full_sos') NOT NULL,
  latitude   DECIMAL(10,8)  NULL DEFAULT NULL,
  longitude  DECIMAL(11,8)  NULL DEFAULT NULL,
  status     ENUM('Pending','Acknowledged') NOT NULL DEFAULT 'Pending',
  created_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ee_user    (user_id),
  INDEX idx_ee_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 22. EMERGENCY TRACKING  (live GPS breadcrumbs during active SOS)
-- ============================================================================
CREATE TABLE IF NOT EXISTS emergency_tracking (
  id           INT            NOT NULL AUTO_INCREMENT,
  emergency_id INT            NOT NULL,
  latitude     DECIMAL(10,8)  NOT NULL,
  longitude    DECIMAL(11,8)  NOT NULL,
  timestamp    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (emergency_id) REFERENCES emergency_alerts(id) ON DELETE CASCADE,
  INDEX idx_et_emergency (emergency_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 23. NOTIFICATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  notification_id        INT          NOT NULL AUTO_INCREMENT,
  user_id                INT          NOT NULL,
  title                  VARCHAR(255) NOT NULL,
  message                TEXT         NOT NULL,
  type                   VARCHAR(100) NOT NULL DEFAULT 'general',
  related_route_id       INT          NULL,
  related_destination_id INT          NULL,
  action_url             VARCHAR(500) NULL,
  is_read                TINYINT(1)   NOT NULL DEFAULT 0,
  created_at             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id),
  FOREIGN KEY (user_id)               REFERENCES users(user_id)               ON DELETE CASCADE,
  FOREIGN KEY (related_route_id)      REFERENCES routes(route_id)             ON DELETE SET NULL,
  FOREIGN KEY (related_destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_notif_user    (user_id),
  INDEX idx_notif_is_read (is_read),
  INDEX idx_notif_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 24. FCM TOKENS  (Firebase push notification device tokens)
-- ============================================================================
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id         INT          NOT NULL AUTO_INCREMENT,
  user_id    INT          NOT NULL,
  token      VARCHAR(512) NOT NULL UNIQUE,
  platform   ENUM('android','ios','web') NOT NULL DEFAULT 'android',
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP    NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_fcm_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 25. WEATHER CACHE
-- ============================================================================
CREATE TABLE IF NOT EXISTS weather_cache (
  cache_id     INT            NOT NULL AUTO_INCREMENT,
  latitude     DECIMAL(10,8)  NOT NULL,
  longitude    DECIMAL(11,8)  NOT NULL,
  weather_data JSON           NOT NULL,
  expires_at   TIMESTAMP      NOT NULL,
  created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (cache_id),
  UNIQUE KEY uq_weather_location (latitude, longitude),
  INDEX idx_weather_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 26. AI CHAT HISTORY
-- ============================================================================
CREATE TABLE IF NOT EXISTS ai_chat_history (
  chat_id        INT       NOT NULL AUTO_INCREMENT,
  user_id        INT       NOT NULL,
  user_message   TEXT      NOT NULL,
  ai_response    TEXT      NOT NULL,
  context_data   JSON      NULL,
  helpful_rating INT       NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_ai_user    (user_id),
  INDEX idx_ai_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 27. MENTAL HEALTH CHAT HISTORY  (wellness / travel anxiety chatbot)
-- ============================================================================
CREATE TABLE IF NOT EXISTS mental_health_chat_history (
  id           INT       NOT NULL AUTO_INCREMENT,
  user_id      INT       NOT NULL,
  user_message TEXT      NOT NULL,
  ai_response  TEXT      NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_mh_user (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 28. AI RECOMMENDATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS ai_recommendations (
  recommendation_id      INT           NOT NULL AUTO_INCREMENT,
  user_id                INT           NOT NULL,
  destination_id         INT           NULL,
  reason                 TEXT          NULL,
  confidence_score       DECIMAL(3,2)  NULL,
  recommended_visit_date DATE          NULL,
  viewed                 TINYINT(1)    NOT NULL DEFAULT 0,
  created_at             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (recommendation_id),
  FOREIGN KEY (user_id)       REFERENCES users(user_id)               ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE,
  INDEX idx_airec_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 29. VIRTUAL TOURS
-- ============================================================================
CREATE TABLE IF NOT EXISTS virtual_tours (
  id             INT          NOT NULL AUTO_INCREMENT,
  destination_id INT          NULL,
  title          VARCHAR(255) NOT NULL,
  description    TEXT         NULL,
  thumbnail_url  VARCHAR(500) NULL,
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
  INDEX idx_vt_destination (destination_id),
  INDEX idx_vt_active      (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 30. VIRTUAL TOUR SCENES
-- ============================================================================
CREATE TABLE IF NOT EXISTS virtual_tour_scenes (
  id            INT          NOT NULL AUTO_INCREMENT,
  tour_id       INT          NOT NULL,
  scene_name    VARCHAR(255) NOT NULL,
  panorama_url  VARCHAR(500) NOT NULL,
  thumbnail_url VARCHAR(500) NULL,
  description   TEXT         NULL,
  ai_narration  TEXT         NULL,
  scene_order   INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  FOREIGN KEY (tour_id) REFERENCES virtual_tours(id) ON DELETE CASCADE,
  INDEX idx_vts_tour (tour_id, scene_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 31. VIRTUAL TOUR HOTSPOTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS virtual_tour_hotspots (
  id              INT     NOT NULL AUTO_INCREMENT,
  scene_id        INT     NOT NULL,
  type            ENUM('scene','info') NOT NULL DEFAULT 'info',
  target_scene_id INT     NULL,
  title           VARCHAR(255) NULL,
  text            TEXT    NULL,
  pitch           FLOAT   NOT NULL DEFAULT 0,
  yaw             FLOAT   NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  FOREIGN KEY (scene_id)        REFERENCES virtual_tour_scenes(id) ON DELETE CASCADE,
  FOREIGN KEY (target_scene_id) REFERENCES virtual_tour_scenes(id) ON DELETE SET NULL,
  INDEX idx_vth_scene (scene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- 32. ADMIN ACTIVITY LOGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin_activity_logs (
  id          INT          NOT NULL AUTO_INCREMENT,
  admin_id    INT          NOT NULL,
  admin_name  VARCHAR(255) NOT NULL DEFAULT '',
  action      VARCHAR(100) NOT NULL,
  target_type VARCHAR(50)  NULL,
  target_id   INT          NULL,
  details     TEXT         NULL,
  ip_address  VARCHAR(45)  NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_aal_admin   (admin_id),
  INDEX idx_aal_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- SEED DATA — Default admin account
-- Password: Admin@SafarSync2025!
-- CHANGE THIS after first login via the admin panel.
-- ============================================================================
INSERT IGNORE INTO admins (email, password_hash, full_name, role) VALUES (
  'admin@safarsync.com',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TqrCJxqLkQJHwPxMhkNPFVKdYXvy',
  'SafarSync Admin',
  'super_admin'
);

-- ============================================================================
-- SEED DATA — Sasta Tour Packages
-- ============================================================================
INSERT IGNORE INTO tour_packages (package_id, title, description, duration_days, total_price, price_per_day, category, destinations, itinerary, includes, is_active) VALUES
(1, 'Weekend Escape — Murree & Nathiagali', 'A short 3-day getaway to the cool hills of Murree and Nathiagali.', 3, 15000.00, 5000.00, 'Nature',
 '["Murree","Nathiagali","Patriata"]',
 '[{"day":1,"title":"Arrival + Murree Mall Road","desc":"Check in, evening stroll"},{"day":2,"title":"Nathiagali Hike","desc":"Morning hike to Miranjani top"},{"day":3,"title":"Patriata Chair Lift + Return","desc":"Chair lift ride, depart"}]',
 '["Hotel 2 nights","Breakfast & dinner","Local guide","Chair lift tickets"]', 1),

(2, 'Adventure Week — Hunza Valley', 'Explore the breathtaking Hunza Valley over 7 days.', 7, 35000.00, 5000.00, 'Adventure',
 '["Hunza","Karimabad","Attabad Lake","Passu"]',
 '[{"day":1,"title":"Islamabad → Hunza","desc":"Fly to Gilgit, drive to Hunza"},{"day":2,"title":"Baltit Fort","desc":"Historic fort tour"},{"day":3,"title":"Attabad Lake","desc":"Boat ride"},{"day":4,"title":"Passu Cones Trek","desc":"Day hike"},{"day":5,"title":"Eagle Nest","desc":"Panoramic views"},{"day":6,"title":"Culture Day","desc":"Apricot farm, local food"},{"day":7,"title":"Return","desc":"Back to Islamabad"}]',
 '["Hotel 6 nights","All meals","Flight Islamabad↔Gilgit","Local guide","Boat ride","Transport"]', 1),

(3, 'Grand Pakistan Explorer — 14 Days', 'The ultimate Pakistan road trip: Lahore, Islamabad, Naran, Swat, Hunza.', 14, 55000.00, 3929.00, 'Cultural',
 '["Lahore","Islamabad","Naran Valley","Swat","Hunza"]',
 '[{"day":1,"title":"Lahore — Walled City","desc":"Badshahi Mosque, Lahore Fort"},{"day":2,"title":"Lahore Museums","desc":"Pakistan Museum, Shalimar"},{"day":3,"title":"→ Islamabad","desc":"Motorway drive, Faisal Mosque"},{"day":4,"title":"Margalla Hills","desc":"Trail 5 hike"},{"day":5,"title":"→ Naran","desc":"KKH drive"},{"day":6,"title":"Saif ul Malook","desc":"Lake visit by jeep"},{"day":7,"title":"→ Swat","desc":"Scenic passes"},{"day":8,"title":"Swat Valley","desc":"Fizagat, White Palace"},{"day":9,"title":"Malam Jabba","desc":"Ski resort area"},{"day":10,"title":"→ Gilgit","desc":"KKH drive"},{"day":11,"title":"Hunza Arrival","desc":"Rest, Karimabad walk"},{"day":12,"title":"Hunza Highlights","desc":"Baltit Fort, Attabad"},{"day":13,"title":"Eagle Nest","desc":"Sunrise viewpoint"},{"day":14,"title":"Return","desc":"Gilgit → Islamabad"}]',
 '["Hotel 13 nights","All meals","Transport throughout","Local guides","Entry tickets","Jeep rides"]', 1),

(4, 'Family Fun — Swat Valley', 'A 5-day family holiday in the lush Swat Valley.', 5, 22000.00, 4400.00, 'Nature',
 '["Swat","Mingora","Malam Jabba","Fizagat"]',
 '[{"day":1,"title":"Arrival Mingora","desc":"Swat Museum visit"},{"day":2,"title":"Malam Jabba","desc":"Chair lift + meadows"},{"day":3,"title":"Fizagat Park","desc":"Picnic by the river"},{"day":4,"title":"Waterfalls Day","desc":"Local waterfalls"},{"day":5,"title":"Shopping & Departure","desc":"Swati handicrafts"}]',
 '["Hotel 4 nights","Breakfast","Chair lift tickets","Guide","Transport"]', 1),

(5, 'Budget City Break — Lahore', 'Explore the cultural heart of Pakistan in just 2 days.', 2, 8000.00, 4000.00, 'Cultural',
 '["Lahore","Anarkali","Wagah Border"]',
 '[{"day":1,"title":"Old Lahore","desc":"Badshahi Mosque, Fort, Food Street"},{"day":2,"title":"Wagah Border","desc":"Shalimar Gardens, border ceremony"}]',
 '["Hotel 1 night","Breakfast","Wagah Border transport","Guide"]', 1);

-- ============================================================================
-- SEED DATA — Virtual Tours (demo panoramas)
-- ============================================================================
INSERT IGNORE INTO virtual_tours (id, destination_id, title, description, is_active) VALUES
(1, NULL, 'Hunza Valley Tour',    'Explore the breathtaking Hunza Valley across 4 iconic locations.', 1),
(2, NULL, 'Lahore Heritage Tour', 'Walk through 400 years of Mughal history in Lahore.', 1),
(3, NULL, 'Skardu Adventure Tour','Experience the cold desert and turquoise lakes of Skardu.', 1);

INSERT IGNORE INTO virtual_tour_scenes (id, tour_id, scene_name, panorama_url, description, scene_order) VALUES
(1,  1, 'Attabad Lake',   'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Attabad_Lake_Hunza_2.jpg/2560px-Attabad_Lake_Hunza_2.jpg', 'Turquoise lake formed by the 2010 landslide.', 0),
(2,  1, 'Baltit Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Baltit_fort.jpg/2560px-Baltit_fort.jpg', '700-year-old fort overlooking Karimabad.', 1),
(3,  1, 'Eagle Nest View','https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Hunza_Valley_from_Eagle%27s_Nest.jpg/2560px-Hunza_Valley_from_Eagle%27s_Nest.jpg', 'Highest viewpoint in Hunza.', 2),
(4,  1, 'Passu Cones',    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Passu_Cones_%282%29.jpg/2560px-Passu_Cones_%282%29.jpg', 'Cathedral-like spires in the Karakoram.', 3),
(5,  2, 'Badshahi Mosque','https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg/2560px-Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg', 'One of the worlds largest mosques.', 0),
(6,  2, 'Lahore Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Lahore_Fort_Sheesh_Mahal.jpg/2560px-Lahore_Fort_Sheesh_Mahal.jpg', 'UNESCO World Heritage Site.', 1),
(7,  2, 'Walled City',    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Old_Lahore.jpg/2560px-Old_Lahore.jpg', 'Ancient walled city of Lahore.', 2),
(8,  3, 'Shangrila Lake', 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Shangrila_Resort_Kachura_Lake_Skardu.jpg/2560px-Shangrila_Resort_Kachura_Lake_Skardu.jpg', 'Heaven on Earth at 2500m altitude.', 0),
(9,  3, 'Deosai Plains',  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Deosai_National_Park.jpg/2560px-Deosai_National_Park.jpg', 'One of the worlds highest plateaus.', 1),
(10, 3, 'Shigar Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Shigar_Fort.JPG/1280px-Shigar_Fort.JPG', '400-year-old restored palace fort.', 2);

INSERT IGNORE INTO virtual_tour_hotspots (scene_id, type, target_scene_id, title, text, pitch, yaw) VALUES
(1, 'scene', 2,  'Go to Baltit Fort',  NULL, -5,  45),
(1, 'info',  NULL,'Attabad Lake',       'Formed in 2010 when a landslide blocked the Hunza River.', 10, -90),
(2, 'scene', 3,  'Eagle Nest View',     NULL, -3, 120),
(2, 'scene', 1,  'Back to Attabad',     NULL, -3, -60),
(3, 'scene', 4,  'Passu Cones',         NULL, -5,  90),
(3, 'scene', 2,  'Back to Baltit',      NULL, -5, -90),
(4, 'scene', 1,  'Back to Attabad',     NULL, -5, 180),
(5, 'scene', 6,  'Go to Lahore Fort',   NULL, -5,  60),
(6, 'scene', 7,  'Walled City',         NULL, -5, 180),
(6, 'scene', 5,  'Back to Mosque',      NULL, -5,   0),
(7, 'scene', 5,  'Back to Mosque',      NULL, -5,   0),
(8, 'scene', 9,  'Deosai Plains',       NULL, -5,  90),
(9, 'scene', 10, 'Shigar Fort',         NULL, -5, 180),
(9, 'scene', 8,  'Back to Shangrila',   NULL, -5,   0),
(10,'scene', 8,  'Back to Shangrila',   NULL, -5,  90);

-- ============================================================================
-- VERIFY: Check all tables now exist
-- ============================================================================
SELECT table_name AS `Table`, table_rows AS `Rows`
FROM information_schema.tables
WHERE table_schema = 'safarsync'
ORDER BY table_name;
