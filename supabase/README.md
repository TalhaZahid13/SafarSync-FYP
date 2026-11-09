# SafarSync backend — Supabase

The app no longer needs a local server, MySQL, or any IP address.

```
Flutter app ──HTTPS──► Supabase Cloud (project zjjbnrqtfnewwfxuahga)
                         ├─ Auth            email/password, Google, Apple
                         ├─ Edge Function   `api`  (REST API, replaces lib/backend Express server)
                         ├─ Postgres        35 tables, RLS on every table
                         ├─ Storage         `avatars` bucket (profile photos)
                         └─ Realtime        private broadcast channels (replaces Socket.io)
```

## Layout

| Path | What |
|---|---|
| `migrations/20261110000001_core_schema.sql` | Tables, keys, indexes, `updated_at` triggers (MySQL → Postgres) |
| `migrations/20261110000002_auth_rls_realtime_storage.sql` | Auth→profile trigger, RLS policies, Realtime topic policies, Storage bucket + policies |
| `migrations/20261110000003_seed_reference_data.sql` | Destinations, tour packages, virtual tours, admin role row |
| `functions/api/` | The `api` Edge Function (`index.ts` router, `lib/`, `routes/`) |

## Deploying changes

```bash
npx supabase login
npx supabase link --project-ref zjjbnrqtfnewwfxuahga
npx supabase db push                                  # new migrations
npx supabase functions deploy api --no-verify-jwt     # the function verifies Supabase JWTs itself
```

`--no-verify-jwt` is intentional: the function authenticates every non-public
route against Supabase Auth itself, and also serves public catalogue routes
and the Stripe webhook.

## Edge Function secrets (Dashboard → Edge Functions → Secrets)

| Secret | Needed for | Required? |
|---|---|---|
| `GROQ_API_KEY` | Safar AI chat, wellness chat, budget planner AI, tour narration | yes, for AI features |
| `STRIPE_SECRET_KEY` | Payments + refunds | yes, for payments |
| `STRIPE_WEBHOOK_SECRET` | `POST /functions/v1/api/payments/webhook` | recommended |
| `EMAIL_USER`, `EMAIL_PASS` (`EMAIL_HOST` optional, default smtp.gmail.com) | Invitation + SOS emails (SMTP over port 465) | optional |
| `OWM_API_KEY` | City names in weather (falls back to keyless Open-Meteo) | optional |
| `ADMIN_EMAIL` | Extra SOS email recipient | optional |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` and
`SUPABASE_DB_URL` are injected automatically.

## Realtime topics

| Topic | Who can join (RLS) | Events |
|---|---|---|
| `user:<user_id>` | that user | `notification:new` |
| `group:<group_booking_id>` | group members | `chat:message`, `chat:deleted`, `chat:typing` |
| `group-tracking:<group_booking_id>` | group members | `location:group-updated`, `member:joined`, `tracking:started` |
| `emergency:admin` | admins | `emergency:sos`, `emergency:resolved`, `emergency:event`, `location:*` |
| `broadcast:all` | any signed-in user | `notification:new` (admin broadcasts) |

## Admin accounts

An admin is a normal Supabase Auth user plus **either**
`public.users.is_admin = true` (role `admin`) **or** an active row in
`public.admins` (role `super_admin` / `moderator`). A pending `admins` row
(e.g. the seeded `admin@safarsync.com`) is linked automatically the first time
a *verified* account with that email opens the admin panel.

Promote your own account (SQL editor):

```sql
insert into public.admins (email, full_name, role)
values ('you@example.com', 'Your Name', 'super_admin')
on conflict (email) do update set role = 'super_admin', is_active = true;
```
