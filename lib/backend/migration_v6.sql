-- SafarSync Migration v6
-- Sasta Tour Packages + Budget Planner tables

CREATE TABLE IF NOT EXISTS tour_packages (
  package_id    INT AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(255)    NOT NULL,
  description   TEXT,
  duration_days INT             NOT NULL DEFAULT 3,
  total_price   DECIMAL(12,2)   NOT NULL,
  category      VARCHAR(100)    DEFAULT 'General',
  destinations  JSON,
  itinerary     JSON,
  max_travelers INT             DEFAULT 10,
  includes      JSON,
  image_url     VARCHAR(500),
  is_active     BOOLEAN         DEFAULT TRUE,
  is_ai_generated BOOLEAN       DEFAULT FALSE,
  created_by_admin INT,
  created_at    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_price    (total_price),
  INDEX idx_duration (duration_days),
  INDEX idx_category (category),
  INDEX idx_active   (is_active)
);

CREATE TABLE IF NOT EXISTS budget_plans (
  plan_id        INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT            NOT NULL,
  budget_amount  DECIMAL(12,2)  NOT NULL,
  num_travelers  INT            NOT NULL DEFAULT 1,
  duration_days  INT            NOT NULL DEFAULT 3,
  start_city     VARCHAR(100),
  preferences    VARCHAR(500),
  generated_plan JSON,
  created_at     TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- Seed a few starter Sasta Tour Packages
INSERT IGNORE INTO tour_packages (title, description, duration_days, total_price, category, destinations, itinerary, includes, image_url, is_active) VALUES
(
  'Weekend Escape — Murree & Nathiagali',
  'A short 3-day getaway to the cool hills of Murree and Nathiagali. Perfect for families and couples escaping city heat.',
  3, 15000.00, 'Nature',
  '["Murree", "Nathiagali", "Patriata"]',
  '[{"day":1,"title":"Arrival + Murree Mall Road","desc":"Check in, evening stroll on Mall Road"},{"day":2,"title":"Nathiagali Hike","desc":"Morning hike to Miranjani top, afternoon leisure"},{"day":3,"title":"Patriata Chair Lift + Return","desc":"Chair lift ride, depart by evening"}]',
  '["Hotel 2 nights", "Breakfast & dinner", "Local guide", "Chair lift tickets"]',
  NULL, TRUE
),
(
  'Adventure Week — Hunza Valley',
  'Explore the breathtaking Hunza Valley over 7 days. Karimabad bazaar, Baltit Fort, Attabad Lake, and the KKH.',
  7, 35000.00, 'Adventure',
  '["Hunza", "Karimabad", "Attabad Lake", "Passu"]',
  '[{"day":1,"title":"Islamabad → Hunza (Flight)","desc":"Fly to Gilgit, drive to Hunza"},{"day":2,"title":"Baltit Fort & Karimabad","desc":"Historic fort tour, local bazaar"},{"day":3,"title":"Attabad Lake","desc":"Boat ride on the stunning blue lake"},{"day":4,"title":"Passu Cones Trek","desc":"Day hike to iconic Passu Cathedral"},{"day":5,"title":"Eagle Nest Viewpoint","desc":"Panoramic views at sunrise"},{"day":6,"title":"Local Culture Day","desc":"Apricot farm, local food, music"},{"day":7,"title":"Return Flight","desc":"Back to Islamabad"}]',
  '["Hotel 6 nights", "All meals", "Flight Islamabad↔Gilgit", "Local guide", "Boat ride", "Transport"]',
  NULL, TRUE
),
(
  'Grand Pakistan Explorer — 14 Days',
  'The ultimate Pakistan road trip covering Lahore, Islamabad, Naran, Swat, and Hunza. For true adventurers.',
  14, 55000.00, 'Cultural',
  '["Lahore", "Islamabad", "Naran Valley", "Swat", "Hunza"]',
  '[{"day":1,"title":"Lahore — Walled City","desc":"Badshahi Mosque, Lahore Fort, Food Street"},{"day":2,"title":"Lahore — Museums","desc":"Pakistan Museum, Shalimar Gardens"},{"day":3,"title":"Lahore → Islamabad","desc":"Motorway drive, Faisal Mosque"},{"day":4,"title":"Islamabad & Margalla Hills","desc":"Trail 5 hike, Daman-e-Koh"},{"day":5,"title":"Islamabad → Naran","desc":"Scenic KKH drive"},{"day":6,"title":"Naran — Saif ul Malook","desc":"Lake visit by jeep or horse"},{"day":7,"title":"Naran → Swat","desc":"Transfer through scenic passes"},{"day":8,"title":"Swat Valley","desc":"Fizagat Park, White Palace"},{"day":9,"title":"Swat → Mingora","desc":"Malam Jabba ski resort area"},{"day":10,"title":"Swat → Gilgit","desc":"Long drive through KKH"},{"day":11,"title":"Hunza Arrival","desc":"Rest, Karimabad evening walk"},{"day":12,"title":"Hunza Highlights","desc":"Baltit Fort, Attabad Lake"},{"day":13,"title":"Hunza — Eagle Nest","desc":"Sunrise viewpoint"},{"day":14,"title":"Return Flight","desc":"Gilgit → Islamabad"}]',
  '["Hotel 13 nights", "All meals", "Transport throughout", "Local guides", "Entry tickets", "Jeep rides"]',
  NULL, TRUE
),
(
  'Family Fun — Swat Valley',
  'A 5-day family holiday in the lush Swat Valley. Waterfalls, green meadows, and Malam Jabba.',
  5, 22000.00, 'Nature',
  '["Swat", "Mingora", "Malam Jabba", "Fizagat"]',
  '[{"day":1,"title":"Arrival Mingora","desc":"Check in, Swat Museum visit"},{"day":2,"title":"Malam Jabba","desc":"Chair lift + scenic meadows"},{"day":3,"title":"Fizagat Park & River","desc":"Picnic by the river, kids activities"},{"day":4,"title":"Waterfalls Day","desc":"Visit local waterfalls and farms"},{"day":5,"title":"Shopping & Departure","desc":"Swati handicrafts, return home"}]',
  '["Hotel 4 nights", "Breakfast", "Chair lift tickets", "Guide", "Transport"]',
  NULL, TRUE
),
(
  'Budget City Break — Lahore',
  'Explore the cultural heart of Pakistan in just 2 days. History, food, and architecture at its finest.',
  2, 8000.00, 'Cultural',
  '["Lahore", "Anarkali", "Wagah Border"]',
  '[{"day":1,"title":"Old Lahore","desc":"Badshahi Mosque, Lahore Fort, Anarkali Bazaar, Food Street dinner"},{"day":2,"title":"Wagah Border + Gardens","desc":"Shalimar Gardens, Wagah Border ceremony at sunset"}]',
  '["Hotel 1 night", "Breakfast", "Wagah Border transport", "Guide"]',
  NULL, TRUE
);
