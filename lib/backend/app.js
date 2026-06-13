const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080', '*'],
  credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Error handling middleware
const { errorHandler } = require('./middleware/errorMiddleware');

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/destinations', require('./routes/destinationRoutes'));
app.use('/api/routes', require('./routes/routeRoutes'));
app.use('/api/wishlist', require('./routes/wishlistRoutes'));
app.use('/api/weather', require('./routes/weatherRoutes'));
app.use('/api/location', require('./routes/locationRoutes'));
app.use('/api/emergency', require('./routes/emergencyRoutes'));
app.use('/api/ai', require('./routes/aiRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/groups', require('./routes/groupRoutes'));
app.use('/api/sos', require('./routes/sosRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/group-bookings', require('./routes/groupBookingRoutes'));
app.use('/api/invitations', require('./routes/invitationRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/emergency-contacts', require('./routes/emergencyContactRoutes'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler middleware
app.use(errorHandler);

module.exports = app;
