# SafarSync Backend - Setup & Integration Guide

## 🚀 Quick Start Guide

### Step 1: Database Setup

#### On Windows:

1. Open MySQL Command Line or MySQL Workbench
2. Create database:

```sql
CREATE DATABASE safarsync;
USE safarsync;
```

3. Import schema:

```sql
SOURCE lib\backend\database_schema.sql;
```

4. Verify tables:

```sql
SHOW TABLES;
```

Expected tables:

- users
- destinations
- routes
- route_stops
- wishlists
- reviews
- emergency_contacts
- emergency_events
- ai_chat_history
- notifications
- weather_cache
- user_preferences
- ai_recommendations
- Traveler (legacy)
- tour_packages

---

### Step 2: Backend Setup

1. **Navigate to backend**

```bash
cd lib\backend
```

2. **Install dependencies**

```bash
npm install
```

3. **Verify .env configuration**

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=<your_password>
DB_NAME=safarsync
DB_PORT=3306
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
NODE_ENV=development
PORT=5000
HOST=localhost
```

4. **Start backend server**

```bash
npm run dev
```

Expected output:

```
✅ Server running on http://localhost:5000
Environment: development
```

---

### Step 3: Test Backend Endpoints

#### Health Check

```bash
curl http://localhost:5000/health
```

#### Signup

```bash
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d {
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "bloodGroup": "O+"
  }
```

#### Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d {
    "email": "test@example.com",
    "password": "password123"
  }
```

---

### Step 4: Connect Frontend to Backend

Update Flutter app to use backend endpoints.

#### In `frontend/src/services/apiService.dart` (create if doesn't exist):

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<dynamic>> getDestinations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/destinations?limit=20'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['destinations'];
      } else {
        throw Exception('Failed to fetch destinations');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> searchDestinations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/destinations/search?query=$query'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

#### Update pubspec.yaml (add http package):

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.0.0
  firebase_auth: ^4.0.0
  http: ^1.1.0
```

---

## 📊 Database Schema Overview

### Core Relations

```
users (1) ──→ (many) routes
users (1) ──→ (many) wishlists
users (1) ──→ (many) reviews
users (1) ──→ (many) emergency_contacts
users (1) ──→ (many) ai_chat_history
users (1) ──→ (many) notifications
users (1) ──→ (1) user_preferences

routes (1) ──→ (many) route_stops
routes (1) ──→ (many) reviews

destinations (1) ──→ (many) wishlists
destinations (1) ──→ (many) reviews
destinations (1) ──→ (many) route_stops
destinations (1) ──→ (many) ai_recommendations
```

---

## 🔐 Authentication Implementation

### Current Implementation (Firebase)

Your frontend uses Firebase Authentication directly. Backend validates Firebase tokens.

### Hybrid Approach (Recommended)

For better backend control, consider this flow:

1. User provides email/password to Flutter app
2. Firebase authenticates user
3. Firebase returns Firebase ID token
4. Flutter sends Firebase ID token to backend `/auth/login`
5. Backend verifies Firebase token
6. Backend generates JWT token
7. JWT used for subsequent requests

#### Backend Login Implementation:

```javascript
// In authController.js
const verifyFirebaseToken = async (firebaseToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
    return decodedToken;
  } catch (error) {
    throw new Error("Invalid Firebase token");
  }
};

// Usage in login endpoint
app.post("/api/auth/login", async (req, res) => {
  const { firebaseToken } = req.body;

  try {
    const decodedToken = await verifyFirebaseToken(firebaseToken);

    // Get/Create user in MySQL
    const user = await getUserByEmail(decodedToken.email);

    // Generate JWT
    const jwtToken = jwt.sign(
      { userId: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "24h" },
    );

    res.json({ token: jwtToken });
  } catch (error) {
    res.status(401).json({ error: "Authentication failed" });
  }
});
```

---

## 🧪 Testing Endpoints

### Using Postman

1. **Create Postman Collection**
   - Base URL: `http://localhost:5000/api`

2. **Test Flow**
   - POST `/auth/signup` - Register user
   - POST `/auth/login` - Get JWT token
   - Copy token to all subsequent requests in Authorization header
   - Test other endpoints

### Using cURL

```bash
# Signup
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass","name":"User"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass"}'

# Get current user (replace TOKEN with actual token)
curl -X GET http://localhost:5000/api/users/me \
  -H "Authorization: Bearer TOKEN"

# Get destinations
curl -X GET "http://localhost:5000/api/destinations?limit=5"

# Create destination
curl -X POST http://localhost:5000/api/destinations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "name":"New Place",
    "latitude":48.8566,
    "longitude":2.3522,
    "city":"Paris",
    "country":"France"
  }'
```

---

## 📱 Frontend Integration Checklist

- [ ] Add `http` package to pubspec.yaml
- [ ] Create `ApiService` class
- [ ] Replace Firebase login with backend `/api/auth/login`
- [ ] Store JWT token in local storage/secure storage
- [ ] Add token to all API requests in Authorization header
- [ ] Update home page to fetch destinations from backend
- [ ] Update search to call backend search endpoint
- [ ] Connect wishlist to backend endpoints
- [ ] Connect route creation to backend
- [ ] Test all features

---

## 🔄 Migration Path

### Phase 1: Backend Only (Current)

- Backend API ready
- Database schema ready
- Authentication ready

### Phase 2: Frontend Integration

- Connect auth endpoints
- Integrate destination endpoints
- Integrate route endpoints

### Phase 3: Advanced Features

- Weather API integration
- AI/ML recommendations
- Real-time notifications (Socket.io)
- Map integration (Google Maps/Mapbox)

### Phase 4: Production

- Database backups
- Error logging (Sentry)
- Performance monitoring
- Rate limiting
- API caching

---

## 📁 File Structure Summary

```
lib/backend/
├── app.js                        ✅ Express setup
├── server.js                     ✅ Entry point
├── .env                          ✅ Configuration
├── database_schema.sql           ✅ MySQL schema
├── package.json                  ✅ Dependencies
├── README.md                     ✅ Main docs
├── API_DOCUMENTATION.md          ✅ Endpoint docs
├── SETUP_GUIDE.md               ✅ Setup guide
│
├── config/
│   ├── db.js                    ✅ Database connection
│   └── jwtConfig.js             ✅ JWT config
│
├── controllers/
│   ├── authController.js        ✅ Auth logic
│   ├── userController.js        ✅ User management
│   ├── destinationController.js ✅ Destinations
│   ├── routeController.js       ✅ Routes
│   ├── wishlistController.js    ✅ Wishlists
│   ├── weatherController.js     ✅ Weather
│   ├── aiController.js          ✅ AI chat
│   ├── emergencyController.js   ✅ Emergency
│   └── notificationController.js ✅ Notifications
│
├── routes/
│   ├── authRoutes.js            ✅ Auth endpoints
│   ├── userRoutes.js            ✅ User endpoints
│   ├── destinationRoutes.js     ✅ Destination endpoints
│   ├── routeRoutes.js           ✅ Route endpoints
│   ├── wishlistRoutes.js        ✅ Wishlist endpoints
│   ├── weatherRoutes.js         ✅ Weather endpoints
│   ├── aiRoutes.js              ✅ AI endpoints
│   ├── emergencyRoutes.js       ✅ Emergency endpoints
│   └── notificationRoutes.js    ✅ Notification endpoints
│
└── middleware/
    ├── authMiddleware.js        ✅ JWT verification
    └── errorMiddleware.js       ✅ Error handling
```

---

## ⚡ Performance Tips

1. **Database Indexing** - Already configured in schema
2. **Connection Pooling** - Implemented (10 connections)
3. **Caching** - Weather data cached for 3 hours
4. **Pagination** - All list endpoints support pagination
5. **CORS** - Configured for development

---

## 🐛 Troubleshooting

### Server won't start

- Check MySQL is running
- Verify .env credentials
- Check port 5000 is not in use

### Database errors

- Verify schema was imported correctly
- Check user permissions
- Ensure database exists

### API returns 401

- Check JWT token is valid
- Verify Authorization header format
- Token might be expired

### CORS errors

- Ensure frontend URL is in CORS origins in app.js
- Check Content-Type headers

---

## 📞 Next Steps

1. ✅ Database schema created
2. ✅ Backend API completed
3. ✅ Documentation provided
4. ⏭️ **Next**: Setup database and test backend
5. ⏭️ **Then**: Connect frontend to backend APIs

---

**Created**: 2026-04-12  
**Status**: Ready for Integration ✅  
**Version**: 1.0.0
