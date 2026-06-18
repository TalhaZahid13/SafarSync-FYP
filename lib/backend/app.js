const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

// Initialize Firebase Admin SDK (must happen before any route requires it)
const { initFirebaseAdmin } = require('./config/firebaseAdmin');
initFirebaseAdmin();

const app = express();

// ─── Rate limiting ────────────────────────────────────────────────────────────
let rateLimit;
try {
  rateLimit = require('express-rate-limit');
} catch (_) {
  // express-rate-limit not installed yet; skip (run: npm install express-rate-limit)
  rateLimit = null;
}

if (rateLimit) {
  const globalLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 200, standardHeaders: true, legacyHeaders: false });
  const authLimiter  = rateLimit({ windowMs: 15 * 60 * 1000, max: 20,  standardHeaders: true, legacyHeaders: false, message: { error: 'Too many auth attempts, try again later.' } });
  const aiLimiter    = rateLimit({ windowMs: 60 * 1000, max: 30, standardHeaders: true, legacyHeaders: false, message: { error: 'AI rate limit exceeded.' } });
  app.use(globalLimiter);
  app.use('/api/auth', authLimiter);
  app.use('/api/ai',   aiLimiter);
}

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
app.use('/api/admin/auth', require('./routes/adminAuthRoutes')); // public admin auth — must come first
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/emergency-contacts', require('./routes/emergencyContactRoutes'));
app.use('/api/group-chat', require('./routes/groupChatRoutes'));

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
