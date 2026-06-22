-- migration_v8: Virtual Tours system
-- Run after migration_v7.sql

-- ─── virtual_tours ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS virtual_tours (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  destination_id  INT,
  title           VARCHAR(255) NOT NULL,
  description     TEXT,
  thumbnail_url   VARCHAR(500),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (destination_id) REFERENCES destination(destinationId) ON DELETE SET NULL
);

-- ─── virtual_tour_scenes ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS virtual_tour_scenes (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  tour_id         INT NOT NULL,
  scene_name      VARCHAR(255) NOT NULL,
  panorama_url    VARCHAR(500) NOT NULL,
  thumbnail_url   VARCHAR(500),
  description     TEXT,
  ai_narration    TEXT,
  scene_order     INT NOT NULL DEFAULT 0,
  FOREIGN KEY (tour_id) REFERENCES virtual_tours(id) ON DELETE CASCADE
);

-- ─── virtual_tour_hotspots ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS virtual_tour_hotspots (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  scene_id        INT NOT NULL,
  type            ENUM('scene','info') NOT NULL DEFAULT 'info',
  target_scene_id INT,
  title           VARCHAR(255),
  text            TEXT,
  pitch           FLOAT NOT NULL DEFAULT 0,
  yaw             FLOAT NOT NULL DEFAULT 0,
  FOREIGN KEY (scene_id) REFERENCES virtual_tour_scenes(id) ON DELETE CASCADE,
  FOREIGN KEY (target_scene_id) REFERENCES virtual_tour_scenes(id) ON DELETE SET NULL
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_vt_destination ON virtual_tours(destination_id);
CREATE INDEX IF NOT EXISTS idx_vts_tour       ON virtual_tour_scenes(tour_id, scene_order);
CREATE INDEX IF NOT EXISTS idx_vth_scene      ON virtual_tour_hotspots(scene_id);

-- ─── Seed: demo tours (panorama_url = replace with real equirectangular images)

INSERT IGNORE INTO virtual_tours (id, destination_id, title, description, thumbnail_url) VALUES
(1, NULL, 'Hunza Valley Tour',   'Explore the breathtaking Hunza Valley across 4 iconic locations.', NULL),
(2, NULL, 'Lahore Heritage Tour', 'Walk through 400 years of Mughal history in Lahore.', NULL),
(3, NULL, 'Skardu Adventure Tour','Experience the cold desert and turquoise lakes of Skardu.', NULL);

INSERT IGNORE INTO virtual_tour_scenes (id, tour_id, scene_name, panorama_url, description, scene_order) VALUES
-- Hunza
(1,  1, 'Attabad Lake',   'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Attabad_Lake_Hunza_2.jpg/2560px-Attabad_Lake_Hunza_2.jpg',
  'A turquoise lake formed by the 2010 Attabad landslide. Now a stunning tourist attraction.', 0),
(2,  1, 'Baltit Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Baltit_fort.jpg/2560px-Baltit_fort.jpg',
  'A 700-year-old fort overlooking Karimabad. Once the residence of the Mir of Hunza.', 1),
(3,  1, 'Eagle Nest View','https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Hunza_Valley_from_Eagle%27s_Nest.jpg/2560px-Hunza_Valley_from_Eagle%27s_Nest.jpg',
  'The highest viewpoint in Hunza. On clear days you can see five 7000m+ peaks.', 2),
(4,  1, 'Passu Cones',    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Passu_Cones_%282%29.jpg/2560px-Passu_Cones_%282%29.jpg',
  'Cathedral-like spires rising dramatically from the Karakoram range.', 3),
-- Lahore
(5,  2, 'Badshahi Mosque','https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg/2560px-Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg',
  'One of the world largest mosques. Built in 1673 by Mughal Emperor Aurangzeb.', 0),
(6,  2, 'Lahore Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Lahore_Fort_Sheesh_Mahal.jpg/2560px-Lahore_Fort_Sheesh_Mahal.jpg',
  'A UNESCO World Heritage Site. The Sheesh Mahal (Hall of Mirrors) is a masterpiece.', 1),
(7,  2, 'Walled City',   'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Old_Lahore.jpg/2560px-Old_Lahore.jpg',
  'The ancient walled city of Lahore, dating back over 2,000 years.', 2),
-- Skardu
(8,  3, 'Shangrila Lake', 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Shangrila_Resort_Kachura_Lake_Skardu.jpg/2560px-Shangrila_Resort_Kachura_Lake_Skardu.jpg',
  'Known as Heaven on Earth. The Kachura lake at 2,500m altitude.', 0),
(9,  3, 'Deosai Plains',  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Deosai_National_Park.jpg/2560px-Deosai_National_Park.jpg',
  'One of the world highest plateaus at 4,114m. Home to the Himalayan brown bear.', 1),
(10, 3, 'Shigar Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Shigar_Fort.JPG/1280px-Shigar_Fort.JPG',
  'A 400-year-old restored palace fort, now a luxury heritage hotel.', 2);

-- Seed hotspots (scene → scene navigation + info)
INSERT IGNORE INTO virtual_tour_hotspots (scene_id, type, target_scene_id, title, text, pitch, yaw) VALUES
-- Hunza Tour
(1, 'scene', 2,  'Go to Baltit Fort',  NULL, -5,  45),
(1, 'info',  NULL, 'Attabad Lake',     'Formed in January 2010 when a massive landslide blocked the Hunza River. The lake is now 21km long and 100m deep.', 10, -90),
(2, 'scene', 3,  'Eagle Nest View',    NULL, -3,  120),
(2, 'scene', 1,  'Back to Attabad',   NULL, -3, -60),
(2, 'info',  NULL, 'Baltit Fort',      'Built in the 8th century. The fort has been renovated by the Aga Khan Trust for Culture and is a must-visit landmark.', 15, 0),
(3, 'scene', 4,  'Passu Cones',        NULL, -5,  90),
(3, 'scene', 2,  'Back to Baltit',    NULL, -5, -90),
(4, 'scene', 1,  'Back to Attabad',   NULL, -5, 180),
(4, 'info',  NULL, 'Passu Cones',      'These distinctive spires, rising over 6,000 metres, are among the most dramatic mountain shapes on Earth.', 20, 0),
-- Lahore Tour
(5, 'scene', 6,  'Go to Lahore Fort', NULL, -5,  60),
(5, 'info',  NULL, 'Badshahi Mosque',  'Can accommodate 100,000 worshippers. The courtyard alone holds 60,000 people, making it the second largest in the world.', 10, -30),
(6, 'scene', 7,  'Walled City',       NULL, -5, 180),
(6, 'scene', 5,  'Back to Mosque',   NULL, -5,   0),
(6, 'info',  NULL, 'Sheesh Mahal',     'The Hall of Mirrors was built in 1631 using Belgian glass. Every inch of its walls and ceilings are covered in mirror work.', 20, 90),
(7, 'scene', 5,  'Back to Mosque',   NULL, -5,   0),
-- Skardu Tour
(8,  'scene', 9,  'Deosai Plains',    NULL, -5, 90),
(8,  'info',  NULL, 'Kachura Lake',   'The name Shangrila comes from James Hiltons novel Lost Horizon. The lake is surrounded by weeping willows and fruit trees.', 10, -45),
(9,  'scene', 10, 'Shigar Fort',      NULL, -5, 180),
(9,  'scene', 8,  'Back to Shangrila',NULL, -5, 0),
(10, 'scene', 8,  'Back to Shangrila',NULL, -5, 90);
