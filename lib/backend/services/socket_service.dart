// services/socket_service.dart (FIXED WITH CORRECT ENDPOINT)

import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class SocketService {
  static SocketService? _instance;
  late IO.Socket socket;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Event callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(String)? onUserStoppedTyping;
  Function(bool)? onConnectionStateChange;

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  // 🔧 FIXED: Initialize socket with correct endpoint
  Future<void> initializeSocket() async {
    try {
      final token = await TokenManager.getToken();

      if (token == null) {
        log('❌ Socket: No token found');
        return;
      }

      // 🆕 CORRECT SOCKET URL
      final String serverUrl = 'ws://34.205.160.246:5000';

      log('🔌 Connecting to Socket.io at: $serverUrl');
      log('🔑 Using token: ${token.substring(0, 20)}...');

      // 🔧 FIXED: Socket configuration for WebSocket connection
      socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'], // Only WebSocket for ws:// protocol
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 3000,
        'forceNew': true,
        'timeout': 20000,
        'extraHeaders': {
          'Authorization': 'Bearer $token', // Token in headers
        },
        'auth': {
          'token': token, // Also try in auth
        },
      });

      // 🔧 Enhanced connection event handlers
      socket.onConnect((_) {
        _isConnected = true;
        log('✅ Socket connected successfully to $serverUrl');
        onConnectionStateChange?.call(true);
      });

      socket.onConnectError((error) {
        _isConnected = false;
        log('❌ Socket connection error: $error');

        // More specific error handling
        if (error.toString().contains('timeout')) {
          log('⏰ Connection timeout - server might be down');
        } else if (error.toString().contains('refused')) {
          log('🚫 Connection refused - check server URL and port');
        } else if (error.toString().contains('unauthorized')) {
          log('🔒 Unauthorized - check token validity');
        }

        onConnectionStateChange?.call(false);
      });

      socket.onError((error) {
        log('❌ Socket error: $error');
      });

      socket.onDisconnect((reason) {
        _isConnected = false;
        log('❌ Socket disconnected: $reason');
        onConnectionStateChange?.call(false);
      });

      // 🔧 Message event listeners (server may emit multiple event names)
      void handleIncoming(dynamic data) {
        try {
          log('📨 New message received: $data');
          if (data is Map<String, dynamic>) {
            onMessageReceived?.call(data);
          } else {
            log(
              '⚠️ Received message in unexpected format: ${data.runtimeType}',
            );
          }
        } catch (e) {
          log('❌ Error processing received message: $e');
        }
      }

      // Some servers use 'message', ours emits 'newMessage' on receive
      socket.on('message', handleIncoming);
      socket.on('newMessage', handleIncoming);
      socket.on('newChat', handleIncoming);

      // 🔧 Typing event listeners
      socket.on('typing', (data) {
        try {
          log('⌨️ User typing: $data');
          if (data is Map<String, dynamic>) {
            onUserTyping?.call(data);
          }
        } catch (e) {
          log('❌ Error processing typing event: $e');
        }
      });

      socket.on('stopTyping', (data) {
        try {
          log('⌨️ User stopped typing: $data');
          final email = data['email'] as String? ?? '';
          onUserStoppedTyping?.call(email);
        } catch (e) {
          log('❌ Error processing stop typing event: $e');
        }
      });

      // 🔧 Connection status events
      socket.on('connect', (_) {
        log('🔗 Socket connect event fired');
      });

      socket.on('disconnect', (reason) {
        log('🔗 Socket disconnect event fired: $reason');
      });

      // 🚀 Attempt connection (idempotent)
      if (!_isConnected) {
        socket.connect();
      }
      log('🔌 Socket connection attempt initiated...');
    } catch (e) {
      log('❌ Socket initialization error: $e');
      onConnectionStateChange?.call(false);
    }
  }

  // 🔧 FIXED: Send message with correct format
  void sendMessage({
    required String receiverEmail,
    required String content,
    String? chatId,
  }) async {
    try {
      if (!_isConnected) {
        log('❌ Cannot send message: Socket not connected');
        return;
      }

      // 🆕 EXACT FORMAT as specified
      final messageData = {'receiverEmail': receiverEmail, 'content': content};

      // Add chatId only if provided
      if (chatId != null && chatId.isNotEmpty) {
        messageData['chatId'] = chatId;
      }

      log('📤 Sending message with format: $messageData');
      // Server expects 'sendMessage' event; keep 'message' as fallback
      socket.emit('sendMessage', messageData);
      socket.emit('message', messageData);

      log('✅ Message sent successfully');
    } catch (e) {
      log('❌ Error sending message: $e');
    }
  }

  // 🔧 Send typing indicator
  void sendTyping(String receiverEmail) {
    try {
      if (_isConnected) {
        socket.emit('typing', {'receiverEmail': receiverEmail});
        log('⌨️ Sent typing indicator to: $receiverEmail');
      } else {
        log('❌ Cannot send typing: Socket not connected');
      }
    } catch (e) {
      log('❌ Error sending typing indicator: $e');
    }
  }

  // 🔧 Stop typing indicator
  void stopTyping(String receiverEmail) {
    try {
      if (_isConnected) {
        socket.emit('stopTyping', {'receiverEmail': receiverEmail});
        log('⌨️ Sent stop typing to: $receiverEmail');
      }
    } catch (e) {
      log('❌ Error sending stop typing: $e');
    }
  }

  // 🔧 Disconnect socket
  void disconnect() {
    try {
      if (_isConnected) {
        socket.disconnect();
        _isConnected = false;
        log('🔌 Socket disconnected manually');
      }
    } catch (e) {
      log('❌ Error disconnecting socket: $e');
    }
  }

  // 🔧 Reconnect socket
  Future<void> reconnect() async {
    try {
      log('🔄 Attempting to reconnect socket...');
      if (_isConnected) {
        disconnect();
      }
      await Future.delayed(const Duration(seconds: 2));
      await initializeSocket();
    } catch (e) {
      log('❌ Error reconnecting socket: $e');
    }
  }

  // 🔧 Clear all callbacks
  void clearCallbacks() {
    onMessageReceived = null;
    onUserTyping = null;
    onUserStoppedTyping = null;
    onConnectionStateChange = null;
  }

  // 🔧 Get connection status
  bool get connectionStatus => _isConnected;
}
