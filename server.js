const express = require('express');
const http = require('http');
const socketIo = require('socket.io'); // Import the socket.io library once
const path = require('path'); // Import the path module

const app = express();
const server = http.createServer(app);
const io = socketIo(server); // Create a socket.io instance using the server

const INACTIVITY_TIMEOUT = 300000; // 300,000 milliseconds = 5 minutes
let inactivityTimeout;

const roomConnections = {};

io.on('connection', (socket) => {
  resetInactivityTimeout();

  socket.on('join-room', (room) => {
    socket.join(room);
    roomConnections[room] = roomConnections[room] || [];
    roomConnections[room].push(socket);
    resetInactivityTimeout(); // Reset timer on entering a room
  });

  socket.on('message', (data) => {
    const { room, message } = data;
    io.to(room).emit('message', message);
    resetInactivityTimeout(); // Reset timer on receiving message
  });

  socket.on('play-sound', (data) => {
    const { room } = data;
    io.to(room).emit('play-sound');
    resetInactivityTimeout(); // Reset timer on playing sound
  });

  socket.on('disconnect', () => {
    for (const room in roomConnections) {
      const index = roomConnections[room].indexOf(socket);
      if (index !== -1) {
        roomConnections[room].splice(index, 1);
      }
    }
  });

  socket.on('any-activity', resetInactivityTimeout);
});

app.use(express.static(path.join(__dirname, 'public')));

app.use((req, res, next) => {
  resetInactivityTimeout(); // Reset timer on any request
  next();
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 12345;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

function resetInactivityTimeout() {
  if (inactivityTimeout) {
    clearTimeout(inactivityTimeout);
  }
  inactivityTimeout = setTimeout(() => {
    console.log('No activity detected. Shutting down server...');
    server.close(() => {
      console.log('Server shut down due to inactivity.');
    });
  }, INACTIVITY_TIMEOUT);
}
