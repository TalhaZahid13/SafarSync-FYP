// models/chat_models.dart (UPDATED FOR YOUR API)

class ChatItem {
  final String chatId;
  final String content;
  final bool isSent;
  final DateTime createdAt;
  final ChatUser user;
  final String senderEmail;

  ChatItem({
    required this.chatId,
    required this.content,
    required this.isSent,
    required this.createdAt,
    required this.user,
    required this.senderEmail,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      isSent: json['isSent'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: ChatUser.fromJson(json['user'] as Map<String, dynamic>),
      senderEmail: json['senderEmail'] as String,
    );
  }
}

class ChatMessage {
  final String messageId;
  final String senderEmail;
  final String chatId;
  final String content;
  final bool isSent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatUser user;

  ChatMessage({
    required this.messageId,
    required this.senderEmail,
    required this.chatId,
    required this.content,
    required this.isSent,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      senderEmail: json['senderEmail'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      isSent: json['isSent'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: ChatUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ChatUser {
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePic;

  ChatUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePic,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profilePic: json['profilePic'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}

// Keep existing ChatConversation for compatibility
class ChatConversation {
  final int id;
  final String userName;
  final String userImageUrl;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
  });
}
