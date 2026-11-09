-- ============================================================================
-- SafarSync — auth integration, access-control helpers, RLS, Realtime, Storage
-- ============================================================================

-- Helpers live in a schema that PostgREST does not expose, so they cannot be
-- called as RPCs by clients; they are only used inside policies.
create schema if not exists private;
grant usage on schema private to authenticated, anon;

-- integer users.user_id of the signed-in Supabase Auth user (or null)
create or replace function private.app_user_id()
returns integer
language sql stable security definer
set search_path = ''
as $$
  select u.user_id from public.users u where u.auth_user_id = (select auth.uid());
$$;

create or replace function private.is_app_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
           select 1 from public.users u
           where u.auth_user_id = (select auth.uid()) and u.is_admin and not u.is_blocked)
      or exists (
           select 1 from public.admins a
           where a.auth_user_id = (select auth.uid()) and a.is_active);
$$;

create or replace function private.is_group_member(gid integer)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.group_booking_members m
    join public.users u on u.user_id = m.user_id
    where m.group_booking_id = gid and u.auth_user_id = (select auth.uid()));
$$;

-- Realtime topic authorization.
--   user:<user_id>            → only that user
--   group:<id>                → members of that group (chat)
--   group-tracking:<id>       → members of that group (live location)
--   emergency:admin           → admins only (read); server-only writes
--   broadcast:all             → any signed-in user (read); server-only writes
create or replace function private.can_access_topic(topic text, for_write boolean)
returns boolean
language plpgsql stable security definer
set search_path = ''
as $$
declare
  parts text[] := string_to_array(topic, ':');
  scope text := parts[1];
  ident text := parts[2];
begin
  if scope = 'user' and not for_write then
    return ident ~ '^\d+$' and ident::integer = private.app_user_id();
  elsif scope in ('group', 'group-tracking') then
    return ident ~ '^\d+$'
       and (private.is_group_member(ident::integer) or (not for_write and private.is_app_admin()));
  elsif scope = 'emergency' and ident = 'admin' and not for_write then
    return private.is_app_admin();
  elsif scope = 'broadcast' and ident = 'all' and not for_write then
    return (select auth.uid()) is not null;
  end if;
  return false;
end;
$$;

grant execute on function private.app_user_id()                to authenticated;
grant execute on function private.is_app_admin()               to authenticated;
grant execute on function private.is_group_member(integer)     to authenticated;
grant execute on function private.can_access_topic(text, boolean) to authenticated;

-- ============================================================================
-- Supabase Auth → public.users profile row
-- ============================================================================
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  meta     jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  provider text  := lower(coalesce(new.raw_app_meta_data->>'provider', 'email'));
  mail     text  := lower(coalesce(new.email, new.id::text || '@users.safarsync.app'));
begin
  insert into public.users (auth_user_id, email, full_name, phone_number, blood_group,
                            profile_picture_url, auth_provider, last_login_at)
  values (
    new.id,
    mail,
    coalesce(nullif(trim(meta->>'full_name'), ''), nullif(trim(meta->>'name'), ''), split_part(mail, '@', 1)),
    nullif(trim(meta->>'phone_number'), ''),
    nullif(trim(meta->>'blood_group'), ''),
    coalesce(meta->>'avatar_url', meta->>'picture'),
    case provider when 'google' then 'GOOGLE' when 'apple' then 'APPLE'
                  when 'facebook' then 'FACEBOOK' else 'EMAIL' end,
    now()
  )
  -- A pre-existing (e.g. migrated) profile with the same email is linked,
  -- never duplicated.
  on conflict (email) do update
    set auth_user_id = excluded.auth_user_id
    where public.users.auth_user_id is null;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

-- Keep the profile email in sync if the user changes it in Supabase Auth.
create or replace function private.handle_auth_user_email_change()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if new.email is distinct from old.email and new.email is not null then
    update public.users set email = lower(new.email) where auth_user_id = new.id;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row execute function private.handle_auth_user_email_change();

-- ============================================================================
-- Row Level Security
--
-- All application reads/writes go through the `api` Edge Function, which
-- authenticates the Supabase JWT and enforces the same authorization rules as
-- the old Express backend. RLS is the second layer: anything reachable with the
-- publishable key directly is limited to the caller's own rows.
-- ============================================================================

do $$
declare t text;
begin
  foreach t in array array[
    'users','admins','destinations','user_preferences','weather_cache','tour_packages',
    'bookings','group_bookings','group_booking_members','group_invitations',
    'group_chat_messages','group_tracking_sessions','payments','transactions','routes',
    'route_stops','wishlists','reviews','budget_plans','emergency_contacts',
    'emergency_alerts','sos_alerts','emergency_events','emergency_tracking',
    'notifications','fcm_tokens','user_location_updates','ai_chat_history',
    'mental_health_chat_history','ai_recommendations','virtual_tours',
    'virtual_tour_scenes','virtual_tour_hotspots','admin_activity_logs','admin_logs']
  loop
    execute format('alter table public.%I enable row level security', t);
    -- admins have full access everywhere
    execute format(
      'create policy "admin full access" on public.%I for all to authenticated
         using ((select private.is_app_admin())) with check ((select private.is_app_admin()))', t);
  end loop;
end $$;

-- ── users ───────────────────────────────────────────────────────────────────
create policy "users read own profile" on public.users
  for select to authenticated using (auth_user_id = (select auth.uid()));
create policy "users update own profile" on public.users
  for update to authenticated
  using (auth_user_id = (select auth.uid()))
  with check (auth_user_id = (select auth.uid()));
-- only profile fields are client-writable; flags such as is_admin/is_blocked
-- can never be changed by the user themselves
revoke update on public.users from authenticated, anon;
grant update (full_name, phone_number, city, bio, blood_group, profile_picture_url, theme_preference)
  on public.users to authenticated;
revoke insert, delete on public.users from authenticated, anon;

create policy "admins read own row" on public.admins
  for select to authenticated using (auth_user_id = (select auth.uid()));

-- ── public catalogue data ───────────────────────────────────────────────────
create policy "anyone reads destinations" on public.destinations
  for select to anon, authenticated using (true);
create policy "anyone reads active packages" on public.tour_packages
  for select to anon, authenticated using (is_active);
create policy "anyone reads active tours" on public.virtual_tours
  for select to anon, authenticated using (is_active);
create policy "anyone reads tour scenes" on public.virtual_tour_scenes
  for select to anon, authenticated
  using (exists (select 1 from public.virtual_tours t where t.id = tour_id and t.is_active));
create policy "anyone reads tour hotspots" on public.virtual_tour_hotspots
  for select to anon, authenticated
  using (exists (select 1 from public.virtual_tour_scenes s
                 join public.virtual_tours t on t.id = s.tour_id
                 where s.id = scene_id and t.is_active));
create policy "anyone reads reviews" on public.reviews
  for select to anon, authenticated using (true);
create policy "users write own reviews" on public.reviews
  for insert to authenticated with check (user_id = (select private.app_user_id()));
create policy "users update own reviews" on public.reviews
  for update to authenticated using (user_id = (select private.app_user_id()))
  with check (user_id = (select private.app_user_id()));
create policy "users delete own reviews" on public.reviews
  for delete to authenticated using (user_id = (select private.app_user_id()));

-- ── owner-only CRUD tables ──────────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['wishlists','emergency_contacts','routes','user_preferences','fcm_tokens']
  loop
    execute format('create policy "owner select" on public.%I for select to authenticated
                      using (user_id = (select private.app_user_id()))', t);
    execute format('create policy "owner insert" on public.%I for insert to authenticated
                      with check (user_id = (select private.app_user_id()))', t);
    execute format('create policy "owner update" on public.%I for update to authenticated
                      using (user_id = (select private.app_user_id()))
                      with check (user_id = (select private.app_user_id()))', t);
    execute format('create policy "owner delete" on public.%I for delete to authenticated
                      using (user_id = (select private.app_user_id()))', t);
  end loop;
end $$;

create policy "route owner manages stops" on public.route_stops
  for all to authenticated
  using (exists (select 1 from public.routes r where r.route_id = route_stops.route_id
                 and r.user_id = (select private.app_user_id())))
  with check (exists (select 1 from public.routes r where r.route_id = route_stops.route_id
                      and r.user_id = (select private.app_user_id())));
create policy "anyone reads public routes" on public.routes
  for select to authenticated using (is_public);

-- ── owner read-only (writes are validated server-side by the api function) ──
do $$
declare t text;
begin
  foreach t in array array['bookings','payments','budget_plans','emergency_alerts','sos_alerts',
                           'emergency_events','ai_chat_history','mental_health_chat_history',
                           'ai_recommendations']
  loop
    execute format('create policy "owner select" on public.%I for select to authenticated
                      using (user_id = (select private.app_user_id()))', t);
  end loop;
end $$;

create policy "owner deletes own ai history" on public.ai_chat_history
  for delete to authenticated using (user_id = (select private.app_user_id()));

create policy "owner reads own transactions" on public.transactions
  for select to authenticated
  using (exists (select 1 from public.payments p where p.id = payment_id
                 and p.user_id = (select private.app_user_id())));

create policy "owner reads own tracking points" on public.emergency_tracking
  for select to authenticated
  using (exists (select 1 from public.emergency_alerts a where a.id = emergency_id
                 and a.user_id = (select private.app_user_id())));

-- ── notifications: read / mark read / delete own ────────────────────────────
create policy "owner select" on public.notifications
  for select to authenticated using (user_id = (select private.app_user_id()));
create policy "owner marks read" on public.notifications
  for update to authenticated using (user_id = (select private.app_user_id()))
  with check (user_id = (select private.app_user_id()));
create policy "owner delete" on public.notifications
  for delete to authenticated using (user_id = (select private.app_user_id()));

-- ── location history: only your own pings ───────────────────────────────────
create policy "owner reads own locations" on public.user_location_updates
  for select to authenticated
  using (user_identifier = 'user_' || (select private.app_user_id())::text);

-- ── groups: visible to members ──────────────────────────────────────────────
create policy "members read group" on public.group_bookings
  for select to authenticated
  using (created_by = (select private.app_user_id()) or (select private.is_group_member(group_booking_id)));
create policy "members read membership" on public.group_booking_members
  for select to authenticated using ((select private.is_group_member(group_booking_id)));
create policy "members read tracking sessions" on public.group_tracking_sessions
  for select to authenticated using ((select private.is_group_member(group_booking_id)));
create policy "members read chat" on public.group_chat_messages
  for select to authenticated using ((select private.is_group_member(group_booking_id)));
create policy "members post chat as self" on public.group_chat_messages
  for insert to authenticated
  with check (user_id = (select private.app_user_id()) and (select private.is_group_member(group_booking_id)));
create policy "authors delete own chat" on public.group_chat_messages
  for delete to authenticated using (user_id = (select private.app_user_id()));
create policy "parties read invitations" on public.group_invitations
  for select to authenticated
  using (sender_id = (select private.app_user_id()) or receiver_id = (select private.app_user_id()));

-- admin tables: admin-only (covered by "admin full access"); no other policies.

-- ============================================================================
-- Realtime (private broadcast channels replace the old Socket.io rooms)
-- ============================================================================
create policy "safarsync topic read" on realtime.messages
  for select to authenticated
  using ((select private.can_access_topic(realtime.topic(), false)));
create policy "safarsync topic write" on realtime.messages
  for insert to authenticated
  with check ((select private.can_access_topic(realtime.topic(), true)));

-- ============================================================================
-- Storage: profile pictures
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880,
        array['image/jpeg','image/png','image/webp','image/gif','image/heic'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- objects are stored as avatars/<auth uid>/<file>; users manage only their folder
create policy "avatar owner read" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatar owner upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatar owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatar owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
