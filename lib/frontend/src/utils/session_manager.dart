import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage.dart';

class SessionManager {
  static const Duration inactivityLimit = Duration(days: 7);

  static Future<void> recordActivity() async {
    await AuthStorage.setLastActiveAt(DateTime.now());
  }

  static Future<bool> isSessionExpired({
    Duration limit = inactivityLimit,
  }) async {
    final lastActiveAt = await AuthStorage.getLastActiveAt();
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt) >= limit;
  }

  static Future<void> setRememberMeEmail(String email, bool enabled) async {
    await AuthStorage.setRememberMe(enabled: enabled, email: email);
  }

  static Future<String?> getRememberedEmail() {
    return AuthStorage.getRememberedEmail();
  }

  static Future<void> clearAuthState({bool clearRememberMe = false}) async {
    await FirebaseAuth.instance.signOut();
    await AuthStorage.clearToken();
    await AuthStorage.clearAdminToken();
    await AuthStorage.clearLastActiveAt();

    // Clear all cached user/admin data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['is_admin', 'user_id', 'user_email', 'user_full_name',
                        'admin_id', 'admin_email', 'admin_full_name', 'admin_role',
                        'firebase_uid', 'auth_provider', 'user_role']) {
      await prefs.remove(key);
    }

    if (clearRememberMe) {
      await AuthStorage.clearRememberMe();
    }
  }

  static Future<bool> clearIfSessionExpired({
    bool clearRememberMe = false,
  }) async {
    final expired = await isSessionExpired();
    if (!expired) return false;

    await clearAuthState(clearRememberMe: clearRememberMe);
    return true;
  }
}
