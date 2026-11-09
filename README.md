<div align="center">

<img src="assets/images/logo.png" alt="SafarSync Logo" width="120" height="120" style="border-radius:50%"/>

# SafarSync

### Your Smart Travel Companion for Pakistan

*AI-powered travel planning · Live group tracking · Emergency SOS · Offline maps*

---

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Postgres%20%7C%20Auth%20%7C%20Realtime-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://stripe.com)

[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=flat-square)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square)](CONTRIBUTING.md)

</div>

---

## What is SafarSync?

**SafarSync** is a full-stack mobile travel companion built as a Final Year Project. It combines AI-driven budget planning, real-time group coordination, offline map access, and emergency safety tools into a single app designed for travellers in Pakistan.

The app is a **Flutter** mobile frontend running entirely on **Supabase Cloud** (Postgres with Row Level Security, Supabase Auth for email/Google/Apple, Storage, Realtime, and an Edge Function REST API), enhanced with **Groq AI** and **Stripe** payments. No local server, database, or IP address is needed.

---

## Feature Overview

<table>
<tr>
<td width="50%">

### 🤖 AI Features
- **AI Budget Planner** — Enter budget, travelers, days → Groq AI generates a full day-by-day itinerary with cost breakdown and money-saving tips
- **Safar AI Chat** — Conversational AI travel assistant for trip advice, destination info, and planning

### 🗺️ Explore & Navigate
- **Destination Explorer** — Browse & search Pakistan destinations with category filters, ratings, and photos
- **Smart Route Planner** — AI-assisted route generation between destinations
- **Offline Maps** — Download map tiles for use without internet
- **Live Map** — Real-time GPS position on an interactive map

### 🏨 Bookings & Travel
- **Single Booking** — Book destinations with date, travelers, duration, and Stripe payment
- **Group Booking** — Create group trips, invite members via invite code, coordinate as a team
- **Sasta Tour Packages** — Browse AI-curated affordable travel packages

</td>
<td width="50%">

### 👥 Group Travel
- **Groups** — Create/join travel groups with invite codes
- **Group Live Tracking** — Real-time GPS sharing across all group members via Supabase Realtime
- **Group Chat** — In-app messaging within group bookings
- **Group Invitations** — Send/accept/decline join requests

### 🆘 Safety
- **Emergency SOS** — One-tap SOS with GPS location broadcast to emergency contacts
- **Quick Dial Menu** — Ambulance (1122), Police (15), Tourist Police (1422), ICE Contacts
- **Emergency Contacts** — Manage in-case-of-emergency contact list
- **Android Quick-Tile** — SOS accessible from notification shade

### 🌦️ Discover
- **Weather Forecast** — 4-day weather for any destination
- **Virtual Tours** — 360° Pannellum WebView tours with AI narration and hotspots
- **Hotel Finder** — Nearby hotel search
- **Food Spots** — Local food discovery
- **Wellness** — Travel wellness tips

</td>
</tr>
</table>

### Additional Features
| Feature | Description |
|---|---|
| **Smart Dashboard** | Personalized stats: bookings, active trips, budget summary, quick actions |
| **Stripe Payments** | Secure payment for bookings with payment intent + webhook confirmation |
| **Wishlist** | Save destinations to a personal wishlist |
| **Notifications** | Push + in-app notifications for booking updates, group events |
| **Dynamic Themes** | App gradient changes automatically based on active booking destination |
| **Profile & Settings** | Photo upload, blood group, city, dark/light mode |
| **Admin Panel** | Full admin dashboard — bookings, users, analytics, payments, refunds |
| **Offline-first Auth** | Local SQLite caching, session management, 7-day activity timeout |
| **Transaction History** | Full payment history with receipt generation |

---

## Tech Stack

### Frontend (Flutter)
| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Dart) |
| State Management | `Provider` + `ChangeNotifier` |
| Backend client | `supabase_flutter` (Auth, Storage, Realtime, Edge Function calls) |
| Authentication | Supabase Auth: email/password, Google (`google_sign_in`), Apple (`sign_in_with_apple`) |
| Local Storage | SQLite via `sqflite`, `shared_preferences`, `flutter_secure_storage` |
| Maps | `flutter_map` + OpenStreetMap + `geolocator` |
| Payments | `flutter_stripe` |
| Real-time | Supabase Realtime private broadcast channels |
| Virtual Tours | `webview_flutter` + Pannellum.js |
| Notifications | `flutter_local_notifications` + Realtime |

### Backend (Supabase Cloud)
| Layer | Technology |
|---|---|
| Database | Supabase Postgres: 35 tables, RLS enabled on every table |
| API | Edge Function `api` (Deno / TypeScript) |
| Authentication | Supabase Auth (JWT verified inside the function) |
| Real-time | `realtime.send` broadcasts on RLS-protected topics |
| Storage | `avatars` bucket (per-user folders) |
| AI | Groq API (model set by the `GROQ_MODEL` secret) |
| Payments | Stripe REST API + signed webhook |
| Email | SMTP via Nodemailer (optional) |

---

## Project Architecture

```
SafarSync-FYP/
├── lib/
│   ├── main.dart                    # Entry point → frontend/main.dart
│   └── frontend/
│       ├── main.dart                # Supabase init, AuthGate, routing
│       └── src/
│           ├── auth/                # Login (Google / Apple / email), signup, password reset
│           ├── pages/               # App screens (home, explore, bookings, SOS, admin, ...)
│           ├── components/          # Reusable widgets (navigation, emergency, smart, discover, home, ai)
│           ├── ui/                  # Light/dark + dynamic destination themes
│           └── utils/
│               ├── api_service.dart       # All API calls (Supabase + Edge Function)
│               ├── app_auth.dart          # Supabase Auth wrapper
│               ├── realtime_service.dart  # Realtime channels (chat, tracking, SOS)
│               ├── env_config.dart        # Build-time config (--dart-define)
│               ├── local_database_service.dart  # SQLite offline cache
│               └── session_manager.dart   # Session tracking
│
├── supabase/
│   ├── migrations/                  # Schema, RLS/Realtime/Storage policies, seed data
│   ├── functions/api/               # Edge Function REST API
│   └── README.md                    # Backend deploy + secrets guide
├── env/production.example.json      # Build-time config template
├── assets/                          # Logo, explore images, Pannellum viewer
└── pubspec.yaml
```

---

## Database Schema

The Postgres schema lives in `supabase/migrations/` and is applied with `npx supabase db push`.

**Core tables:**

| Table | Purpose |
|---|---|
| `users` | Profiles linked to `auth.users`, blood group, location |
| `destinations` | Travel destinations with geo-coords, ratings, costs |
| `bookings` | Single destination bookings with payment lifecycle |
| `group_bookings` | Group trips with invite codes |
| `group_booking_members` | Group membership |
| `group_chat_messages` | Group chat |
| `group_tracking_sessions` | Live GPS sessions |
| `payments` / `transactions` | Stripe payment intents and ledger |
| `emergency_contacts` | ICE contacts per user |
| `emergency_alerts` | SOS events with location |
| `tour_packages` | Sasta tour packages |
| `virtual_tours` | 360° tour scenes and hotspots |
| `wishlists` | Saved destinations |
| `notifications` | In-app notification queue |
| `routes` | User-saved travel routes |
| `admins` | Admin roles |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x → [install guide](https://docs.flutter.dev/get-started/install)
- A Supabase project (this app uses `zjjbnrqtfnewwfxuahga`)
- Node.js, only for the `npx supabase` CLI when changing the backend

### 1. Clone and install

```bash
git clone https://github.com/TalhaZahid1/SafarSync-FYP.git
cd SafarSync-FYP
flutter pub get
```

### 2. Build-time config

Copy `env/production.example.json` to `env/production.json` and fill in the values
(Supabase URL + publishable key, Google **Web** client ID, Stripe publishable key).
Only public client keys belong here. Never put a service-role key or secret in the app.

### 3. Run / build

```bash
flutter run --dart-define-from-file=env/production.json
flutter build apk --release --dart-define-from-file=env/production.json
flutter build appbundle --release --dart-define-from-file=env/production.json
```

### 4. Backend changes (optional)

See [`supabase/README.md`](supabase/README.md) for migrations, deploying the
`api` Edge Function, Realtime topics, admin setup and the Edge Function secrets
(`GROQ_API_KEY`, `GROQ_MODEL`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, email).

---

## API Endpoints Summary

The `api` Edge Function (`https://<project>.supabase.co/functions/v1/api/...`) exposes these route groups:

| Route Group | Endpoints | Description |
|---|---|---|
| `/auth` | POST session, GET me | Records sign-in, returns the app user id |
| `/admin/auth` | GET me | Admin role check |
| `/users` | GET profile, PUT update, POST photo | User profile management |
| `/destinations` | GET list, GET `:id`, POST, PUT, DELETE | Destination CRUD |
| `/bookings` | POST create, GET list, GET `:id`, PUT status, POST cancel | Booking lifecycle |
| `/group-bookings` | Full CRUD + join/leave/invite | Group trip management |
| `/groups` | GET list, POST create, GET members | Group management |
| `/payments` | POST create-intent, POST confirm, GET history | Stripe payments |
| `/tours` | GET packages, GET `:id`, POST budget-plan | Budget planner + packages |
| `/ai` | POST chat | Groq AI travel assistant |
| `/weather` | GET `/:lat/:lng`, GET forecast | Weather data |
| `/emergency` | POST trigger, POST event, GET list | SOS alerts |
| `/sos` | POST, GET history | SOS event logging |
| `/emergency-contacts` | Full CRUD | ICE contact management |
| `/location` | POST update, GET latest | GPS position |
| `/wishlist` | GET, POST, DELETE, GET check | Wishlist |
| `/notifications` | GET list, PUT read, DELETE | Notifications |
| `/routes` | GET, POST, DELETE | Saved routes |
| `/virtual-tours` | GET list, GET `:id` | 360° tour data |
| `/invitations` | POST send, PUT respond | Group invitations |
| `/group-chat` | GET messages, POST send | Group messaging |
| `/admin` | Full admin dashboard data | Admin panel |

---

## Booking Flow

```
User selects destination → "Book Now"
        ↓
CreateBookingScreen (destination pre-filled)
        ↓
User enters: travelers · dates · duration · notes
        ↓
POST /functions/v1/api/bookings/create → status: Pending
        ↓
PaymentPage (Stripe) → POST /functions/v1/api/payments/create-intent
        ↓
Stripe Payment Sheet → confirm payment
        ↓
Webhook: POST /functions/v1/api/payments/webhook → status: Confirmed
        ↓
Booking Details Screen (receipt, cancel, refund request)
```

---

## Emergency SOS Flow

```
User taps Floating Emergency Button
        ↓
Menu expands: Ambulance 1122 · Police 15 · Tourist Police 1422 · ICE Contacts · SOS Alert
        ↓
Tap any option → GPS location captured → dial / navigate
        ↓
SOS Alert → POST /functions/v1/api/emergency/trigger → email + in-app alert to contacts and admins
        ↓
Real-time location broadcast to contacts
```

---

## AI Budget Planner Flow

```
User enters: budget · travelers · days · start city · preferences
        ↓
POST /functions/v1/api/tours/budget-plan (45s timeout for AI)
        ↓
Edge Function queries affordable destinations from Postgres
        ↓
Groq AI generates:
  - Day-by-day itinerary with activities + costs
  - Recommended destinations
  - Money-saving tips
  - Best travel season
        ↓
Flutter renders: itinerary cards · destination cost cards · tips · included items
```

---

## Screenshots

> *Coming soon — app screenshots will be added here*

| Home | Explore | Budget Planner | Emergency SOS |
|------|---------|----------------|---------------|
| ![home](docs/screenshots/home.png) | ![explore](docs/screenshots/explore.png) | ![planner](docs/screenshots/planner.png) | ![sos](docs/screenshots/sos.png) |

| Booking | Group Trip | Virtual Tour | Smart Dashboard |
|---------|-----------|--------------|-----------------|
| ![booking](docs/screenshots/booking.png) | ![group](docs/screenshots/group.png) | ![tour](docs/screenshots/tour.png) | ![dashboard](docs/screenshots/dashboard.png) |

---

## Known Setup Notes

- **Google sign-in on Android**: needs an Android OAuth client (package `com.safarsync.app` + the signing SHA-1) and a Web OAuth client in the same Google Cloud project. The Web client ID/secret go in Supabase → Authentication → Providers → Google, with "Skip nonce checks" on. Add the Play Console app-signing SHA-1 before release.
- **Auth redirect**: allow-list `io.safarsync.app://login-callback` under Supabase → Authentication → URL Configuration.
- **Offline maps**: require a map tile download before going offline. Tap the download icon on the Offline Maps screen.
- **Stripe webhooks**: point Stripe at `https://<project>.supabase.co/functions/v1/api/payments/webhook`.

---

## Team

| Name | Role |
|---|---|
| **Muhammad Talha Zahid** | Full-Stack Developer (Flutter + Supabase) |

**Supervisor**: University Final Year Project — 8th Semester

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

**SafarSync** — Making Pakistan travel smarter, safer, and more affordable.

*Built with Flutter · Powered by AI · Backed by Supabase*

</div>
