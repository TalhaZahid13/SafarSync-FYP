import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String jwtTokenKey = 'jwt_token';
  static const String adminJwtTokenKey = 'admin_jwt_token';
  static const String rememberMeEmailKey = 'remember_me_email';
  static const String rememberMeEnabledKey = 'remember_me_enabled';
  static const String lastActiveAtKey = 'last_active_at';

  static Future<String?> readToken() {
    return _secureStorage.read(key: jwtTokenKey);
  }

  static Future<void> writeToken(String token) {
    return _secureStorage.write(key: jwtTokenKey, value: token);
  }

  static Future<void> clearToken() {
    return _secureStorage.delete(key: jwtTokenKey);
  }

  // ── Admin token (separate from user token) ────────────────────────────────
  static Future<String?> readAdminToken() {
    return _secureStorage.read(key: adminJwtTokenKey);
  }

  static Future<void> writeAdminToken(String token) {
    return _secureStorage.write(key: adminJwtTokenKey, value: token);
  }

  static Future<void> clearAdminToken() {
    return _secureStorage.delete(key: adminJwtTokenKey);
  }

  static Future<void> setRememberMe({
    required bool enabled,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rememberMeEnabledKey, enabled);

    if (enabled && email != null && email.trim().isNotEmpty) {
      await prefs.setString(rememberMeEmailKey, email.trim());
    } else {
      await prefs.remove(rememberMeEmailKey);
    }
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(rememberMeEnabledKey) ?? false;
  }

  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(rememberMeEnabledKey) ?? false;
    if (!enabled) return null;
    return prefs.getString(rememberMeEmailKey);
  }

  static Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(rememberMeEnabledKey);
    await prefs.remove(rememberMeEmailKey);
  }

  static Future<void> setLastActiveAt(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastActiveAtKey, timestamp.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastActiveAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(lastActiveAtKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> clearLastActiveAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastActiveAtKey);
  }
}
