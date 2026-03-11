import 'package:safarsync_mobileapp/backend/models/user_model.dart';

class AuthResponse {
  final int status;
  final String message;
  final User user;
  final String token;

  AuthResponse({
    required this.status,
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      user: User.fromJson(json['data']['user'] as Map<String, dynamic>),
      token: json['data']['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': {'user': user.toJson(), 'token': token},
    };
  }
}
