import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only view of the signed-in Supabase user with the property names the
/// screens already use (`uid`, `displayName`, `photoURL`, `email`).
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
}

class AppAuth {
  AppAuth._();

  static AppUser? get currentUser {
    final User? u = Supabase.instance.client.auth.currentUser;
    if (u == null) return null;
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final name = (meta['full_name'] ?? meta['name'])?.toString().trim();
    return AppUser(
      uid: u.id,
      email: u.email,
      displayName: (name == null || name.isEmpty) ? null : name,
      photoURL: (meta['avatar_url'] ?? meta['picture'])?.toString(),
    );
  }

  /// Keeps the auth profile (used for the greeting/avatar) in sync with
  /// edits saved through the API.
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final data = <String, dynamic>{
      if (displayName != null) 'full_name': displayName,
      if (photoURL != null) 'avatar_url': photoURL,
    };
    if (data.isEmpty || Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: data),
      );
    } catch (_) {}
  }

  static Future<void> signOut() => Supabase.instance.client.auth.signOut();
}
