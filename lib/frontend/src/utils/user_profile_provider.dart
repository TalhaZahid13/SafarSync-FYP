import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/destination_theme.dart';
import 'api_service.dart';

/// Single source of truth for the signed-in user's profile (name, photo,
/// city, …) as stored in `public.users`, loaded through `GET /users/profile`
/// (the server resolves the user from the session JWT — the app never sends
/// a user id).
///
/// It follows Supabase auth events, so signing out clears it and signing in
/// as someone else loads that account's profile and theme — no data from the
/// previous account survives an account switch.
class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({required this.themes});

  final DestinationThemeProvider themes;

  StreamSubscription<AuthState>? _authSub;
  String? _uid;
  Map<String, dynamic>? _profile;
  bool _loading = false;
  int _generation = 0;

  // ── Read API ────────────────────────────────────────────────────────────────

  bool get isSignedIn => _uid != null;
  bool get isLoading => _loading;
  Map<String, dynamic>? get profile => _profile;

  String? get email =>
      _str(_profile?['email']) ??
      Supabase.instance.client.auth.currentUser?.email;
  String? get city => _str(_profile?['city']);
  String? get photoUrl =>
      _str(_profile?['profile_picture_url']) ?? _authMeta('avatar_url');

  /// Full name from the database, then the sign-in provider, then null.
  String? get fullName =>
      _str(_profile?['full_name']) ??
      _authMeta('full_name') ??
      _authMeta('name');

  /// What to greet the user with: first word of the real name. Falls back to
  /// a neutral "Traveler" rather than exposing the email address.
  String get firstName {
    final n = fullName;
    if (n == null) return 'Traveler';
    return n.split(RegExp(r'\s+')).first;
  }

  /// Up to two initials for the avatar placeholder.
  String get initials {
    final n = fullName ?? email ?? '';
    final parts = n
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  /// Starts following auth state. Call once after Supabase is initialised.
  void start() {
    try {
      final auth = Supabase.instance.client.auth;
      _authSub = auth.onAuthStateChange.listen((s) {
        _onAuth(s.session?.user.id, s.event);
      });
      _onAuth(auth.currentUser?.id, null);
    } catch (e) {
      debugPrint('[UserProfile] auth listener not started: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onAuth(String? uid, AuthChangeEvent? event) {
    if (event == AuthChangeEvent.signedOut) uid = null;
    if (uid == _uid) {
      if (event == AuthChangeEvent.userUpdated) refresh().ignore();
      return;
    }
    _generation++;
    _uid = uid;
    _profile = null; // never show the previous account's data
    notifyListeners();
    themes.attachUser(uid).ignore();
    if (uid != null) refresh().ignore();
  }

  // ── Updates ─────────────────────────────────────────────────────────────────

  /// Reloads the profile from the database.
  Future<void> refresh() async {
    if (_uid == null) return;
    final gen = _generation;
    _loading = true;
    notifyListeners();
    try {
      final r = await ApiService.getRequest('/users/profile');
      if (gen != _generation) return; // signed out / switched meanwhile
      if (r['success'] == true && r['user'] is Map) {
        _profile = Map<String, dynamic>.from(r['user'] as Map);
      }
    } catch (e) {
      debugPrint('[UserProfile] refresh failed: $e');
    } finally {
      if (gen == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Applies fields that were just saved, so the header/profile update
  /// immediately, then confirms against the server.
  void applySaved(Map<String, dynamic> fields) {
    if (_uid == null) return;
    _profile = {...?_profile, ...fields};
    notifyListeners();
    refresh().ignore();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String? _str(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static String? _authMeta(String key) {
    try {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      return _str(meta?[key]);
    } catch (_) {
      return null;
    }
  }
}
