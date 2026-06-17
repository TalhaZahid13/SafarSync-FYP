import 'package:firebase_auth/firebase_auth.dart';

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
    await AuthStorage.clearLastActiveAt();

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
