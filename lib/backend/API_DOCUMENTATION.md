# SafarSync API Documentation

Complete REST API documentation for SafarSync Backend.

## Base URL

```
http://localhost:5000/api
```

---

## 🔐 Authentication

All protected endpoints require JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Login

**POST** `/auth/login`

Request:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Signup

**POST** `/auth/signup`

Request:

```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phoneNumber": "123456789",
  "bloodGroup": "O+"
}
```

Response:

```json
{
  "message": "User registered successfully"
}
```

---

## 👤 User Endpoints

### Get Current User

**GET** `/users/me` _(Protected)_

Response:

```json
{
  "user": {
    "user_id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "phone_number": "123456789",
    "blood_group": "O+"
  }
}
```

### Update User Profile

**PUT** `/users/me` _(Protected)_

Request:

```json
{
  "full_name": "John Updated",
  "bio": "Travel enthusiast",
  "profile_picture_url": "https://..."
}
```

Response:

```json
{
  "message": "Profile updated successfully"
}
```

---

## 🏖️ Destination Endpoints

### List All Destinations

**GET** `/destinations`

Query Parameters:

- `page` (default: 1)
- `limit` (default: 10)
- `category` (optional)
- `city` (optional)
- `country` (optional)

Response:

```json
{
  "destinations": [
    {
      "destination_id": 1,
      "name": "Eiffel Tower",
      "city": "Paris",
      "country": "France",
      "latitude": 48.858,
      "longitude": 2.2945,
      "category": "Monument",
      "rating": 4.5,
      "review_count": 1523
    }
  ],
  "page": 1,
  "limit": 10
}
```

### Search Destinations

**GET** `/destinations/search?query=paris`

Response:

```json
{
  "results": [
    {
      "destination_id": 1,
      "name": "Paris",
      "description": "The City of Light...",
      "rating": 4.5
    }
  ]
}
```

### Get Destination Details

**GET** `/destinations/:id`

Response:

```json
{
  "destination": {
    "destination_id": 1,
    "name": "Eiffel Tower",
    "description": "Iconic iron structure...",
    "city": "Paris",
    "country": "France",
    "rating": 4.5,
    "image_url": "https://...",
    "best_time_to_visit": "April-May",
    "average_cost": 25.5
  }
}
```

### Create Destination _(Admin)_

**POST** `/destinations` _(Protected, Admin)_

Request:

```json
{
  "name": "New Place",
  "description": "Description...",
  "latitude": 48.858,
  "longitude": 2.2945,
  "city": "Paris",
  "country": "France",
  "category": "Monument",
  "image_url": "https://...",
  "best_time_to_visit": "April-May",
  "average_cost": 25.5
}
```

Response:

```json
{
  "message": "Destination created successfully",
  "destination_id": 5
}
```

---

## 🗺️ Route Endpoints

### Create Route

**POST** `/routes` _(Protected)_

Request:

```json
{
  "route_name": "Paris Trip",
  "description": "5-day Paris itinerary",
  "start_location": "Orly Airport",
  "end_location": "Charles de Gaulle Airport",
  "start_lat": 48.7626,
  "start_lng": 2.551,
  "end_lat": 49.0097,
  "end_lng": 2.5479,
  "difficulty_level": "Easy",
  "is_public": false
}
```

Response:

```json
{
  "message": "Route created successfully",
  "route_id": 10
}
```

### Get User's Routes

**GET** `/routes` _(Protected)_

Query Parameters:

- `page` (default: 1)
- `limit` (default: 10)

Response:

```json
{
  "routes": [
    {
      "route_id": 10,
      "route_name": "Paris Trip",
      "start_location": "Orly Airport",
      "end_location": "Charles de Gaulle Airport",
      "difficulty_level": "Easy",
      "created_at": "2024-04-12T10:00:00.000Z"
    }
  ],
  "page": 1,
  "limit": 10
}
```

### Get Route Details

**GET** `/routes/:id`

Response:

```json
{
  "route": {
    "route_id": 10,
    "route_name": "Paris Trip",
    "description": "5-day itinerary",
    "total_distance": 250.5,
    "estimated_duration": 1440,
    "weather_optimized": true,
    "traffic_considered": true,
    "rating": 4.8
  }
}
```

### Update Route

**PUT** `/routes/:id` _(Protected)_

Request:

```json
{
  "route_name": "Updated Paris Trip",
  "description": "Updated description",
  "difficulty_level": "Medium"
}
```

Response:

```json
{
  "message": "Route updated successfully"
}
```

### Delete Route

**DELETE** `/routes/:id` _(Protected)_

Response:

```json
{
  "message": "Route deleted successfully"
}
```

### Optimize Route

**POST** `/routes/:id/optimize` _(Protected)_

Response:

```json
{
  "message": "Route optimization applied"
}
```

### Add Stop to Route

**POST** `/routes/:id/stops` _(Protected)_

Request:

```json
{
  "destination_id": 5,
  "stop_order": 1,
  "latitude": 48.861,
  "longitude": 2.2922,
  "stop_name": "Eiffel Tower",
  "duration_at_stop": 120,
  "notes": "Visit observation deck"
}
```

Response:

```json
{
  "message": "Stop added successfully",
  "stop_id": 42
}
```

---

## ❤️ Wishlist Endpoints

### Get Wishlist

**GET** `/wishlist` _(Protected)_

Response:

```json
{
  "wishlist": [
    {
      "wishlist_id": 1,
      "destination_id": 5,
      "name": "Eiffel Tower",
      "priority": "High",
      "planned_visit_date": "2024-06-15",
      "notes": "Must visit"
    }
  ],
  "page": 1,
  "limit": 10
}
```

### Add to Wishlist

**POST** `/wishlist` _(Protected)_

Request:

```json
{
  "destination_id": 5,
  "priority": "High",
  "planned_visit_date": "2024-06-15",
  "notes": "Must visit with family"
}
```

Response:

```json
{
  "message": "Added to wishlist",
  "wishlist_id": 1
}
```

### Remove from Wishlist

**DELETE** `/wishlist/:destinationId` _(Protected)_

Response:

```json
{
  "message": "Removed from wishlist"
}
```

### Check if in Wishlist

**GET** `/wishlist/check/:destinationId` _(Protected)_

Response:

```json
{
  "inWishlist": true
}
```

---

## 🌤️ Weather Endpoints

### Get Current Weather

**GET** `/weather/:lat/:lng`

Response:

```json
{
  "weather": {
    "temperature": 25,
    "condition": "Clear",
    "humidity": 65,
    "wind_speed": 10,
    "uv_index": 6,
    "feels_like": 24
  },
  "cached": false
}
```

### Get Weather Forecast

**GET** `/weather/:lat/:lng/forecast?days=7`

Response:

```json
{
  "forecast": [
    {
      "date": "2024-04-12",
      "high_temp": 28,
      "low_temp": 20,
      "condition": "Sunny",
      "precipitation": 0
    }
  ]
}
```

---

## 🤖 AI Endpoints

### Send Message to AI

**POST** `/ai/chat` _(Protected)_

Request:

```json
{
  "message": "Recommend best places to visit in Paris",
  "context_data": {
    "budget": "high",
    "interests": ["history", "art"]
  }
}
```

Response:

```json
{
  "chat_id": 123,
  "user_message": "Recommend best places to visit in Paris",
  "ai_response": "Based on your interests, I recommend..."
}
```

### Get Recommendations

**GET** `/ai/recommendations` _(Protected)_

Response:

```json
{
  "recommendations": [
    {
      "recommendation_id": 1,
      "destination_id": 5,
      "name": "Eiffel Tower",
      "reason": "Popular monument matching your interests",
      "confidence_score": 0.95
    }
  ]
}
```

### Get Chat History

**GET** `/ai/history` _(Protected)_

Response:

```json
{
  "chatHistory": [
    {
      "chat_id": 123,
      "user_message": "...",
      "ai_response": "...",
      "created_at": "2024-04-12T10:00:00.000Z"
    }
  ]
}
```

---

## 🆘 Emergency Endpoints

### Trigger SOS

**POST** `/emergency/sos` _(Protected)_

Request:

```json
{
  "latitude": 48.8566,
  "longitude": 2.3522,
  "location_description": "Near Eiffel Tower",
  "severity": "High"
}
```

Response:

```json
{
  "message": "SOS activated",
  "event_id": 1,
  "emergency_contacts_notified": 3
}
```

### Get Emergency Contacts

**GET** `/emergency/contacts` _(Protected)_

Response:

```json
{
  "contacts": [
    {
      "contact_id": 1,
      "contact_name": "Mom",
      "contact_phone": "+1234567890",
      "relationship": "Mother",
      "is_primary": true
    }
  ]
}
```

### Add Emergency Contact

**POST** `/emergency/contacts` _(Protected)_

Request:

```json
{
  "contact_name": "Brother",
  "contact_phone": "+0987654321",
  "relationship": "Brother",
  "is_primary": false
}
```

Response:

```json
{
  "message": "Contact added successfully",
  "contact_id": 2
}
```

---

## 🔔 Notification Endpoints

### Get Notifications

**GET** `/notifications` _(Protected)_

Query Parameters:

- `limit` (default: 20)
- `unread_only` (default: false)

Response:

```json
{
  "notifications": [
    {
      "notification_id": 1,
      "title": "Weather Alert",
      "message": "Rain expected in your destination",
      "type": "Weather",
      "is_read": false,
      "created_at": "2024-04-12T10:00:00.000Z"
    }
  ]
}
```

### Mark as Read

**PUT** `/notifications/:id/read` _(Protected)_

Response:

```json
{
  "message": "Notification marked as read"
}
```

### Delete Notification

**DELETE** `/notifications/:id` _(Protected)_

Response:

```json
{
  "message": "Notification deleted"
}
```

---

## ❌ Error Responses

### 400 Bad Request

```json
{
  "error": "Email is required",
  "status": 400
}
```

### 401 Unauthorized

```json
{
  "error": "Invalid or expired token",
  "status": 401
}
```

### 404 Not Found

```json
{
  "error": "Destination not found",
  "status": 404
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal server error",
  "status": 500
}
```

---

## 📝 Request/Response Examples

### Example: Complete User Journey

1. **Sign Up**

```bash
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "pass123",
    "name": "John Doe"
  }'
```

2. **Login**

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "pass123"
  }'
```

3. **Create Route**

```bash
curl -X POST http://localhost:5000/api/routes \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "route_name": "Paris Trip",
    "difficulty_level": "Easy"
  }'
```

---

## 🔄 Rate Limiting

Currently unlimited. Production deployment should implement rate limiting:

- 100 requests per minute for unauthenticated endpoints
- 1000 requests per minute for authenticated endpoints

---

**API Version**: 1.0.0  
**Last Updated**: 2026-04-12  
**Status**: Production Ready ✅
