# SAFARSYNC DEVELOPER QUICK START GUIDE
## Immediate Implementation Reference

**Purpose:** Get developers started within 30 minutes  
**Target:** Week 1 team orientation  
**Status:** Active Development

---

# WHAT YOU'RE BUILDING

SafarSync is NOT a booking website.

SafarSync is an **AI-powered travel and safety ecosystem** featuring:
- Group travel management
- Real-time location tracking
- AI travel assistance
- Mental health support
- Emergency SOS system
- Payment processing
- Admin monitoring

**Version:** 1.0 (Production Ready)  
**Timeline:** 90 days (3 months)  
**Team Size:** 3 developers

---

# CURRENT PROJECT STATUS

| Aspect | Status | Completion |
|--------|--------|-----------|
| Architecture | ✅ Solid foundation | 60% |
| Database | ⚠️ Partial | 55% |
| Backend APIs | ❌ Many missing | 30% |
| Frontend UI | ✅ Good base | 45% |
| Security | ❌ Critical gaps | 15% |
| AI Integration | ⚠️ Frontend only | 60% |
| **Overall** | ❌ **Incomplete** | **28%** |

**Your Job:** Increase to 100% in 12 weeks

---

# REPOSITORY STRUCTURE

```
SafarSync-FYP/
├── lib/
│   ├── backend/                    # Node.js API
│   │   ├── server.js              # Entry point
│   │   ├── app.js                 # Express app
│   │   ├── config/                # Configuration
│   │   │   ├── db.js
│   │   │   ├── jwtConfig.js
│   │   │   └── serverConfig.js
│   │   ├── middleware/            # Auth, validation, error handling
│   │   ├── controllers/           # Business logic (existing: 10 files)
│   │   ├── routes/                # API endpoints (existing: 11 files)
│   │   ├── services/              # ⭐ CREATE THIS (Auth, User, Trip, etc.)
│   │   ├── models/                # Database models
│   │   ├── utils/                 # Utilities
│   │   ├── database_schema.sql     # Database schema
│   │   └── package.json
│   │
│   └── frontend/                   # Flutter app
│       ├── main.dart              # Entry point
│       ├── firebase_options.dart   # Firebase config
│       ├── pubspec.yaml           # Dependencies
│       └── src/
│           ├── auth/              # Auth screens (login, signup, MFA)
│           ├── pages/             # Main app screens (35+ needed)
│           ├── components/        # Reusable UI components
│           ├── utils/             # Services (API, theme, etc.)
│           └── ui/                # Theme & styling
│
├── SAFARSYNC_MASTER_IMPLEMENTATION_PLAN.md   # ⭐ READ THIS FIRST
├── SAFARSYNC_FYP_DEMO_FLOW.md                # Demo scenario
└── DEVELOPER_QUICK_START.md                   # This file

```

---

# HOW TO START (Week 1)

## Step 1: Read These Documents
1. **SAFARSYNC_MASTER_IMPLEMENTATION_PLAN.md** (This week)
2. **This file** (DEVELOPER_QUICK_START.md)
3. Your assigned module details

**Time:** 4 hours

## Step 2: Clone & Setup Environment
```bash
git clone <repo_url>
cd SafarSync-FYP

# Backend setup
cd lib/backend
npm install
cp .env.example .env
# Fill in .env file:
# DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
# JWT_SECRET, PORT, NODE_ENV
npm run dev

# Frontend setup
# (in separate terminal)
cd lib/frontend
flutter pub get
flutter run
```

**Time:** 1 hour

## Step 3: Understand Your Module
- Read your module spec in Master Plan
- Understand database tables
- Review example APIs
- Check Flutter screen requirements

**Time:** 3 hours

## Step 4: First Task (Small Win)
By end of Week 1:
- **Backend:** Create one complete API endpoint
- **Frontend:** Build one screen that calls API
- **Both:** Test end-to-end integration

---

# TEAM ROLES & RESPONSIBILITIES

## Role 1: Backend Lead (Node.js/Database)

**Primary Responsibility:** All API development

**Week 1 Deliverables:**
- ✅ Database schema created & migrated
- ✅ Email verification service
- ✅ Password reset service
- ✅ MFA TOTP implementation
- ✅ 3 complete auth endpoints

**Key Files to Edit:**
```
lib/backend/
├── config/db.js                # Database connection
├── services/authService.js     # ⭐ Create this
├── controllers/authController.js (Update)
├── routes/authRoutes.js        # (Update)
└── middleware/
    ├── authMiddleware.js       # (Update)
    └── validationMiddleware.js # ⭐ Create this
```

**Tech Stack:**
- Node.js 18+
- Express.js 5.x
- MySQL 8.0
- JWT, bcrypt, speakeasy (MFA)

**Testing Tools:**
- Postman (API testing)
- Jest (Unit tests)
- MySQL Workbench (Database)

## Role 2: Frontend Lead (Flutter)

**Primary Responsibility:** All mobile app development

**Week 1 Deliverables:**
- ✅ Splash screen
- ✅ Login screen with error handling
- ✅ Email verification screen
- ✅ Dashboard home screen
- ✅ API integration

**Key Files to Create:**
```
lib/frontend/src/
├── auth/
│   ├── email_verification.dart    # ⭐ Create
│   ├── mfa_setup.dart             # ⭐ Create
│   └── mfa_verification.dart      # ⭐ Create
├── pages/
│   ├── dashboard_home.dart        # ⭐ Create
│   └── my_trips_list.dart         # ⭐ Create
└── utils/
    ├── api_service.dart           # Update
    └── auth_service.dart          # ⭐ Create
```

**Tech Stack:**
- Flutter 3.10+
- Dart
- Provider/Riverpod
- Firebase Auth
- Socket.io client

## Role 3: Fullstack Engineer (DevOps/Admin/Integration)

**Primary Responsibility:** Database, security, admin panel, integration

**Week 1 Deliverables:**
- ✅ Complete database setup
- ✅ Database schema migration
- ✅ Redis cache setup
- ✅ Security configuration
- ✅ Rate limiting implementation

**Key Files to Create:**
```
lib/backend/
├── config/redisConfig.js         # ⭐ Create
├── middleware/rateLimitMiddleware.js # ⭐ Create
├── middleware/securityMiddleware.js  # ⭐ Create
├── utils/encryptionUtils.js      # ⭐ Create
└── database_schema.sql           # ⭐ EXPAND
```

**Tech Stack:**
- Redis
- Docker (for development)
- PM2 (production)
- MySQL migration tools

---

# DAILY WORKFLOW

### Morning (9-10 AM) - Standup
```
Each person reports:
1. What did you complete yesterday?
2. What are you doing today?
3. What blockers do you face?

Format: 15 minutes max
```

### Work (10 AM - 1 PM) - Deep Focus
**Backend Lead:**
- Implement API endpoints
- Write tests
- Update database schema
- Review code

**Frontend Lead:**
- Build screens
- Integrate APIs
- Handle errors
- Test on device

**Fullstack:**
- Setup infrastructure
- Deploy changes
- Monitor performance
- Security audits

### Afternoon (2-4 PM) - Integration Testing
**All Together:**
```
1. Backend pushes new endpoint
2. Frontend integrates and tests
3. Fullstack verifies deployment
4. Document and commit
```

### Evening (4-5 PM) - Daily Review
```
1. What shipped today?
2. Any blockers for tomorrow?
3. Update task board
4. Commit and push
```

---

# CRITICAL FILES YOU MUST KNOW

## Backend Critical Files

### 1. server.js
**What it does:** Express server setup with Socket.io  
**Edit:** Add new service initializations  
**Example:**
```javascript
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

global.io = io; // Make available to services
```

### 2. config/db.js
**What it does:** MySQL connection pool  
**Edit:** Update for new tables  
**Note:** Create new tables BEFORE code

### 3. middleware/authMiddleware.js
**What it does:** JWT verification  
**Update:** Add role checking
```javascript
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

const authorize = (roles = []) => {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'No user' });
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
};
```

### 4. controllers/* - THESE WILL EXPAND
**What they do:** Business logic  
**Current state:** Mostly stubs  
**Your job:** Fill them out

## Frontend Critical Files

### 1. main.dart
**What it does:** App initialization  
**Edit:** Auth gate logic  
```dart
class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  _checkAuthStatus() async {
    // Check if user is logged in
    final token = await SharedPreferences.getInstance();
    final savedToken = token.getString('auth_token');
    
    if (savedToken != null) {
      // Token exists, go to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // No token, go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### 2. utils/api_service.dart
**What it does:** HTTP client for APIs  
**Current state:** Basic implementation  
**Update:** Add all endpoints
```dart
class ApiService {
  static const String baseUrl = 'https://api.safarsync.com/v1';
  
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired, refresh
        await _refreshToken();
        return post(endpoint, body); // Retry
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return { 'error': e.toString() };
    }
  }

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  static Future<void> _refreshToken() async {
    // Call backend refresh endpoint
    // Update local token
  }
}
```

---

# CRITICAL DEVELOPMENT RULES

## Rule 1: Database First
**Before writing ANY API code:**
1. Create/update table in database_schema.sql
2. Run migration
3. Verify table in MySQL
4. Then write API

**Example:**
```sql
-- Add to database_schema.sql
CREATE TABLE IF NOT EXISTS trips (
  trip_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_id INT NOT NULL,
  trip_name VARCHAR(255) NOT NULL,
  -- ... more fields
  FOREIGN KEY (organizer_id) REFERENCES users(user_id)
);

-- In Node.js backend
router.post('/trips', authenticate, (req, res) => {
  const query = `INSERT INTO trips (organizer_id, trip_name, ...) VALUES (?, ?, ...)`;
  db.query(query, [req.user.userId, req.body.trip_name, ...], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    res.status(201).json({ trip_id: result.insertId });
  });
});
```

## Rule 2: Test Before Commit
```bash
# Backend
npm test

# Frontend
flutter test

# Manual
Postman (test API)
Device emulator (test UI)
```

## Rule 3: Never Commit Credentials
**Always use .env**
```javascript
// WRONG ❌
const password = 'my-super-secret-password';

// RIGHT ✅
const password = process.env.DB_PASSWORD;
```

## Rule 4: API Response Format
**Always return this format:**
```json
{
  "success": true/false,
  "message": "Description",
  "data": { /* actual data */ },
  "errors": { /* validation errors */ }
}
```

## Rule 5: Error Handling
**Catch all errors, don't crash:**
```javascript
try {
  // risky code
} catch (error) {
  console.error('Error:', error);
  res.status(500).json({ 
    success: false, 
    message: 'Server error',
    error: process.env.NODE_ENV === 'development' ? error.message : 'Unknown error'
  });
}
```

---

# WEEK 1 CHECKLIST

### Backend Lead
- [ ] Database schema expanded with 20 new tables
- [ ] Migration scripts created
- [ ] 5 auth endpoints working
- [ ] JWT & bcrypt working
- [ ] Email service configured
- [ ] MFA TOTP implemented
- [ ] Rate limiting middleware added
- [ ] 2 endpoints tested with Postman

### Frontend Lead
- [ ] 3 auth screens built
- [ ] API service configured
- [ ] Login/signup flow working
- [ ] Email verification screen
- [ ] MFA verification screen
- [ ] Dashboard home screen
- [ ] Error handling implemented
- [ ] Navigation working end-to-end

### Fullstack Engineer
- [ ] Database fully set up
- [ ] Redis configured
- [ ] Security headers added
- [ ] CORS configured properly
- [ ] Logging configured
- [ ] Deployment pipeline started
- [ ] Backup strategy tested

**By Friday EOD:** All items checked ✓

---

# COMMON ISSUES & SOLUTIONS

### Issue 1: "Cannot find module"
**Solution:**
```bash
npm install <module>
flutter pub get
```

### Issue 2: "Database connection refused"
**Solution:**
```bash
# Check MySQL is running
mysql -u root -p
# Check connection in db.js
# Verify .env file has correct DB_HOST, DB_USER, DB_PASSWORD
```

### Issue 3: "JWT verification failed"
**Solution:**
```bash
# Check .env JWT_SECRET matches frontend
# Check token format in header: "Bearer <token>"
# Check token expiry (default 1 hour)
```

### Issue 4: "CORS error in frontend"
**Solution:**
```javascript
// In app.js, fix CORS config
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true
}));
```

### Issue 5: "Flutter won't build"
**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk (or ios)
```

---

# PERFORMANCE TARGETS

These are minimum requirements:

| Metric | Target | How |
|--------|--------|-----|
| API Response | <100ms | Database indexes, caching |
| Login | <2 sec | JWT optimization |
| Live Location | <1 sec | Socket.io, Redis |
| AI Response | <3 sec | Groq API (pre-configured) |
| Page Load | <2 sec | Flutter optimization |
| Database Query | <100ms | Proper indexes |

---

# RESOURCES & DOCUMENTATION

## Backend
- Express.js: https://expressjs.com/
- JWT: https://jwt.io/
- MySQL: https://dev.mysql.com/doc/
- Socket.io: https://socket.io/docs/
- bcryptjs: https://github.com/dcodeIO/bcrypt.js
- speakeasy (MFA): https://www.npmjs.com/package/speakeasy

## Frontend
- Flutter: https://flutter.dev/docs
- Provider: https://pub.dev/packages/provider
- Firebase: https://firebase.google.com/docs/flutter/setup
- HTTP: https://pub.dev/packages/http

## Deployment
- Docker: https://docs.docker.com/
- AWS EC2: https://docs.aws.amazon.com/ec2/
- GitHub Actions: https://docs.github.com/en/actions
- Let's Encrypt (HTTPS): https://letsencrypt.org/

## Design
- Material Design 3: https://m3.material.io/
- Figma: https://www.figma.com/
- Design System: (Create your own)

---

# COMMUNICATION

## Where to Ask Questions
1. **Slack #dev:** Quick questions
2. **GitHub Issues:** Bugs and features
3. **Daily Standup:** Blockers
4. **Weekly Review:** Progress check

## Where to Share Progress
1. **GitHub Commits:** Code changes
2. **Pull Requests:** Code review
3. **Trello/Jira:** Task updates
4. **Weekly Report:** Summary

---

# SUCCESS CRITERIA FOR WEEK 1

```
✅ Database: 20+ tables created
✅ Backend: 5+ working auth APIs
✅ Frontend: 3+ screens with navigation
✅ Integration: End-to-end login working
✅ Testing: All tests passing
✅ Documentation: APIs documented
✅ Security: No hardcoded secrets
✅ Performance: <100ms response time
✅ Team: Daily syncs happening
✅ Velocity: On track for 12-week delivery
```

---

# FINAL THOUGHT

SafarSync isn't just another app. It's redefining safe travel in Pakistan.

Your code will potentially help thousands of travelers stay safe, connect with friends, and explore with confidence.

Code with intention. Test with rigor. Ship with pride.

**Let's build something remarkable.** 🚀

---

**Questions?** Check the Master Implementation Plan (link: SAFARSYNC_MASTER_IMPLEMENTATION_PLAN.md)

**Ready to start?** Pick your module and begin Week 1 tasks.

**Need help?** Reach out in daily standup or Slack.

**Let's go!** ⚡

