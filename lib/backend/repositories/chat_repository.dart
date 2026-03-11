// repositories/chat_repository.dart (UPDATED FOR YOUR API)

import 'dart:developer';
import 'package:safarsync_mobileapp/backend/services/api_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';
import 'package:safarsync_mobileapp/backend/models/chat_models.dart';

class ChatRepository {
  // Get all chats
  static Future<Map<String, dynamic>> getAllChats() async {
    try {
      final token = await TokenManager.getToken();

      final response = await ApiService.get(endpoint: '/chat', token: token);

      log('📱 Get All Chats Response: ${response}');

      if (response['success'] == true) {
        final List<dynamic> chatsData = response['data']['data'] ?? [];
        final List<ChatItem> chats = chatsData
            .map((json) => ChatItem.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': 'Chats fetched successfully',
          'chats': chats,
        };
      } else {
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Failed to fetch chats',
        };
      }
    } catch (e) {
      log('❌ Get All Chats Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch chats: ${e.toString()}',
      };
    }
  }

  // Get specific chat messages
  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
  }) async {
    try {
      final token = await TokenManager.getToken();

      final response = await ApiService.get(
        endpoint: '/chat/$chatId',
        token: token,
      );

      log('📱 Get Chat Messages Response: ${response}');

      if (response['success'] == true) {
        final List<dynamic> messagesData = response['data']['data'] ?? [];
        final List<ChatMessage> messages = messagesData
            .map((json) => ChatMessage.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': 'Messages fetched successfully',
          'messages': messages,
        };
      } else {
        return {
          'success': false,
          'message': response['data']['message'] ?? 'Failed to fetch messages',
        };
      }
    } catch (e) {
      log('❌ Get Chat Messages Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch messages: ${e.toString()}',
      };
    }
  }

  // Send message via API (backup for socket)
}
