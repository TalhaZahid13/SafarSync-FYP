// viewmodels/chat_viewmodel.dart (UPDATED FOR YOUR API)

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/models/chat_models.dart';
import 'package:safarsync_mobileapp/backend/repositories/chat_repository.dart';
import 'package:safarsync_mobileapp/backend/services/socket_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';
class ChatViewModel extends ChangeNotifier {
  // Chat list state
  ViewState _chatsState = ViewState.initial;
  ViewState get chatsState => _chatsState;

  List<ChatItem> _chatItems = [];
  List<ChatItem> get chatItems => _chatItems;

  // Messages state
  ViewState _messagesState = ViewState.initial;
  ViewState get messagesState => _messagesState;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Current chat
  String? _currentChatId;
  String? get currentChatId => _currentChatId;

  String? _currentChatEmail;
  String? get currentChatEmail => _currentChatEmail;

  // Socket connection state
  bool _isSocketConnected = false;
  bool get isSocketConnected => _isSocketConnected;

  // Live typing indicator for current peer
  bool _isPeerTyping = false;
  bool get isPeerTyping => _isPeerTyping;

  // Error messages
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Current user email cache
  String? _currentUserEmail;

  // For compatibility with existing ChatView
  ViewState get roomsState => _chatsState;
  List<dynamic> get chatRooms => _chatItems;

  ChatViewModel() {
    _initializeSocket();
    _loadCurrentUserEmail();
  }

  // Initialize socket connection
  Future<void> _initializeSocket() async {
    try {
      final socketService = SocketService.instance;

      socketService.onConnectionStateChange = (isConnected) {
        _isSocketConnected = isConnected;
        notifyListeners();

        if (isConnected) {
          log('✅ Chat: Socket connected');
        } else {
          log('❌ Chat: Socket disconnected');
        }
      };

      socketService.onMessageReceived = (message) {
        _handleNewMessage(message);
      };

      socketService.onUserTyping = (data) {
        try {
          final email =
              (data['email'] ?? data['senderEmail'] ?? data['from']) as String?;
          if (_currentChatEmail != null &&
              (email == null || email == _currentChatEmail)) {
            _isPeerTyping = true;
            notifyListeners();
          }
        } catch (_) {}
      };

      socketService.onUserStoppedTyping = (email) {
        if (_currentChatEmail == null || email == _currentChatEmail) {
          _isPeerTyping = false;
          notifyListeners();
        }
      };

      await socketService.initializeSocket();
    } catch (e) {
      log('❌ Chat ViewModel: Socket initialization error: $e');
    }
  }

  // Load current user email
  Future<void> _loadCurrentUserEmail() async {
    try {
      final user = await TokenManager.getCurrentUser();
      _currentUserEmail = user?.email;
      log('👤 Current user email: $_currentUserEmail');
    } catch (e) {
      log('❌ Error loading current user email: $e');
    }
  }

  // Fetch all chats
  Future<void> fetchChatRooms() async {
    _chatsState = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ChatRepository.getAllChats();

      if (response['success'] == true) {
        _chatItems = response['chats'] as List<ChatItem>;
        _chatsState = _chatItems.isEmpty ? ViewState.empty : ViewState.loaded;
        log('✅ Fetched ${_chatItems.length} chats');
      } else {
        _errorMessage = response['message'];
        _chatsState = ViewState.error;
        log('❌ Failed to fetch chats: ${response['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch chats: ${e.toString()}';
      _chatsState = ViewState.error;
      log('❌ Fetch chats error: $e');
    }

    notifyListeners();
  }

  // Fetch messages for specific chat
  Future<void> fetchChatMessages(String chatId) async {
    _messagesState = ViewState.loading;
    _currentChatId = chatId;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ChatRepository.getChatMessages(chatId: chatId);

      if (response['success'] == true) {
        _messages = response['messages'] as List<ChatMessage>;
        _messagesState = _messages.isEmpty ? ViewState.empty : ViewState.loaded;
        log('✅ Fetched ${_messages.length} messages for chat $chatId');
      } else {
        _errorMessage = response['message'];
        _messagesState = ViewState.error;
        log('❌ Failed to fetch messages: ${response['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch messages: ${e.toString()}';
      _messagesState = ViewState.error;
      log('❌ Fetch messages error: $e');
    }

    notifyListeners();
  }

  // Set or update the current peer email for the active chat
  void setCurrentChatPeer(String email) {
    _currentChatEmail = email;
    log('👥 Current chat peer set to: $email');
  }

  // Start new chat with email
  Future<void> startChatWithEmail(String email, String userName) async {
    _currentChatEmail = email;
    _currentChatId = null; // Will be set when first message is sent
    _messages.clear();
    _messagesState = ViewState.loaded;
    notifyListeners();
    log('💬 Started new chat with: $email ($userName)');
  }

  // Send message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _currentChatEmail == null) return;

    try {
      // 1) Add local message immediately (no awaits)
      final now = DateTime.now();
      final localMessage = ChatMessage(
        messageId: 'local_${now.millisecondsSinceEpoch}',
        senderEmail: _currentUserEmail ?? 'me',
        chatId: _currentChatId ?? '',
        content: content,
        isSent: true,
        createdAt: now,
        updatedAt: now,
        user: ChatUser(
          email: _currentUserEmail ?? 'me',
          firstName: 'Me',
          lastName: '',
          profilePic: null,
        ),
      );

      _messages.add(localMessage);
      _optimisticallyUpdateChatList(
        senderEmail: _currentUserEmail ?? 'me',
        receiverEmail: _currentChatEmail!,
        content: content,
        chatId: _currentChatId,
        createdAt: now,
      );
      notifyListeners();

      // 2) Ensure socket is ready (can await after UI update)
      if (!SocketService.instance.connectionStatus) {
        await SocketService.instance.initializeSocket();
      }

      // 3) Send over socket
      SocketService.instance.sendMessage(
        receiverEmail: _currentChatEmail!,
        content: content,
        chatId: _currentChatId,
      );

      // Optionally still refresh in background later if chatId is missing
      // (skip immediate fetch to keep UI snappy)
    } catch (e) {
      log('❌ Send Message Error: $e');
      _errorMessage = 'Failed to send message';
      notifyListeners();
    }
  }

  // Handle incoming messages from socket
  void _handleNewMessage(Map<String, dynamic> message) async {
    try {
      log('📨 Processing incoming socket message: $message');

      final senderEmail = message['senderEmail'] as String?;
      final receiverEmail = message['receiverEmail'] as String?;
      final content = message['content'] as String?;
      final chatId = message['chatId'] as String?;

      if (content == null || content.isEmpty) {
        log('⚠️ Received message with empty content');
        return;
      }

      // Ensure we have current user email
      if (_currentUserEmail == null) {
        await _loadCurrentUserEmail();
      }

      // Check if message is for current chat
      bool isForCurrentChat = false;

      if (_currentChatId != null && chatId == _currentChatId) {
        isForCurrentChat = true;
      } else if (_currentChatEmail != null &&
          (senderEmail == _currentChatEmail ||
              receiverEmail == _currentChatEmail)) {
        isForCurrentChat = true;
        // Update current chat ID if we got it
        if (chatId != null) {
          _currentChatId = chatId;
        }
      }

      if (isForCurrentChat) {
        // Optimistically append to current thread
        final now = DateTime.now();
        _messages.add(
          ChatMessage(
            messageId: 'remote_${now.millisecondsSinceEpoch}',
            senderEmail: senderEmail ?? 'unknown',
            chatId: chatId ?? _currentChatId ?? '',
            content: content,
            isSent: true,
            createdAt: now,
            updatedAt: now,
            user: ChatUser(
              email: senderEmail ?? 'unknown',
              firstName: '',
              lastName: '',
              profilePic: null,
            ),
          ),
        );
      }

      // Update chat list immediately
      _optimisticallyUpdateChatList(
        senderEmail: senderEmail ?? '',
        receiverEmail: receiverEmail ?? '',
        content: content,
        chatId: chatId,
        createdAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      log('❌ Error handling new message: $e');
    }
  }

  // Optimistically move/insert and update the chat list item
  void _optimisticallyUpdateChatList({
    required String senderEmail,
    required String receiverEmail,
    required String content,
    String? chatId,
    required DateTime createdAt,
  }) {
    try {
      // Find existing item by chatId or by other party email
      int existingIndex = -1;
      if (chatId != null && chatId.isNotEmpty) {
        existingIndex = _chatItems.indexWhere((c) => c.chatId == chatId);
      }
      if (existingIndex == -1) {
        // Try to find by email match (either side)
        existingIndex = _chatItems.indexWhere(
          (c) => c.senderEmail == senderEmail || c.user.email == senderEmail,
        );
      }

      if (existingIndex >= 0) {
        final existing = _chatItems[existingIndex];
        final updated = ChatItem(
          chatId: chatId ?? existing.chatId,
          content: content,
          isSent: true,
          createdAt: createdAt,
          user: existing.user,
          senderEmail: existing.senderEmail,
        );
        _chatItems.removeAt(existingIndex);
        _chatItems.insert(0, updated);
      } else {
        // Insert minimal item at top if not present yet
        final otherEmail = (_currentUserEmail == senderEmail)
            ? receiverEmail
            : senderEmail;
        final newItem = ChatItem(
          chatId: chatId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          isSent: true,
          createdAt: createdAt,
          user: ChatUser(
            email: otherEmail,
            firstName: otherEmail,
            lastName: '',
            profilePic: null,
          ),
          senderEmail: otherEmail,
        );
        _chatItems.insert(0, newItem);
      }

      _chatsState = _chatItems.isEmpty ? ViewState.empty : ViewState.loaded;
    } catch (e) {
      log('⚠️ Optimistic update failed: $e');
    }
  }

  // Check if message is from current user
  bool isMessageFromCurrentUser(ChatMessage message) {
    return message.senderEmail == _currentUserEmail;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Leave current chat
  void leaveCurrentChat() {
    _currentChatEmail = null;
    _currentChatId = null;
    _messages.clear();
    _messagesState = ViewState.initial;
    notifyListeners();
    log('🚪 Left current chat');
  }

  // Get display error message
  String getDisplayErrorMessage() {
    if (_errorMessage == null) return '';

    if (_errorMessage!.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (_errorMessage!.toLowerCase().contains('token')) {
      return 'Session expired. Please login again.';
    }

    return _errorMessage!;
  }

  @override
  void dispose() {
    SocketService.instance.clearCallbacks();
    super.dispose();
  }
}
