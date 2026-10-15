<div align="center">

<img src="assets/images/logo.png" alt="SafarSync Logo" width="120" height="120" style="border-radius:50%"/>

# SafarSync

### Your Smart Travel Companion for Pakistan

*AI-powered travel planning · Live group tracking · Emergency SOS · Offline maps*

---

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://stripe.com)

[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=flat-square)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square)](CONTRIBUTING.md)

</div>

---

## What is SafarSync?

**SafarSync** is a full-stack mobile travel companion built as a Final Year Project. It combines AI-driven budget planning, real-time group coordination, offline map access, and emergency safety tools into a single app designed for travellers in Pakistan.

The app has a **Flutter** mobile frontend and a **Node.js / Express** REST API backend, backed by **MySQL**, authenticated via **Firebase**, and enhanced with **Groq AI** (Llama 3.3 70B), **Stripe** payments, and **Socket.io** live tracking.

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
- **Group Live Tracking** — Real-time GPS sharing across all group members via Socket.io
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
| Authentication | Firebase Auth (Email, Google, Apple) |
| Local Storage | SQLite via `sqflite` |
| Maps | `flutter_map` + OpenStreetMap + `geolocator` |
| Payments | `flutter_stripe` |
| Real-time | `socket_io_client` |
| HTTP | `http` package |
| Offline Maps | `flutter_map_tile_caching` |
| Virtual Tours | `webview_flutter` + Pannellum.js |
| Notifications | `firebase_messaging` + `flutter_local_notifications` |

### Backend (Node.js)
| Layer | Technology |
|---|---|
| Runtime | Node.js 20.x |
| Framework | Express.js |
| Database | MySQL 8.0 via `mysql2` |
| Authentication | Firebase Admin SDK + custom JWT |
| AI | Groq API — Llama 3.3 70B Versatile |
| Payments | Stripe Node.js SDK |
| Real-time | Socket.io |
| Email | Nodemailer |
| Environment | dotenv |

---

## Project Architecture

```
safarsync_mobileapp/
├── lib/
│   ├── frontend/                    # Flutter App
│   │   ├── main.dart                # App entry point, AuthGate, routing
│   │   ├── firebase_options.dart    # Firebase project config
│   │   └── src/
│   │       ├── auth/                # Login (Google / Apple / email), Signup
│   │       ├── pages/               # All 35+ app screens
│   │       │   ├── home_page.dart
│   │       │   ├── explore_page.dart
│   │       │   ├── bookings_page.dart
│   │       │   ├── smart_dashboard_page.dart
│   │       │   ├── sasta_tour_page.dart      # AI Budget Planner
│   │       │   ├── emergency_sos_screen.dart
│   │       │   ├── virtual_tour_player_page.dart
│   │       │   └── ...
│   │       ├── components/          # Reusable widgets
│   │       │   ├── navigation/      # Top + bottom nav bars
│   │       │   ├── emergency/       # Floating SOS button
│   │       │   └── smart/           # Dashboard cards
│   │       ├── utils/
│   │       │   ├── api_service.dart       # All HTTP calls + Firebase exchange
│   │       │   ├── local_database_service.dart  # SQLite offline cache
│   │       │   ├── session_manager.dart   # 7-day session tracking
│   │       │   └── auth_storage.dart      # Secure token storage
│   │       └── ui/
│   │           ├── app_theme.dart         # Light/Dark themes
│   │           └── destination_theme.dart # Dynamic gradient themes
│   │
│   └── backend/                     # Node.js API
│       ├── server.js                # Express app + Socket.io init
│       ├── config/
│       │   └── db.js                # MySQL connection pool
│       ├── middleware/
│       │   └── authMiddleware.js    # JWT + Firebase token verify
│       ├── routes/                  # 22 route files
│       ├── controllers/             # Business logic
│       ├── models/                  # MySQL query functions
│       └── migration_v*.sql         # 16 incremental DB migrations
│
├── pubspec.yaml                     # Flutter dependencies
└── google-services.json             # Firebase Android config
```

---

## Database Schema

The MySQL database is managed through **16 incremental migration files** (`migration_v1.sql` → `migration_v16.sql`). For a fresh install, use `safarsync_complete_migration.sql`.

**Core tables:**

| Table | Purpose |
|---|---|
| `users` | User accounts, Firebase UID, profile, blood group |
| `destinations` | Travel destinations with geo-coords, ratings, costs |
| `bookings` | Single destination bookings with payment lifecycle |
| `group_bookings` | Group trips with invite codes |
| `group_booking_members` | Group membership |
| `group_tracking_sessions` | Live GPS sessions |
| `payments` | Stripe payment intents |
| `emergency_contacts` | ICE contacts per user |
| `emergency_alerts` | SOS events with location |
| `tour_packages` | Sasta tour packages |
| `virtual_tours` | 360° tour scene data |
| `wishlist` | Saved destinations |
| `notifications` | In-app notification queue |
| `routes` | User-saved travel routes |
| `admin_users` | Admin accounts |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x → [install guide](https://docs.flutter.dev/get-started/install)
- Node.js 20.x + npm
- MySQL 8.0
- Firebase project with Android app registered
- Groq API key → [console.groq.com](https://console.groq.com)
- Stripe account → [dashboard.stripe.com](https://dashboard.stripe.com)

---

### 1. Clone the repository

```bash
git clone https://github.com/TalhaZahid1/SafarSync-FYP.git
cd SafarSync-FYP
```

### 2. Set up the backend

```bash
cd lib/backend
npm install
```

Create a `.env` file in `lib/backend/`:

```env
# Server
PORT=5000

# MySQL
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=safarsync

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# JWT
JWT_SECRET=your_super_secret_jwt_key_min_32_chars

# Groq AI
GROQ_API_KEY=gsk_...

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your@gmail.com
EMAIL_PASS=your_app_password
```

### 3. Set up the database

```bash
# Create the database
mysql -u root -p -e "CREATE DATABASE safarsync;"

# Run the complete migration (fresh install)
mysql -u root -p safarsync < lib/backend/safarsync_complete_migration.sql

# OR apply migrations incrementally
mysql -u root -p safarsync < lib/backend/migration_v1.sql
# ... repeat for v2 through v16
```

### 4. Start the backend

```bash
cd lib/backend
node server.js
# Server running on http://localhost:5000
```

### 5. Set up Flutter

```bash
# From project root
flutter pub get
```

Add your `google-services.json` (Firebase Android config) to the project root.

Update `lib/frontend/src/utils/app_config.dart`:
```dart
static const String stripePublishableKey = 'pk_test_YOUR_KEY';
```

### 6. Point the app at the hosted backend

The app has **no server/IP setup screen**. The backend URL is compiled in from
`env/production.json` (copy `env/production.example.json`):

```json
{ "API_BASE_URL": "https://safarsync-api.onrender.com/api" }
```

Release builds require `https://`. (Debug builds also accept `http://` for a
local dev server, e.g. `http://10.0.2.2:5000/api` on the Android emulator.)

### 7. Run / build the app

```bash
flutter run --dart-define-from-file=env/production.json
flutter build apk --release --dart-define-from-file=env/production.json
```

Users then just tap **Continue with Google** — no PC server, no shared Wi-Fi.

---

## API Endpoints Summary

The backend exposes **22 route groups** under `/api/`:

| Route Group | Endpoints | Description |
|---|---|---|
| `/auth` | POST login, signup, firebase-exchange | Authentication + Firebase token exchange |
| `/admin/auth` | POST login, forgot-password, reset | Admin authentication |
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
POST /api/bookings/create → status: Pending
        ↓
PaymentPage (Stripe) → POST /api/payments/create-intent
        ↓
Stripe Payment Sheet → confirm payment
        ↓
Webhook: POST /api/payments/webhook → status: Confirmed
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
SOS Alert → POST /api/emergency/trigger → FCM push to emergency contacts
        ↓
Real-time location broadcast to contacts
```

---

## AI Budget Planner Flow

```
User enters: budget · travelers · days · start city · preferences
        ↓
POST /api/tours/budget-plan (35s timeout for AI)
        ↓
Backend queries affordable destinations from MySQL
        ↓
Groq AI (Llama 3.3 70B) generates:
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

## Environment Variables Reference

| Variable | Required | Description |
|---|---|---|
| `PORT` | No (default 5000) | Express server port |
| `DB_HOST` | Yes | MySQL host |
| `DB_USER` | Yes | MySQL username |
| `DB_PASSWORD` | Yes | MySQL password |
| `DB_NAME` | Yes | MySQL database name |
| `FIREBASE_PROJECT_ID` | Yes | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | Yes | Service account email |
| `FIREBASE_PRIVATE_KEY` | Yes | Service account private key |
| `JWT_SECRET` | Yes | JWT signing secret (32+ chars) |
| `GROQ_API_KEY` | Yes | Groq API key for AI features |
| `STRIPE_SECRET_KEY` | Yes | Stripe secret key |
| `STRIPE_WEBHOOK_SECRET` | Yes | Stripe webhook signing secret |
| `EMAIL_HOST` | No | SMTP host for email notifications |
| `EMAIL_USER` | No | SMTP username |
| `EMAIL_PASS` | No | SMTP password |

---

## Database Migrations

Migrations are numbered and applied incrementally:

| Migration | Changes |
|---|---|
| `v1–v3` | Base schema: users, destinations, routes, wishlist |
| `v4` | Booking lifecycle columns, payment tables |
| `v5` | Virtual tours schema |
| `v6` | Group chat, group tracking |
| `v7` | Dynamic destination themes |
| `v8` | Virtual tour scenes + hotspots |
| `v9` | SOS multi-option, admin analytics, refund workflow |
| `v10` | Sasta tour packages, budget plan history |
| `v11–v14` | Auth improvements, session management, FCM tokens |
| `v15` | Group invite codes |
| `v16` | Bookings table fix — expanded status ENUM, missing columns |

---

## Known Setup Notes

- **Hosting the backend**: `render.yaml` deploys `lib/backend` to Render as an HTTPS service. Set `NODE_ENV=production` and `FIREBASE_SERVICE_ACCOUNT_KEY`; without the key, production sign-in is refused (tokens are never accepted unverified). See `lib/backend/.env.example`.
- **Google sign-in on Android**: register your debug *and* release SHA-1 fingerprints in Firebase Console → Project settings → Android app, then re-download `android/app/google-services.json`.
- **Offline maps**: Require a map tile download before going offline. Tap the download icon on the Offline Maps screen.
- **Stripe webhooks**: For local testing, use [Stripe CLI](https://stripe.com/docs/stripe-cli): `stripe listen --forward-to localhost:5000/api/payments/webhook`
- **Firebase Admin**: Download the service account JSON from Firebase Console → Project Settings → Service Accounts → Generate new private key.

---

## Team

| Name | Role |
|---|---|
| **Muhammad Talha Zahid** | Full-Stack Developer (Flutter + Node.js) |

**Supervisor**: University Final Year Project — 8th Semester

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

**SafarSync** — Making Pakistan travel smarter, safer, and more affordable.

*Built with Flutter · Powered by AI · Secured by Firebase*

</div>
