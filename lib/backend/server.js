require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';
const displayHost = HOST === '0.0.0.0' ? 'localhost' : HOST;

const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Make io accessible in controllers via global
global.io = io;

io.on('connection', (socket) => {
  console.log(`📡 Client connected: ${socket.id}`);

  // A user can join their own room to receive targeted updates
  socket.on('join:user', (userId) => {
    socket.join(`user:${userId}`);
  });

  // Admin/monitor subscribes to all emergency SOS events
  socket.on('join:emergency-admin', () => {
    socket.join('emergency:admin');
    console.log(`🚨 Client joined emergency:admin room: ${socket.id}`);
  });

  // Join group booking tracking room
  socket.on('join:group-tracking', (groupBookingId) => {
    socket.join(`group-tracking:${groupBookingId}`);
    console.log(`📍 User joined group tracking: ${groupBookingId}`);
  });

  // Leave group booking tracking room
  socket.on('leave:group-tracking', (groupBookingId) => {
    socket.leave(`group-tracking:${groupBookingId}`);
    console.log(`📍 User left group tracking: ${groupBookingId}`);
  });

  // Broadcast location update to group + forward to admin emergency map
  socket.on('location:update-group', (data) => {
    const { group_booking_id, user_id, latitude, longitude, user_name } = data;
    const payload = {
      user_id,
      user_name,
      latitude,
      longitude,
      group_booking_id,
      timestamp: new Date().toISOString(),
    };
    io.to(`group-tracking:${group_booking_id}`).emit('location:group-updated', payload);
    // Admin emergency map receives all group positions to track SOS members live
    io.to('emergency:admin').emit('location:group-updated', payload);
  });

  socket.on('disconnect', () => {
    console.log(`📡 Client disconnected: ${socket.id}`);
  });
});

server.listen(PORT, HOST, () => {
  console.log(`✅ Server running on http://${displayHost}:${PORT}`);
  console.log(`📡 Socket.io live tracking enabled`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Database Name: ${process.env.DB_NAME || 'Not set'}`);
});
