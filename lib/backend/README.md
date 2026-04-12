# SafarSync Backend API

A comprehensive Node.js + Express backend for the SafarSync travel planning mobile application.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Running the Server](#running-the-server)
- [API Endpoints](#api-endpoints)
- [Architecture](#architecture)
- [Project Structure](#project-structure)

---

## ✨ Features

✅ **User Authentication** - Firebase + JWT token-based auth  
✅ **Destination Management** - Browse, search, filter destinations  
✅ **Route Planning** - Create, optimize, and manage travel routes  
✅ **Weather Integration** - Real-time weather and forecasts  
✅ **Wishlist Management** - Save favorite destinations  
✅ **AI Recommendations** - Smart travel suggestions  
✅ **Emergency Features** - SOS button and ICE contact management  
✅ **Notifications** - Real-time user notifications  
✅ **Reviews & Ratings** - User reviews and destination ratings  
✅ **Route Optimization** - Weather and traffic-aware routing

---

## 🛠️ Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.x
- **Database**: MySQL 8.0+
- **Authentication**: Firebase Admin SDK + JWT
- **Security**: bcryptjs for password hashing
- **CORS**: Enabled for cross-origin requests
- **Environment**: dotenv for configuration

---

## 📦 Installation

### Prerequisites

- Node.js 18 or higher
- MySQL Server 8.0+
- npm or yarn

### Steps

1. **Clone and navigate to backend**

```bash
cd lib/backend
```

2. **Install dependencies**

```bash
npm install
```

3. **Create `.env` file** (copy from `.env.example` if available)

```bash
cp .env.example .env
```

4. **Configure environment variables**

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=safarsync
DB_PORT=3306
JWT_SECRET=your_super_secret_jwt_key
NODE_ENV=development
PORT=5000
HOST=localhost
```

---

## 🗄️ Database Setup

### 1. Create MySQL Database

```sql
CREATE DATABASE safarsync;
USE safarsync;
```

### 2. Run Database Schema

```bash
mysql -u root -p safarsync < database_schema.sql
```

Or paste the contents of `database_schema.sql` directly into MySQL client.

### 3. Verify Tables

```sql
SHOW TABLES;
DESCRIBE users;
```

---

## 🚀 Running the Server

### Development Mode (with auto-reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

### Expected Output

```
✅ Server running on http://localhost:5000
Environment: development
```

### Test Health Check

```bash
curl http://localhost:5000/health
```

Response:

```json
{
  "status": "OK",
  "timestamp": "2024-04-12T09:30:00.000Z"
}
```

---

## 📡 API Endpoints

### Authentication Endpoints

```
POST   /api/auth/login              - Login user
POST   /api/auth/signup             - Register new user
POST   /api/auth/refresh-token      - Refresh JWT token
POST   /api/auth/logout             - Logout user
```

### User Endpoints

```
GET    /api/users/me                - Get current user
PUT    /api/users/me                - Update user profile
GET    /api/users/:id               - Get user by ID
DELETE /api/users/me                - Delete account
```

### Destination Endpoints

```
GET    /api/destinations            - List all destinations
GET    /api/destinations/:id        - Get destination details
GET    /api/destinations/search     - Search destinations
POST   /api/destinations            - Create destination (admin)
PUT    /api/destinations/:id        - Update destination (admin)
DELETE /api/destinations/:id        - Delete destination (admin)
GET    /api/destinations/category/:category - Get by category
GET    /api/destinations/popular/trending   - Popular destinations
```

### Route Endpoints

```
POST   /api/routes                  - Create route
GET    /api/routes                  - Get user's routes
GET    /api/routes/:id              - Get route details
PUT    /api/routes/:id              - Update route
DELETE /api/routes/:id              - Delete route
POST   /api/routes/:id/optimize     - Optimize route
POST   /api/routes/:id/stops        - Add stop to route
GET    /api/routes/public/trending  - Get public routes
```

### Wishlist Endpoints

```
GET    /api/wishlist                - Get user's wishlist
POST   /api/wishlist                - Add to wishlist
DELETE /api/wishlist/:destinationId - Remove from wishlist
GET    /api/wishlist/check/:destinationId - Check if saved
PUT    /api/wishlist/:destinationId - Update wishlist item
```

### Weather Endpoints

```
GET    /api/weather/:lat/:lng       - Get current weather
GET    /api/weather/:lat/:lng/forecast - Get forecast
POST   /api/weather/batch           - Get multiple locations
```

### AI Endpoints

```
POST   /api/ai/chat                 - Send message to AI
GET    /api/ai/recommendations      - Get recommendations
GET    /api/ai/history              - Get chat history
DELETE /api/ai/history              - Clear chat history
POST   /api/ai/recommendations/:id/rate - Rate recommendation
```

### Emergency Endpoints

```
POST   /api/emergency/sos           - Trigger SOS
GET    /api/emergency/contacts      - Get ICE contacts
POST   /api/emergency/contacts      - Add contact
PUT    /api/emergency/contacts/:id  - Update contact
DELETE /api/emergency/contacts/:id  - Delete contact
```

### Notification Endpoints

```
GET    /api/notifications           - Get notifications
PUT    /api/notifications/:id/read  - Mark as read
DELETE /api/notifications/:id       - Delete notification
PUT    /api/notifications/read/all  - Mark all as read
```

---

## 🏗️ Architecture

### MVC Pattern

```
Request
   ↓
Router (Route)
   ↓
Controller (Business Logic)
   ↓
Service/Model (Data Access)
   ↓
Database (MySQL)
   ↓
Response
```

### Middleware Stack

1. **CORS** - Cross-origin resource sharing
2. **Body Parser** - JSON request parsing
3. **Request Logger** - Log all requests
4. **Auth Middleware** - JWT verification (protected routes)
5. **Error Handler** - Centralized error handling

---

## 📂 Project Structure

```
lib/backend/
├── config/
│   ├── db.js                      - MySQL connection pool
│   └── jwtConfig.js               - JWT configuration
├── controllers/
│   ├── authController.js          - Auth logic
│   ├── userController.js          - User management
│   ├── destinationController.js   - Destination CRUD
│   ├── routeController.js         - Route management
│   ├── wishlistController.js      - Wishlist operations
│   ├── weatherController.js       - Weather API
│   ├── aiController.js            - AI chat & recommendations
│   ├── emergencyController.js     - Emergency features
│   └── notificationController.js  - Notifications
├── routes/
│   ├── authRoutes.js              - Auth endpoints
│   ├── userRoutes.js              - User endpoints
│   ├── destinationRoutes.js       - Destination endpoints
│   ├── routeRoutes.js             - Route endpoints
│   ├── wishlistRoutes.js          - Wishlist endpoints
│   ├── weatherRoutes.js           - Weather endpoints
│   ├── aiRoutes.js                - AI endpoints
│   ├── emergencyRoutes.js         - Emergency endpoints
│   └── notificationRoutes.js      - Notification endpoints
├── middleware/
│   ├── authMiddleware.js          - JWT verification
│   ├── errorMiddleware.js         - Error handling
│   └── corsMiddleware.js          - CORS configuration
├── models/
│   ├── User.js
│   ├── Destination.js
│   ├── Route.js
│   ├── Wishlist.js
│   └── ...
├── services/
│   ├── userService.js
│   ├── routeService.js
│   ├── weatherService.js
│   ├── aiService.js
│   └── ...
├── utils/
│   ├── validators.js              - Input validation
│   ├── constants.js               - App constants
│   └── helpers.js                 - Helper functions
├── app.js                         - Express app setup
├── server.js                      - Server entry point
├── database_schema.sql            - MySQL schema
├── .env                           - Environment variables
├── .env.example                   - Environment template
├── package.json                   - Dependencies
└── README.md                      - Documentation
```

---

## 🔐 Authentication Flow

### Login/Signup

1. User provides credentials (email, password)
2. Backend verifies with Firebase Authentication
3. Backend generates JWT token
4. Token returned to client
5. Client includes token in Authorization header for subsequent requests

### Protected Routes

All routes with `authenticate` middleware require JWT token:

```
Header: Authorization: Bearer <JWT_TOKEN>
```

---

## 🗄️ Database Schema Overview

### Core Tables

- **users** - User profiles and authentication
- **destinations** - Places/attractions database
- **routes** - Travel routes created by users
- **route_stops** - Waypoints in routes

### Feature Tables

- **wishlists** - Saved destinations
- **reviews** - User reviews and ratings
- **emergency_contacts** - ICE information
- **ai_chat_history** - AI conversation logs
- **notifications** - User notifications
- **weather_cache** - Cached weather data
- **user_preferences** - User settings

---

## 🚀 Deployment Checklist

- [ ] Update `.env` with production values
- [ ] Set `NODE_ENV=production`
- [ ] Update `JWT_SECRET` to a strong value
- [ ] Configure database backups
- [ ] Setup SSL/HTTPS
- [ ] Enable rate limiting
- [ ] Setup logging
- [ ] Configure CORS for production domain
- [ ] Test all endpoints
- [ ] Setup monitoring and alerting

---

## 📝 Common Issues & Solutions

### Database Connection Failed

```
Error: connect ECONNREFUSED 127.0.0.1:3306
Solution: Ensure MySQL is running and credentials are correct
```

### JWT Token Invalid

```
Error: Invalid or expired token
Solution: Check token format and expiration time
```

### CORS Error

```
Error: Access to XMLHttpRequest blocked by CORS policy
Solution: Verify CORS origins in app.js
```

---

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Create a pull request

---

## 📞 Support

For issues or questions, please open a GitHub issue or contact the development team.

---

**Status**: Production Ready ✅  
**Last Updated**: 2026-04-12  
**Version**: 1.0.0
