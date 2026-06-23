# SafarSync Booking System - Implementation Guide

## OVERVIEW

Three major features implemented:
1. **Single Booking** - Individual travel bookings with status tracking
2. **Group Booking** - Multi-member trips with live tracking
3. **Live GPS Tracking** - Real-time location sharing for groups using Socket.io

---

## DATABASE CHANGES

### New Tables Created

**File:** `lib/backend/booking_schema.sql`

#### 1. bookings
```sql
CREATE TABLE bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  destination_id INT NOT NULL,
  booking_type ENUM('single') DEFAULT 'single',
  status ENUM('Planned', 'Active', 'Completed') DEFAULT 'Planned',
  booking_date DATE,
  estimated_duration_days INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE
);
```

#### 2. group_bookings
```sql
CREATE TABLE group_bookings (
  group_booking_id INT AUTO_INCREMENT PRIMARY KEY,
  trip_name VARCHAR(255) NOT NULL,
  created_by INT NOT NULL,
  status ENUM('Planning', 'Active', 'Completed') DEFAULT 'Planning',
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);
```

#### 3. group_booking_members
```sql
CREATE TABLE group_booking_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  user_id INT NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY unique_booking_user (group_booking_id, user_id)
);
```

#### 4. group_booking_destinations (optional)
```sql
CREATE TABLE group_booking_destinations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  destination_id INT NOT NULL,
  stop_order INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE,
  FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE
);
```

#### 5. group_tracking_sessions
```sql
CREATE TABLE group_tracking_sessions (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  group_booking_id INT NOT NULL,
  status ENUM('active', 'paused', 'ended') DEFAULT 'active',
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  FOREIGN KEY (group_booking_id) REFERENCES group_bookings(group_booking_id) ON DELETE CASCADE
);
```

### Run Migrations

```bash
mysql -u [user] -p [database] < lib/backend/booking_schema.sql
```

---

## BACKEND IMPLEMENTATION

### 1. Models

#### File: `lib/backend/models/booking.js`
- `Booking.create()` - Create new booking
- `Booking.getById()` - Get booking with details
- `Booking.getUserBookings()` - Get user's bookings
- `Booking.updateStatus()` - Update booking status

#### File: `lib/backend/models/groupBooking.js`
- `GroupBooking.create()` - Create new group booking
- `GroupBooking.getById()` - Get group booking with members
- `GroupBooking.getUserGroupBookings()` - Get user's group bookings
- `GroupBooking.addMember()` - Add member to group
- `GroupBooking.getMembers()` - Get all members
- `GroupBooking.updateStatus()` - Update group status
- `GroupBooking.getMemberLocations()` - Get real-time locations

### 2. Controllers

#### File: `lib/backend/controllers/bookingController.js`
**Endpoints:**
- `POST /api/bookings/create` - Create booking
- `GET /api/bookings/list` - Get user bookings
- `GET /api/bookings/:booking_id` - Get booking details
- `PUT /api/bookings/:booking_id/status` - Update status
- `GET /api/bookings/admin/stats` - Get booking stats

#### File: `lib/backend/controllers/groupBookingController.js`
**Endpoints:**
- `POST /api/group-bookings/create` - Create group booking
- `GET /api/group-bookings/list` - Get user's groups
- `GET /api/group-bookings/:group_booking_id` - Get group details
- `POST /api/group-bookings/:group_booking_id/join` - Join group
- `GET /api/group-bookings/:group_booking_id/members` - Get members
- `GET /api/group-bookings/:group_booking_id/locations` - Get live locations
- `PUT /api/group-bookings/:group_booking_id/status` - Update status
- `POST /api/group-bookings/tracking/start` - Start tracking
- `GET /api/group-bookings/admin/stats` - Get group stats

### 3. Routes

#### File: `lib/backend/routes/bookingRoutes.js`
```javascript
router.post('/create', authenticate, createBooking);
router.get('/list', authenticate, getUserBookings);
router.get('/:booking_id', authenticate, getBooking);
router.put('/:booking_id/status', authenticate, updateBookingStatus);
router.get('/admin/stats', authenticate, getAdminBookingStats);
```

#### File: `lib/backend/routes/groupBookingRoutes.js`
```javascript
router.post('/create', authenticate, createGroupBooking);
router.get('/list', authenticate, getUserGroupBookings);
router.get('/:group_booking_id', authenticate, getGroupBooking);
router.post('/:group_booking_id/join', authenticate, joinGroupBooking);
router.get('/:group_booking_id/members', authenticate, getGroupBookingMembers);
router.get('/:group_booking_id/locations', authenticate, getGroupMemberLocations);
router.put('/:group_booking_id/status', authenticate, updateGroupBookingStatus);
router.post('/tracking/start', authenticate, startGroupTracking);
router.get('/admin/stats', authenticate, getAdminGroupBookingStats);
```

### 4. Socket.io Integration

**File:** `lib/backend/server.js`

Enhanced with:
```javascript
socket.on('join:group-tracking', (groupBookingId) => {
  socket.join(`group-tracking:${groupBookingId}`);
});

socket.on('location:update-group', (data) => {
  io.to(`group-tracking:${data.group_booking_id}`).emit('location:group-updated', {...});
});
```

### 5. Admin Routes Update

**File:** `lib/backend/routes/adminRoutes.js`

New endpoints:
- `GET /api/admin/bookings/stats` - Booking statistics
- `GET /api/admin/group-bookings/stats` - Group booking statistics

---

## FLUTTER IMPLEMENTATION

### 1. Booking Pages

#### File: `lib/frontend/src/pages/bookings_page.dart`

**Classes:**
- `BookingsPage` - List all user bookings
- `CreateBookingScreen` - Create new booking
- `BookingDetailsScreen` - View booking details with status update

**Features:**
- Display bookings with status (Planned/Active/Completed)
- Create booking with destination selection
- Update booking status
- View booking image and details

### 2. Group Booking Pages

#### File: `lib/frontend/src/pages/group_bookings_page.dart`

**Classes:**
- `GroupBookingsPage` - List all group bookings
- `CreateGroupBookingScreen` - Create new group trip
- `GroupBookingDetailsScreen` - View group details with members
- `GroupLiveTrackingScreen` - Basic tracking interface

**Features:**
- Create group trips with dates
- View group members
- Join existing groups
- Launch live tracking

### 3. Live Tracking Page

#### File: `lib/frontend/src/pages/group_live_tracking_page.dart`

**Features:**
- **Google Maps/Flutter Map Integration**
- **Real-time Marker Display** - All group members visible simultaneously
- **Socket.io Integration** - Live location updates
- **Member Info Sheet** - Click markers to see details
- **Auto Location Update** - Every 10 seconds
- **Horizontal Member List** - Quick view of all members
- **Current User Tracking** - Green marker for self

**Map Functionality:**
```dart
- Markers for each group member with name and location
- Current user marked differently (green)
- Click marker to show member details
- Auto-center on user location
- Update interval: 10 seconds
```

### 4. Dashboard Component

#### File: `lib/frontend/src/components/dashboard/booking_stats_card.dart`

**Features:**
- Display single booking count
- Display group booking count
- Show active trips
- Stats card for home dashboard

---

## API ENDPOINTS

### Booking API

```
POST   /api/bookings/create                 - Create booking
GET    /api/bookings/list                   - Get user bookings
GET    /api/bookings/:booking_id            - Get booking details
PUT    /api/bookings/:booking_id/status     - Update status
GET    /api/bookings/admin/stats            - Admin stats
```

### Group Booking API

```
POST   /api/group-bookings/create                    - Create group
GET    /api/group-bookings/list                      - Get user groups
GET    /api/group-bookings/:group_booking_id         - Get group details
POST   /api/group-bookings/:group_booking_id/join    - Join group
GET    /api/group-bookings/:group_booking_id/members - Get members
GET    /api/group-bookings/:group_booking_id/locations - Get locations
PUT    /api/group-bookings/:group_booking_id/status  - Update status
POST   /api/group-bookings/tracking/start            - Start tracking
GET    /api/group-bookings/admin/stats               - Admin stats
```

### Admin API

```
GET    /api/admin/bookings/stats            - Booking stats
GET    /api/admin/group-bookings/stats      - Group booking stats
GET    /api/admin/dashboard                 - Updated with new stats
```

---

## SOCKET.IO EVENTS

### Client to Server
```javascript
socket.emit('join:group-tracking', groupBookingId);
socket.emit('location:update-group', {
  group_booking_id: number,
  user_id: number,
  latitude: number,
  longitude: number,
  user_name: string
});
socket.emit('leave:group-tracking', groupBookingId);
```

### Server to Client
```javascript
socket.on('location:group-updated', {
  user_id: number,
  user_name: string,
  latitude: number,
  longitude: number,
  timestamp: ISO8601string
});
```

---

## FILES CREATED

### Backend
- `lib/backend/booking_schema.sql` - Database schema
- `lib/backend/booking_queries.sql` - SQL queries reference
- `lib/backend/models/booking.js` - Booking model
- `lib/backend/models/groupBooking.js` - Group booking model
- `lib/backend/controllers/bookingController.js` - Booking controller
- `lib/backend/controllers/groupBookingController.js` - Group booking controller
- `lib/backend/routes/bookingRoutes.js` - Booking routes
- `lib/backend/routes/groupBookingRoutes.js` - Group booking routes

### Frontend
- `lib/frontend/src/pages/bookings_page.dart` - Booking UI
- `lib/frontend/src/pages/group_bookings_page.dart` - Group booking UI
- `lib/frontend/src/pages/group_live_tracking_page.dart` - Live tracking with map
- `lib/frontend/src/components/dashboard/booking_stats_card.dart` - Dashboard widget

### Modified Files
- `lib/backend/app.js` - Added routes
- `lib/backend/server.js` - Enhanced Socket.io
- `lib/backend/routes/adminRoutes.js` - Added stats endpoints

---

## SETUP INSTRUCTIONS

### 1. Database
```bash
mysql -u [user] -p [database] < lib/backend/booking_schema.sql
```

### 2. Backend
```bash
cd lib/backend
npm install
node server.js
```

### 3. Frontend
```bash
flutter pub get
flutter run
```

### 4. Integration Points

Add to Flutter app navigation:
```dart
routes: {
  '/bookings': (context) => const BookingsPage(),
  '/group-bookings': (context) => const GroupBookingsPage(),
  '/group-tracking/:id': (context) => GroupLiveTrackingPage(
    groupBookingId: int.parse(route.pathParams['id']!),
  ),
}
```

Add to home page/dashboard:
```dart
BookingStatsCard()  // In your dashboard
```

---

## TESTING CHECKLIST

- [ ] Create single booking
- [ ] View booking details
- [ ] Update booking status
- [ ] Create group booking
- [ ] Join group booking
- [ ] View group members
- [ ] Start live tracking
- [ ] See all members on map
- [ ] Location updates in real-time
- [ ] Admin stats display correctly
- [ ] Socket.io connections working
- [ ] Member markers update on map

---

## NOTES

- All location updates use existing `user_location_updates` table
- Socket.io rooms: `group-tracking:{groupBookingId}`
- Locations update every 10 seconds
- No complex optimization - demo-ready only
- All status enums clearly defined per feature
- Uses existing authentication middleware
