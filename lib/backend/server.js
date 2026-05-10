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
