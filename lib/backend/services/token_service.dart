// services/token_manager.dart
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safarsync_mobileapp/backend/models/user_model.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  static String? _currentToken;
  static User? _currentUser;

  // Get current token (cached or from storage)
  static Future<String?> getToken() async {
    if (_currentToken != null) return _currentToken;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString(_tokenKey);
      return _currentToken;
    } catch (e) {
      log('❌ Failed to get token: $e');
      return null;
    }
  }

  // Save token globally
  static Future<void> saveToken(String token) async {
    try {
      _currentToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);
      log('✅ Token saved globally: ${token.substring(0, 20)}...');
    } catch (e) {
      log('❌ Failed to save token: $e');
    }
  }

  // Get current user (cached or from storage)
  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        return _currentUser;
      }
      return null;
    } catch (e) {
      log('❌ Failed to get user data: $e');
      return null;
    }
  }

  // Save user data globally
  static Future<void> saveUserData(User user) async {
    try {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userDataKey, userJson);
      log('✅ User data saved globally: ${user.fullName}');
    } catch (e) {
      log('❌ Failed to save user data: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final token = await getToken();

      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      log('❌ Failed to check login status: $e');
      return false;
    }
  }

  // Clear all auth data (logout)
  static Future<void> clearAll() async {
    try {
      _currentToken = null;
      _currentUser = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);

      log('✅ All auth data cleared');
    } catch (e) {
      log('❌ Failed to clear auth data: $e');
    }
  }

  // Update user data
  static Future<void> updateUserData(User updatedUser) async {
    try {
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(updatedUser.toJson());
      await prefs.setString(_userDataKey, userJson);
      log(
        '✅ User data updated: ${updatedUser.fullName}, ${updatedUser.lastName}',
      );
    } catch (e) {
      log('❌ Failed to update user data: $e');
    }
  }

  // Get token for API calls (with Bearer prefix)
  static Future<String?> getAuthHeader() async {
    final token = await getToken();
    return token != null ? 'Bearer $token' : null;
  }

  // Debug: Print current auth state
  static Future<void> printAuthState() async {
    final token = await getToken();
    final user = await getCurrentUser();
    final isLoggedIn = await TokenManager.isLoggedIn();

    log('🔍 Auth State Debug:');
    log('   Token: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
    log('   User: ${user?.fullName ?? "null"}');
    log('   Is Logged In: $isLoggedIn');
  }
}
