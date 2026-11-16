-- ============================================================================
-- SafarSync — hotels, restaurants, server-side pricing, secure group invites
-- ============================================================================
-- Additive and backward-compatible: new tables + nullable columns only.
--
-- Hotels and restaurants were previously hard-coded in the Flutter app with
-- client-supplied prices. They now live here as an ADMIN-MANAGED inventory
-- (inventory_source = 'internal'): SafarSync is not connected to a hotel /
-- restaurant supplier, so prices, room counts, opening hours and seat
-- capacity are SafarSync-managed values that admins maintain in the admin
-- panel. The seed rows below are the listings the app already showed, with
-- the prices it already displayed; room counts / opening hours / seating
-- capacity were never present in the app and are PLACEHOLDERS for admins to
-- correct.
-- ============================================================================

-- ── Hotels ────────────────────────────────────────────────────────────────────
create table public.hotels (
  hotel_id          serial primary key,
  name              text not null,
  description       text,
  address           text,
  city              text,
  latitude          numeric(10,7),
  longitude         numeric(10,7),
  image_url         text,
  category          text not null default 'Standard',
  rating            numeric(2,1) check (rating between 0 and 5),
  amenities         jsonb not null default '[]'::jsonb,
  check_in_time     time not null default '14:00',
  check_out_time    time not null default '12:00',
  free_cancel_hours integer not null default 48 check (free_cancel_hours >= 0),
  tax_rate          numeric(5,4) not null default 0.10 check (tax_rate between 0 and 1),
  service_fee_rate  numeric(5,4) not null default 0 check (service_fee_rate between 0 and 1),
  inventory_source  text not null default 'internal' check (inventory_source in ('internal', 'supplier')),
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create trigger trg_hotels_updated before update on public.hotels
  for each row execute function public.set_updated_at();

create table public.hotel_room_types (
  room_type_id            serial primary key,
  hotel_id                integer not null references public.hotels(hotel_id) on delete cascade,
  name                    text not null,
  description             text,
  max_guests              integer not null default 2 check (max_guests between 1 and 20),
  base_price_per_night    numeric(12,2) not null check (base_price_per_night > 0),
  weekend_price_per_night numeric(12,2) check (weekend_price_per_night > 0),
  total_rooms             integer not null default 0 check (total_rooms >= 0),
  amenities               jsonb not null default '[]'::jsonb,
  image_url               text,
  is_active               boolean not null default true,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);
create index idx_hrt_hotel on public.hotel_room_types (hotel_id);
create trigger trg_hotel_room_types_updated before update on public.hotel_room_types
  for each row execute function public.set_updated_at();

-- Optional date-range overrides of the nightly price (e.g. peak season).
create table public.hotel_seasonal_rates (
  rate_id         serial primary key,
  room_type_id    integer not null references public.hotel_room_types(room_type_id) on delete cascade,
  label           text,
  starts_on       date not null,
  ends_on         date not null,
  price_per_night numeric(12,2) not null check (price_per_night > 0),
  created_at      timestamptz not null default now(),
  check (ends_on >= starts_on)
);
create index idx_hsr_room on public.hotel_seasonal_rates (room_type_id, starts_on, ends_on);

-- ── Restaurants ───────────────────────────────────────────────────────────────
create table public.restaurants (
  restaurant_id        serial primary key,
  name                 text not null,
  description          text,
  address              text,
  city                 text,
  latitude             numeric(10,7),
  longitude            numeric(10,7),
  phone                text,
  image_url            text,
  cuisine              text,
  cuisine_tag          text,
  rating               numeric(2,1) check (rating between 0 and 5),
  avg_price_per_person numeric(12,2) check (avg_price_per_person >= 0),
  tags                 jsonb not null default '[]'::jsonb,
  -- {"mon":[{"open":"12:00","close":"23:00"}], ... } in the restaurant's timezone
  opening_hours        jsonb not null default '{}'::jsonb,
  timezone             text not null default 'Asia/Karachi',
  slot_minutes         integer not null default 30 check (slot_minutes in (15, 30, 60)),
  seats_per_slot       integer not null default 0 check (seats_per_slot >= 0),
  max_party_size       integer not null default 10 check (max_party_size between 1 and 50),
  seating_options      jsonb not null default '["Indoor"]'::jsonb,
  reservation_policy   text,
  accepts_reservations boolean not null default true,
  inventory_source     text not null default 'internal' check (inventory_source in ('internal', 'supplier')),
  is_active            boolean not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create trigger trg_restaurants_updated before update on public.restaurants
  for each row execute function public.set_updated_at();

-- ── Bookings: hotel stay / restaurant reservation details ────────────────────
alter table public.bookings
  add column hotel_id           integer references public.hotels(hotel_id) on delete set null,
  add column room_type_id       integer references public.hotel_room_types(room_type_id) on delete set null,
  add column check_in           date,
  add column check_out          date,
  add column rooms              integer check (rooms between 1 and 10),
  add column guests             integer check (guests between 1 and 50),
  add column restaurant_id      integer references public.restaurants(restaurant_id) on delete set null,
  add column reservation_at     timestamptz,
  add column party_size         integer check (party_size between 1 and 50),
  add column seating_preference text,
  add column contact_name       text,
  add column contact_phone      text,
  add column price_breakdown    jsonb,
  add column currency           text not null default 'PKR',
  add column booking_reference  text unique
    default ('SS-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  add constraint bookings_stay_dates_check check (check_out is null or check_in is null or check_out > check_in);

update public.bookings
   set booking_reference = 'SS-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
 where booking_reference is null;

create index idx_booking_hotel_stay on public.bookings (room_type_id, check_in, check_out)
  where room_type_id is not null;
create index idx_booking_restaurant_slot on public.bookings (restaurant_id, reservation_at)
  where restaurant_id is not null;
-- one live reservation per user per restaurant time (blocks double-submits)
create unique index uq_booking_restaurant_user_slot
  on public.bookings (user_id, restaurant_id, reservation_at)
  where restaurant_id is not null and status not in ('Cancelled', 'Refunded');

-- ── Secure group invites ─────────────────────────────────────────────────────
-- Joining a group now always requires its invite code (never the numeric id).
-- Existing random codes stay valid so links already shared keep working.
alter table public.group_bookings
  add column invite_expires_at  timestamptz,
  add column invite_max_uses    integer check (invite_max_uses is null or invite_max_uses > 0),
  add column invite_uses        integer not null default 0 check (invite_uses >= 0),
  add column invite_revoked_at  timestamptz;

-- ── App settings (admin-only; e.g. a USD/PKR rate if USD charging is needed)
create table public.app_settings (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

-- ── RLS ───────────────────────────────────────────────────────────────────────
alter table public.hotels               enable row level security;
alter table public.hotel_room_types     enable row level security;
alter table public.hotel_seasonal_rates enable row level security;
alter table public.restaurants          enable row level security;
alter table public.app_settings         enable row level security;

create policy "anyone reads active hotels" on public.hotels
  for select to anon, authenticated using (is_active);
create policy "anyone reads active room types" on public.hotel_room_types
  for select to anon, authenticated using (is_active);
create policy "anyone reads seasonal rates" on public.hotel_seasonal_rates
  for select to anon, authenticated using (true);
create policy "anyone reads active restaurants" on public.restaurants
  for select to anon, authenticated using (is_active);

do $$
declare t text;
begin
  foreach t in array array['hotels', 'hotel_room_types', 'hotel_seasonal_rates', 'restaurants', 'app_settings'] loop
    execute format(
      'create policy "admin full access" on public.%I for all to authenticated
         using ((select private.is_app_admin())) with check ((select private.is_app_admin()))', t);
  end loop;
end $$;

-- Writes go through the `api` Edge Function (validated, priced server-side).
-- Like every other table, clients reach these only through RLS: everyone may
-- read the active catalogue, only admins may write. bookings already has no
-- client UPDATE policy, so money / inventory columns cannot be edited directly.

-- ── Seed: the listings the app already displayed ─────────────────────────────
insert into public.hotels (name, address, city, latitude, longitude, image_url, category, rating, amenities) values
  ('Serena Hotel Islamabad',   'F-5, Islamabad',              'Islamabad', 33.7174, 73.0629, 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=400&q=80', 'Luxury',   4.8, '["WiFi","Pool","Spa","Restaurant"]'),
  ('Pearl Continental Lahore', 'Mall Road, Lahore',           'Lahore',    31.5498, 74.3444, 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=400&q=80', 'Luxury',   4.6, '["WiFi","Pool","Gym","Restaurant"]'),
  ('Avari Towers Karachi',     'Fatima Jinnah Road, Karachi', 'Karachi',   24.8607, 67.0101, 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&q=80', 'Luxury',   4.5, '["WiFi","Pool","Business Center"]'),
  ('Monal Guest House Murree', 'Mall Road, Murree',           'Murree',    33.9078, 73.3944, 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&q=80', 'Boutique', 4.3, '["WiFi","Mountain View","Breakfast"]'),
  ('PTDC Motel Hunza',         'Karimabad, Hunza',            'Hunza',     36.3136, 74.6402, 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80', 'Budget',   4.1, '["WiFi","Valley View","Parking"]'),
  ('Lockwood Hotel Lahore',    'Gulberg III, Lahore',         'Lahore',    31.5117, 74.3510, 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400&q=80', 'Boutique', 4.4, '["WiFi","Restaurant","Bar"]');

-- One "Standard Room" per hotel at the nightly price the app showed.
-- total_rooms = 5 is a PLACEHOLDER — admins must set real inventory.
insert into public.hotel_room_types (hotel_id, name, max_guests, base_price_per_night, total_rooms)
select h.hotel_id, 'Standard Room', 2, p.price, 5
from public.hotels h
join (values
  ('Serena Hotel Islamabad', 25000), ('Pearl Continental Lahore', 18000),
  ('Avari Towers Karachi', 22000),   ('Monal Guest House Murree', 8000),
  ('PTDC Motel Hunza', 5500),        ('Lockwood Hotel Lahore', 12000)
) as p(name, price) on p.name = h.name;

-- Opening hours / seats_per_slot are PLACEHOLDERS (12:00–23:00 daily,
-- 40 seats per 30-min slot) — admins must set real values.
with hrs as (
  select jsonb_build_object(
    'mon', '[{"open":"12:00","close":"23:00"}]'::jsonb, 'tue', '[{"open":"12:00","close":"23:00"}]'::jsonb,
    'wed', '[{"open":"12:00","close":"23:00"}]'::jsonb, 'thu', '[{"open":"12:00","close":"23:00"}]'::jsonb,
    'fri', '[{"open":"12:00","close":"23:00"}]'::jsonb, 'sat', '[{"open":"12:00","close":"23:00"}]'::jsonb,
    'sun', '[{"open":"12:00","close":"23:00"}]'::jsonb) as h
)
insert into public.restaurants (name, address, city, latitude, longitude, image_url, cuisine, cuisine_tag,
                                rating, avg_price_per_person, tags, opening_hours, seats_per_slot,
                                seating_options, accepts_reservations, reservation_policy)
select r.name, r.address, r.city, r.lat, r.lng, r.img, r.cuisine, r.tag, r.rating, r.avg, r.tags::jsonb,
       case when r.reservable then hrs.h else '{}'::jsonb end,
       case when r.reservable then 40 else 0 end,
       r.seating::jsonb, r.reservable,
       case when r.reservable then 'Free table reservation. Please arrive within 15 minutes of your booked time; cancel any time before it from My Bookings.' end
from hrs, (values
  ('Monal Restaurant',       'Pir Sohawa, Islamabad',        'Islamabad', 33.7551, 73.0898, 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&q=80', 'Pakistani & Continental', 'Pakistani',   4.9, 3000, '["Rooftop","Family","Scenic View"]',   '["Indoor","Rooftop"]', true),
  ('Bundu Khan',             'Main Boulevard, Lahore',       'Lahore',    31.5201, 74.3587, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&q=80', 'Traditional BBQ',         'BBQ',         4.7, 2000, '["BBQ","Dine-in","Takeaway"]',         '["Indoor","Outdoor"]', true),
  ('The Golden Fork',        'Blue Area, Islamabad',         'Islamabad', 33.7280, 73.0883, 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80', 'Continental',             'Continental', 4.5, 2500, '["Fine Dining","Business"]',           '["Indoor"]',           true),
  ('Kolachi Restaurant',     'Do Darya, Karachi',            'Karachi',   24.8138, 67.0291, 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80', 'Pakistani',               'Pakistani',   4.6, 2800, '["Seafood","Sea View","Family"]',      '["Indoor","Outdoor"]', true),
  ('McDonald''s',            'Multiple Locations',           null,        null,    null,    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80', 'Fast Food',               'Fast Food',   4.0, 800,  '["Quick Bite","Takeaway","Delivery"]', '["Indoor"]',           false),
  ('Salt''n Pepper Village', 'Main Canal Bank Road, Lahore', 'Lahore',    31.4792, 74.2917, 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80', 'Pakistani',               'Pakistani',   4.8, 3500, '["Village Theme","Desi","Family"]',    '["Indoor","Outdoor"]', true)
) as r(name, address, city, lat, lng, img, cuisine, tag, rating, avg, tags, seating, reservable);
