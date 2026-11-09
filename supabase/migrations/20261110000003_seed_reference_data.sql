-- ============================================================================
-- SafarSync — reference / seed data
--
-- Sources:
--   * destinations   → the 8 destinations bundled with the app
--                      (lib/frontend/src/utils/local_database_service.dart),
--                      ids kept identical so existing UI references still match
--   * admins, tour_packages, virtual tours/scenes/hotspots
--                    → SECTION 18 of lib/backend/safarsync_complete_migration.sql
--
-- No MySQL server/dump was available on the development machine, so there
-- were no user-generated records (users, bookings, …) to migrate.
-- ============================================================================

insert into public.destinations
  (destination_id, name, location, city, country, category, description,
   image_url, rating, review_count, price_label, average_cost, latitude, longitude)
values
  (1, 'Fairy Meadows',       'Gilgit-Baltistan',   'Gilgit-Baltistan',   'Pakistan', 'nature',
      'Lush alpine meadow with views of Nanga Parbat.',
      'assets/explore_images/fairy_meadows.jpg',       4.9, 320, 'Rs 45,000', 45000, 35.38500000, 74.58500000),
  (2, 'Skardu Valley',       'Gilgit-Baltistan',   'Skardu',             'Pakistan', 'nature',
      'Mountain valley with lakes, forts, and scenic roads.',
      'assets/explore_images/skardu_valley.jpg',       4.8, 280, 'Rs 38,000', 38000, 35.29710000, 75.63330000),
  (3, 'Mohenjo Daro',        'Sindh',              'Larkana',            'Pakistan', 'history',
      'Ancient Indus Valley civilization archaeological site.',
      'assets/explore_images/mohenjo_daro.jpg',        4.7, 150, 'Rs 8,000',   8000, 27.32920000, 68.13890000),
  (4, 'Rohtas Fort',         'Punjab',             'Jhelum',             'Pakistan', 'history',
      'UNESCO heritage military fort from the 16th century.',
      'assets/explore_images/rohtas_fort.jpg',         4.6, 200, 'Rs 6,000',   6000, 32.96200000, 73.57600000),
  (5, 'Food Street Lahore',  'Lahore',             'Lahore',             'Pakistan', 'food',
      'Traditional street food and cultural vibes.',
      'assets/explore_images/food_street_lahore.jpg',  4.7, 500, 'Rs 2,500',   2500, 31.58800000, 74.31000000),
  (6, 'Burns Road Karachi',  'Karachi',            'Karachi',            'Pakistan', 'food',
      'Iconic food hub with classic Karachi flavors.',
      'assets/explore_images/burns_road_karachi.jpg',  4.5, 410, 'Rs 2,000',   2000, 24.85800000, 67.01500000),
  (7, 'K2 Base Camp',        'Gilgit-Baltistan',   'Skardu',             'Pakistan', 'adventure',
      'High-altitude expedition route for adventurers.',
      'assets/explore_images/k2_base_camp.jpg',        4.9,  95, 'Rs 75,000', 75000, 35.88000000, 76.51500000),
  (8, 'Chitral Valley Trek', 'Khyber Pakhtunkhwa', 'Chitral',            'Pakistan', 'adventure',
      'Scenic trekking trails through mountain valleys.',
      'assets/explore_images/chitral_valley_trek.jpg', 4.8, 120, 'Rs 52,000', 52000, 35.85100000, 71.78640000)
on conflict (destination_id) do nothing;

-- Admin role row (authentication is Supabase Auth — no password stored here).
-- It is linked automatically the first time a *verified* Supabase Auth account
-- with this email signs in to the admin panel.
insert into public.admins (email, full_name, role)
values ('admin@safarsync.com', 'SafarSync Admin', 'super_admin')
on conflict (email) do nothing;

INSERT INTO tour_packages
  (package_id, title, description, duration_days, total_price, price_per_day, category, destinations, itinerary, includes, image_url, is_active)
VALUES
(1, 'Weekend Escape — Murree & Nathiagali',
  'A short 3-day getaway to the cool hills of Murree and Nathiagali.',
  3, 15000.00, 5000.00, 'Nature',
  '["Murree","Nathiagali","Patriata"]',
  '[{"day":1,"title":"Arrival + Murree Mall Road","desc":"Check in, evening stroll on Mall Road"},{"day":2,"title":"Nathiagali Hike","desc":"Morning hike to Miranjani top"},{"day":3,"title":"Patriata Chair Lift + Return","desc":"Chair lift ride, depart by evening"}]',
  '["Hotel 2 nights","Breakfast & dinner","Local guide","Chair lift tickets"]',
  NULL, true),

(2, 'Adventure Week — Hunza Valley',
  'Explore the breathtaking Hunza Valley over 7 days.',
  7, 35000.00, 5000.00, 'Adventure',
  '["Hunza","Karimabad","Attabad Lake","Passu"]',
  '[{"day":1,"title":"Islamabad → Hunza (Flight)","desc":"Fly to Gilgit, drive to Hunza"},{"day":2,"title":"Baltit Fort & Karimabad","desc":"Historic fort tour, local bazaar"},{"day":3,"title":"Attabad Lake","desc":"Boat ride on the stunning blue lake"},{"day":4,"title":"Passu Cones Trek","desc":"Day hike to iconic Passu Cathedral"},{"day":5,"title":"Eagle Nest Viewpoint","desc":"Panoramic views at sunrise"},{"day":6,"title":"Local Culture Day","desc":"Apricot farm, local food, music"},{"day":7,"title":"Return Flight","desc":"Back to Islamabad"}]',
  '["Hotel 6 nights","All meals","Flight Islamabad↔Gilgit","Local guide","Boat ride","Transport"]',
  NULL, true),

(3, 'Grand Pakistan Explorer — 14 Days',
  'The ultimate Pakistan road trip covering Lahore, Islamabad, Naran, Swat, and Hunza.',
  14, 55000.00, 3929.00, 'Cultural',
  '["Lahore","Islamabad","Naran Valley","Swat","Hunza"]',
  '[{"day":1,"title":"Lahore — Walled City","desc":"Badshahi Mosque, Lahore Fort, Food Street"},{"day":2,"title":"Lahore — Museums","desc":"Pakistan Museum, Shalimar Gardens"},{"day":3,"title":"Lahore → Islamabad","desc":"Motorway drive, Faisal Mosque"},{"day":4,"title":"Islamabad & Margalla Hills","desc":"Trail 5 hike, Daman-e-Koh"},{"day":5,"title":"Islamabad → Naran","desc":"Scenic KKH drive"},{"day":6,"title":"Naran — Saif ul Malook","desc":"Lake visit by jeep"},{"day":7,"title":"Naran → Swat","desc":"Transfer through scenic passes"},{"day":8,"title":"Swat Valley","desc":"Fizagat Park, White Palace"},{"day":9,"title":"Swat → Mingora","desc":"Malam Jabba ski resort area"},{"day":10,"title":"Swat → Gilgit","desc":"Long drive through KKH"},{"day":11,"title":"Hunza Arrival","desc":"Rest, Karimabad evening walk"},{"day":12,"title":"Hunza Highlights","desc":"Baltit Fort, Attabad Lake"},{"day":13,"title":"Hunza — Eagle Nest","desc":"Sunrise viewpoint"},{"day":14,"title":"Return Flight","desc":"Gilgit → Islamabad"}]',
  '["Hotel 13 nights","All meals","Transport throughout","Local guides","Entry tickets","Jeep rides"]',
  NULL, true),

(4, 'Family Fun — Swat Valley',
  'A 5-day family holiday in the lush Swat Valley.',
  5, 22000.00, 4400.00, 'Nature',
  '["Swat","Mingora","Malam Jabba","Fizagat"]',
  '[{"day":1,"title":"Arrival Mingora","desc":"Check in, Swat Museum visit"},{"day":2,"title":"Malam Jabba","desc":"Chair lift + scenic meadows"},{"day":3,"title":"Fizagat Park & River","desc":"Picnic by the river, kids activities"},{"day":4,"title":"Waterfalls Day","desc":"Visit local waterfalls and farms"},{"day":5,"title":"Shopping & Departure","desc":"Swati handicrafts, return home"}]',
  '["Hotel 4 nights","Breakfast","Chair lift tickets","Guide","Transport"]',
  NULL, true),

(5, 'Budget City Break — Lahore',
  'Explore the cultural heart of Pakistan in just 2 days.',
  2, 8000.00, 4000.00, 'Cultural',
  '["Lahore","Anarkali","Wagah Border"]',
  '[{"day":1,"title":"Old Lahore","desc":"Badshahi Mosque, Lahore Fort, Anarkali Bazaar, Food Street"},{"day":2,"title":"Wagah Border + Gardens","desc":"Shalimar Gardens, Wagah Border ceremony at sunset"}]',
  '["Hotel 1 night","Breakfast","Wagah Border transport","Guide"]',
  NULL, true)
ON CONFLICT DO NOTHING;

INSERT INTO virtual_tours (id, destination_id, title, description, thumbnail_url, is_active) VALUES
(1, NULL, 'Hunza Valley Tour',    'Explore the breathtaking Hunza Valley across 4 iconic locations.', NULL, true),
(2, NULL, 'Lahore Heritage Tour', 'Walk through 400 years of Mughal history in Lahore.', NULL, true),
(3, NULL, 'Skardu Adventure Tour','Experience the cold desert and turquoise lakes of Skardu.', NULL, true)
ON CONFLICT DO NOTHING;

INSERT INTO virtual_tour_scenes
  (id, tour_id, scene_name, panorama_url, description, scene_order) VALUES

(1,  1, 'Attabad Lake',   'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Attabad_Lake_Hunza_2.jpg/2560px-Attabad_Lake_Hunza_2.jpg', 'A turquoise lake formed by the 2010 Attabad landslide.', 0),
(2,  1, 'Baltit Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Baltit_fort.jpg/2560px-Baltit_fort.jpg',                   'A 700-year-old fort overlooking Karimabad.', 1),
(3,  1, 'Eagle Nest View','https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Hunza_Valley_from_Eagle%27s_Nest.jpg/2560px-Hunza_Valley_from_Eagle%27s_Nest.jpg', 'The highest viewpoint in Hunza.', 2),
(4,  1, 'Passu Cones',    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Passu_Cones_%282%29.jpg/2560px-Passu_Cones_%282%29.jpg',   'Cathedral-like spires in the Karakoram.', 3),

(5,  2, 'Badshahi Mosque','https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg/2560px-Badshahi_Mosque_July_1_2005_pic32_by_Ali_Imran.jpg', 'One of the world largest mosques.', 0),
(6,  2, 'Lahore Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Lahore_Fort_Sheesh_Mahal.jpg/2560px-Lahore_Fort_Sheesh_Mahal.jpg', 'UNESCO World Heritage Site.', 1),
(7,  2, 'Walled City',   'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Old_Lahore.jpg/2560px-Old_Lahore.jpg',                      'Ancient walled city of Lahore.', 2),

(8,  3, 'Shangrila Lake', 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Shangrila_Resort_Kachura_Lake_Skardu.jpg/2560px-Shangrila_Resort_Kachura_Lake_Skardu.jpg', 'Heaven on Earth at 2,500m altitude.', 0),
(9,  3, 'Deosai Plains',  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Deosai_National_Park.jpg/2560px-Deosai_National_Park.jpg',   'One of the world highest plateaus.', 1),
(10, 3, 'Shigar Fort',    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Shigar_Fort.JPG/1280px-Shigar_Fort.JPG',                     '400-year-old restored palace fort.', 2)
ON CONFLICT DO NOTHING;

INSERT INTO virtual_tour_hotspots
  (scene_id, type, target_scene_id, title, text, pitch, yaw) VALUES

(1, 'scene', 2,  'Go to Baltit Fort',   NULL, -5,  45),
(1, 'info',  NULL,'Attabad Lake',        'Formed in 2010 when a landslide blocked the Hunza River. 21km long, 100m deep.', 10, -90),
(2, 'scene', 3,  'Eagle Nest View',      NULL, -3, 120),
(2, 'scene', 1,  'Back to Attabad',      NULL, -3, -60),
(3, 'scene', 4,  'Passu Cones',          NULL, -5,  90),
(3, 'scene', 2,  'Back to Baltit',       NULL, -5, -90),
(4, 'scene', 1,  'Back to Attabad',      NULL, -5, 180),

(5, 'scene', 6,  'Go to Lahore Fort',    NULL, -5,  60),
(6, 'scene', 7,  'Walled City',          NULL, -5, 180),
(6, 'scene', 5,  'Back to Mosque',       NULL, -5,   0),
(7, 'scene', 5,  'Back to Mosque',       NULL, -5,   0),

(8,  'scene', 9,  'Deosai Plains',       NULL, -5,  90),
(9,  'scene', 10, 'Shigar Fort',         NULL, -5, 180),
(9,  'scene', 8,  'Back to Shangrila',   NULL, -5,   0),
(10, 'scene', 8,  'Back to Shangrila',   NULL, -5,  90)
ON CONFLICT DO NOTHING;

-- keep identity sequences ahead of the explicitly-numbered seed rows
select setval(pg_get_serial_sequence('public.destinations', 'destination_id'),
              (select max(destination_id) from public.destinations));
select setval(pg_get_serial_sequence('public.tour_packages', 'package_id'),
              (select max(package_id) from public.tour_packages));
select setval(pg_get_serial_sequence('public.virtual_tours', 'id'),
              (select max(id) from public.virtual_tours));
select setval(pg_get_serial_sequence('public.virtual_tour_scenes', 'id'),
              (select max(id) from public.virtual_tour_scenes));
