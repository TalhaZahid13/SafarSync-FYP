import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_storage.dart';
import 'env_config.dart';
import 'google_auth_service.dart';
import 'local_database_service.dart';
import 'safe_parse.dart';

/// Single gateway between the app and the SafarSync cloud backend.
///
/// * Authentication — Supabase Auth (email/password, Google, Apple).
/// * Data — the `api` Supabase Edge Function, which exposes the same REST
///   endpoints (and JSON shapes) the previous REST server did, so every
///   screen keeps calling `ApiService.getRequest('/bookings/list')` etc.
/// * Files — Supabase Storage (`avatars` bucket).
///
/// Nothing here depends on a local server, LAN IP or developer machine.
class ApiService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// REST base URL — `https://<project>.supabase.co/functions/v1/api`.
  static String get baseUrl => EnvConfig.apiBaseUrl;

  static const Duration _kTimeout = Duration(seconds: 20);

  // ============ SESSION / HEADERS ============

  /// Current Supabase access token (refreshed first if it is about to expire).
  static Future<String?> getToken() async {
    var session = _sb.auth.currentSession;
    if (session == null) return null;
    if (session.isExpired ||
        (session.expiresAt != null &&
            DateTime.fromMillisecondsSinceEpoch(
              session.expiresAt! * 1000,
            ).isBefore(DateTime.now().add(const Duration(seconds: 30))))) {
      try {
        final res = await _sb.auth.refreshSession();
        session = res.session ?? _sb.auth.currentSession;
      } catch (e) {
        debugPrint('[ApiService] session refresh failed: $e');
      }
    }
    return session?.accessToken;
  }

  /// Kept for API compatibility — the session itself is persisted by
  /// supabase_flutter, so these are no-ops beyond clearing the legacy key.
  static Future<void> saveToken(String token) async {}
  static Future<void> removeToken() async => AuthStorage.clearToken();

  static Future<Map<String, String>> getHeaders({
    bool needsAuth = false,
  }) async {
    final token = needsAuth ? await getToken() : null;
    return {
      'Content-Type': 'application/json',
      'apikey': EnvConfig.supabasePublishableKey,
      'Authorization': 'Bearer ${token ?? EnvConfig.supabasePublishableKey}',
    };
  }

  // ============ AUTH ============

  static String _authErrorMessage(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login credentials')) {
        return 'Invalid email or password';
      }
      if (m.contains('email not confirmed')) {
        return 'Please confirm your email first — check your inbox for the verification link.';
      }
      if (m.contains('already registered') ||
          m.contains('already been registered')) {
        return 'This email is already in use';
      }
      if (m.contains('password should be') || m.contains('weak')) {
        return 'Password is too weak';
      }
      if (m.contains('invalid') && m.contains('email')) {
        return 'Invalid email address';
      }
      if (m.contains('rate limit') || e.statusCode == '429') {
        return 'Too many attempts. Please wait a few minutes and try again.';
      }
      if (m.contains('token has expired') || m.contains('otp')) {
        return 'The code is invalid or has expired. Request a new one.';
      }
      return e.message;
    }
    if (_isNetworkError(e)) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Error: $e';
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException ||
      e.toString().contains('SocketException') ||
      e.toString().contains('Failed host lookup') ||
      e.toString().contains('Connection refused') ||
      e.toString().contains('Network is unreachable');

  /// Sign up with email + password. Profile fields are stored as user
  /// metadata and copied into `public.users` by a database trigger.
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? bloodGroup,
  }) async {
    try {
      final res = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: EnvConfig.authRedirectUrl,
        data: {
          'full_name': fullName.trim(),
          'phone_number': phoneNumber.trim(),
          if (bloodGroup != null && bloodGroup.isNotEmpty)
            'blood_group': bloodGroup,
        },
      );

      // Supabase returns a user with no identities when the email already exists.
      if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
        return {'success': false, 'message': 'This email is already in use'};
      }

      final uid = res.user?.id;
      if (uid != null) {
        await LocalDatabaseService.upsertUserProfile(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          bloodGroup: bloodGroup,
        );
      }

      if (res.session == null) {
        // Email confirmation is enabled for the project.
        return {
          'success': true,
          'needsConfirmation': true,
          'message':
              'Account created! We sent a confirmation link to $email. '
              'Verify your email, then log in.',
        };
      }

      final sync = await syncSession(
        phoneNumber: phoneNumber,
        bloodGroup: bloodGroup,
      );
      if (sync['success'] != true) return sync;
      return {'success': true, 'message': 'User registered successfully'};
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) return {'success': false, 'message': 'Login failed'};

      final sync = await syncSession();
      if (sync['success'] != true) {
        await _sb.auth.signOut();
        return sync;
      }

      final existing = await LocalDatabaseService.getUserProfile(user.id);
      if (existing == null) {
        await LocalDatabaseService.upsertUserProfile(
          uid: user.id,
          email: user.email ?? email,
          fullName: displayName(user),
        );
      }
      return {'success': true, 'uid': user.id};
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
  }

  /// Registers the sign-in with the API (last login, provider, optional
  /// profile fields) and caches the integer user id the UI relies on.
  /// Records the sign-in and caches the integer SafarSync user id.
  static Future<Map<String, dynamic>> syncSession({
    String? phoneNumber,
    String? bloodGroup,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Not signed in'};
    final r = await postRequest('/auth/session', {
      'full_name': displayName(user),
      'profile_picture_url':
          user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (bloodGroup != null) 'blood_group': bloodGroup,
    });
    if (r['success'] == true && r['user'] is Map) {
      await _saveUserData(Map<String, dynamic>.from(r['user'] as Map));
      return {'success': true, 'user': r['user']};
    }
    return {
      'success': false,
      'message':
          r['message'] ??
          r['error'] ??
          'Could not reach SafarSync. Please try again.',
    };
  }

  static Future<void> logout() async {
    try {
      await _sb.auth.signOut();
    } catch (_) {}
    await GoogleAuthService.signOut();
    await removeToken();
    await AuthStorage.clearLastActiveAt();
    await _clearUserData();
    await _clearAdminData();
    await AuthStorage.clearAdminToken();
  }

  /// Sends a password-reset email. The email contains both a link (opens the
  /// app via deep link) and a 6-digit code usable with [resetPasswordWithCode].
  static Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: EnvConfig.authRedirectUrl,
      );
      return {
        'success': true,
        'message': 'Reset instructions sent if the email is registered',
      };
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
  }

  /// Completes a password reset with the 6-digit code from the email.
  static Future<Map<String, dynamic>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _sb.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      await _sb.auth.updateUser(UserAttributes(password: newPassword));
      await _sb.auth.signOut();
      return {
        'success': true,
        'message': 'Password updated. Please log in with your new password.',
      };
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
  }

  /// Sets a new password for the currently signed-in user (used after
  /// opening a password-recovery deep link).
  static Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      await _sb.auth.updateUser(UserAttributes(password: newPassword));
      return {'success': true, 'message': 'Password updated'};
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
  }

  // ============ ADMIN AUTH ============

  /// Admin panel login: Supabase email/password sign-in, then the API
  /// confirms the account holds an admin role.
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      return {'success': false, 'message': _authErrorMessage(e)};
    }
    final r = await getRequest('/admin/auth/me');
    if (r['success'] == true && r['admin'] is Map) {
      final admin = Map<String, dynamic>.from(r['admin'] as Map);
      await AuthStorage.writeAdminToken('supabase-session');
      await _saveAdminData(admin);
      await syncSession();
      return {'success': true, 'admin': admin};
    }
    await _sb.auth.signOut();
    return {
      'success': false,
      'message': r['message'] ?? 'This account does not have admin access.',
    };
  }

  static Future<Map<String, dynamic>> adminForgotPassword(String email) =>
      sendPasswordReset(email);

  static Future<Map<String, dynamic>> adminResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      resetPasswordWithCode(email: email, code: otp, newPassword: newPassword);

  static Future<void> adminLogout() async {
    await AuthStorage.clearAdminToken();
    await _clearAdminData();
    await logout();
  }

  static Future<String?> getAdminToken() => AuthStorage.readAdminToken();

  static Future<Map<String, String>> getAdminHeaders() =>
      getHeaders(needsAuth: true);

  static Future<void> _saveAdminData(Map<String, dynamic> adminData) async {
    final prefs = await SharedPreferences.getInstance();
    final id = asInt(adminData['admin_id']);
    if (id != null) await prefs.setInt('admin_id', id);
    if (adminData['email'] != null) {
      await prefs.setString('admin_email', '${adminData['email']}');
    }
    if (adminData['full_name'] != null) {
      await prefs.setString('admin_full_name', '${adminData['full_name']}');
    }
    if (adminData['role'] != null) {
      await prefs.setString('admin_role', '${adminData['role']}');
    }
  }

  static Future<void> _clearAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      'admin_id',
      'admin_email',
      'admin_full_name',
      'admin_role',
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      'is_admin',
      'user_id',
      'user_email',
      'user_full_name',
      'firebase_uid',
      'auth_provider',
      'user_role',
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', userData['is_admin'] == true);
    final id = asInt(userData['user_id']);
    if (id != null) await prefs.setInt('user_id', id);
    if (userData['email'] != null) {
      await prefs.setString('user_email', '${userData['email']}');
    }
    if (userData['full_name'] != null) {
      await prefs.setString('user_full_name', '${userData['full_name']}');
    }
    if (userData['firebase_uid'] != null) {
      await prefs.setString('firebase_uid', '${userData['firebase_uid']}');
    }
    if (userData['auth_provider'] != null) {
      await prefs.setString('auth_provider', '${userData['auth_provider']}');
    }
    if (userData['role'] != null) {
      await prefs.setString('user_role', '${userData['role']}');
    }
  }

  // ============ CURRENT USER ============

  /// Display name of a Supabase user (signup metadata, OAuth profile or email).
  static String? displayName(User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    final name = (meta['full_name'] ?? meta['name'])?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email?.split('@').first;
  }

  static String? photoUrl(User? user) {
    final meta = user?.userMetadata ?? const {};
    return (meta['avatar_url'] ?? meta['picture'])?.toString();
  }

  /// Supabase Auth user id (uuid).
  static String? get userId => _sb.auth.currentUser?.id;

  static User? get currentAuthUser => _sb.auth.currentUser;

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No authenticated user'};
      }
      final profile = await LocalDatabaseService.getUserProfile(user.id);
      return {
        'success': true,
        'user': {
          'uid': user.id,
          'email': user.email,
          'name': profile?['full_name'] ?? displayName(user),
          'phoneNumber': profile?['phone_number'],
          'bloodGroup': profile?['blood_group'],
          'city': profile?['city'],
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<String> getAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_provider') ?? 'EMAIL';
  }

  static Future<bool> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_admin') == true) return true;
    final adminToken = await AuthStorage.readAdminToken();
    return adminToken != null && adminToken.isNotEmpty;
  }

  static Future<String?> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_role');
  }

  static Future<String> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_full_name') ??
        prefs.getString('user_full_name') ??
        'Admin';
  }

  /// Integer SafarSync user id (public.users.user_id).
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt('user_id');
    if (cached != null || _sb.auth.currentUser == null) return cached;
    final sync = await syncSession();
    return sync['success'] == true ? prefs.getInt('user_id') : null;
  }

  /// True when there is no usable Supabase session.
  static Future<bool> isJwtExpired() async {
    final session = _sb.auth.currentSession;
    return session == null || session.isExpired;
  }

  /// Called on app start: refresh an expired session and make sure the
  /// integer user id is cached.
  static Future<void> refreshSessionIfNeeded() async {
    if (_sb.auth.currentSession == null) return;
    try {
      if (await isJwtExpired()) await _sb.auth.refreshSession();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('user_id') == null) await syncSession();
    } catch (e) {
      debugPrint('[ApiService] refreshSessionIfNeeded: $e');
    }
  }

  // ============ DESTINATIONS ============

  static List<dynamic> _normalizeDestinations(List<dynamic> raw) =>
      raw.map((d) {
        final m = Map<String, dynamic>.from(d as Map);
        final resolved = asInt(m['destination_id'] ?? m['id']);
        m['destination_id'] = resolved;
        m['id'] = resolved;
        return m;
      }).toList();

  /// Destinations from Supabase; falls back to the bundled offline catalogue
  /// only when the network is unavailable.
  static Future<Map<String, dynamic>> getDestinations({
    int page = 1,
    int limit = 50,
    String? category,
  }) async {
    final qs =
        'page=$page&limit=$limit'
        '${category != null ? '&category=${Uri.encodeQueryComponent(category)}' : ''}';
    final r = await getRequest('/destinations?$qs', auth: false);
    if (r['destinations'] is List) {
      return {
        'success': true,
        'destinations': _normalizeDestinations(r['destinations'] as List),
      };
    }
    try {
      await LocalDatabaseService.ensureInitialized();
      final local = await LocalDatabaseService.getDestinations(
        page: page,
        limit: limit,
        category: category,
      );
      return {
        'success': true,
        'offline': true,
        'destinations': _normalizeDestinations(local),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> searchDestinations(String query) async {
    final r = await getRequest(
      '/destinations/search?query=${Uri.encodeQueryComponent(query)}',
      auth: false,
    );
    if (r['results'] is List) {
      return {
        'success': true,
        'results': _normalizeDestinations(r['results'] as List),
      };
    }
    try {
      await LocalDatabaseService.ensureInitialized();
      final results = await LocalDatabaseService.searchDestinations(query);
      return {'success': true, 'offline': true, 'results': results};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDestinationById(int id) async {
    final r = await getRequest('/destinations/$id', auth: false);
    if (r['destination'] != null) {
      return {'success': true, 'destination': r['destination']};
    }
    return {
      'success': false,
      'message': r['message'] ?? 'Destination not found',
    };
  }

  // ============ ROUTES ============

  static Future<Map<String, dynamic>> createRoute({
    required String routeName,
    String? description,
    String? startLocation,
    String? endLocation,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String difficultyLevel = 'Easy',
    bool isPublic = false,
  }) async {
    final r = await postRequest('/routes', {
      'route_name': routeName,
      'description': description,
      'start_location': startLocation,
      'end_location': endLocation,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'difficulty_level': difficultyLevel,
      'is_public': isPublic,
    });
    if (r['route_id'] != null) {
      return {'success': true, 'route_id': r['route_id']};
    }
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to create route',
    };
  }

  static Future<Map<String, dynamic>> getUserRoutes({
    int page = 1,
    int limit = 10,
  }) async {
    final r = await getRequest('/routes?page=$page&limit=$limit');
    if (r['routes'] is List) return {'success': true, 'routes': r['routes']};
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to fetch routes',
    };
  }

  // ============ WISHLIST ============

  static Future<Map<String, dynamic>> getWishlist({
    int page = 1,
    int limit = 10,
  }) async {
    final r = await getRequest('/wishlist?page=$page&limit=$limit');
    if (r['wishlist'] is List) {
      return {'success': true, 'wishlist': r['wishlist']};
    }
    return {
      'success': false,
      'wishlist': [],
      'message': r['message'] ?? 'Failed to fetch wishlist',
    };
  }

  static Future<Map<String, dynamic>> addToWishlist({
    required int destinationId,
    String? notes,
    String? priority,
    String? plannedVisitDate,
  }) async {
    final r = await postRequest('/wishlist', {
      'destination_id': destinationId,
      'notes': notes,
      'priority': priority,
      'planned_visit_date': plannedVisitDate,
    });
    if (r['wishlist_id'] != null) {
      return {'success': true, 'message': 'Added to wishlist'};
    }
    if (r['status'] == 409) {
      return {'success': false, 'message': 'Already in wishlist'};
    }
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to add to wishlist',
    };
  }

  static Future<Map<String, dynamic>> checkInWishlist(int destinationId) async {
    final r = await getRequest('/wishlist/check/$destinationId');
    return {
      'success': r.containsKey('inWishlist'),
      'inWishlist': r['inWishlist'] == true,
    };
  }

  static Future<Map<String, dynamic>> removeFromWishlist(
    int destinationId,
  ) async {
    final r = await deleteRequest('/wishlist/$destinationId');
    if (r['success'] == false) {
      return {'success': false, 'message': r['message'] ?? 'Failed to remove'};
    }
    return {'success': true, 'message': 'Removed from wishlist'};
  }

  // ============ LOCATION / WEATHER ============

  /// Latest stored location of the signed-in user.
  static Future<Map<String, dynamic>> getLatestLocation({
    String? userIdentifier,
  }) async {
    final r = await getRequest('/location/latest');
    if (r['location'] != null) {
      return {'success': true, 'location': r['location']};
    }
    return {'success': false, 'message': r['message'] ?? 'No location found'};
  }

  static Future<Map<String, dynamic>> getWeather(double lat, double lng) async {
    final r = await getRequest('/weather/$lat/$lng', auth: false);
    if (r['weather'] != null) return {'success': true, 'weather': r['weather']};
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to fetch weather',
    };
  }

  static Future<Map<String, dynamic>> getWeatherForecast(
    double lat,
    double lng, {
    int days = 4,
  }) async {
    final r = await getRequest(
      '/weather/$lat/$lng/forecast?days=$days',
      auth: false,
    );
    if (r['forecast'] is List) {
      return {'success': true, 'forecast': r['forecast'], 'city': r['city']};
    }
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to fetch forecast',
    };
  }

  /// Push a GPS position (fire-and-forget).
  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? city,
    String? country,
    int? groupBookingId,
  }) async {
    if (_sb.auth.currentSession == null) return;
    await postRequest('/location/update', {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (groupBookingId != null) 'group_booking_id': groupBookingId,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ============ AI / EMERGENCY / NOTIFICATIONS ============

  static Future<Map<String, dynamic>> sendAiMessage(String message) async {
    final r = await postRequest('/ai/chat', {
      'message': message,
    }, timeout: const Duration(seconds: 40));
    if (r['ai_response'] != null) {
      return {'success': true, 'response': r['ai_response']};
    }
    return {'success': false, 'message': r['message'] ?? 'AI request failed'};
  }

  static Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
    String? locationDescription,
    String severity = 'High',
  }) async {
    final r = await postRequest('/emergency/trigger', {
      'latitude': latitude,
      'longitude': longitude,
      'message': locationDescription,
      'severity': severity,
    });
    if (r['success'] == true) {
      return {
        'success': true,
        'message': 'SOS activated',
        'alert_id': r['alert_id'],
      };
    }
    return {
      'success': false,
      'message': r['message'] ?? 'Failed to activate SOS',
    };
  }

  static Future<Map<String, dynamic>> getNotifications({int limit = 20}) async {
    final r = await getRequest('/notifications?limit=$limit');
    if (r['notifications'] is List) {
      return {'success': true, 'notifications': r['notifications']};
    }
    return {
      'success': false,
      'notifications': [],
      'message': r['message'] ?? 'Failed to fetch notifications',
    };
  }

  // ============ STORAGE ============

  /// Upload a profile photo to Supabase Storage (`avatars/<auth uid>/...`)
  /// and save its public URL on the profile. Returns `{success, url}`.
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    List<int> bytes,
    String filename,
  ) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Please sign in again'};
    }
    if (bytes.length > 5 * 1024 * 1024) {
      return {'success': false, 'message': 'Image is too large (max 5 MB)'};
    }
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : 'jpg';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.${ext == 'jpeg' ? 'jpg' : ext}';
    try {
      await _sb.storage
          .from('avatars')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final url = _sb.storage.from('avatars').getPublicUrl(path);
      final r = await putRequest('/users/profile', {
        'profile_picture_url': url,
      });
      if (r['success'] != true) {
        return {
          'success': false,
          'message': r['message'] ?? 'Could not save photo',
        };
      }
      try {
        await _sb.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
      } catch (_) {}
      return {'success': true, 'url': url};
    } on StorageException catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.message}'};
    } catch (e) {
      return {
        'success': false,
        'message': _isNetworkError(e)
            ? 'No internet connection'
            : 'Upload error: $e',
      };
    }
  }

  // ============ GENERIC HTTP (Edge Function) ============

  static const _offlineMessage =
      'No internet connection. Please check your network and try again.';

  static Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body = {};
    if (res.body.isNotEmpty) {
      try {
        final d = jsonDecode(res.body);
        body = d is Map<String, dynamic> ? d : {'data': d};
      } catch (_) {}
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body.isEmpty ? {'success': true} : body;
    }
    if (res.statusCode == 401) {
      return {
        'success': false,
        'status': 401,
        'message': 'Your session has expired. Please log in again.',
        ...body,
      };
    }
    final msg =
        body['error'] ?? body['message'] ?? 'Request failed: ${res.statusCode}';
    return {
      ...body,
      'success': false,
      'status': res.statusCode,
      'message': '$msg',
      'error': '$msg',
    };
  }

  /// Executes a request with one automatic retry on transient network errors.
  static Future<Map<String, dynamic>> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final headers = await getHeaders(needsAuth: auth);
        final encoded = body == null ? null : jsonEncode(body);
        final Future<http.Response> fut = switch (method) {
          'GET' => http.get(uri, headers: headers),
          'POST' => http.post(uri, headers: headers, body: encoded),
          'PUT' => http.put(uri, headers: headers, body: encoded),
          'DELETE' => http.delete(uri, headers: headers, body: encoded),
          _ => throw ArgumentError('Unsupported method $method'),
        };
        final res = await fut.timeout(timeout ?? _kTimeout);
        return _decode(res);
      } on TimeoutException {
        if (attempt == 1 || method != 'GET') {
          return {
            'success': false,
            'message': 'The request timed out. Please try again.',
          };
        }
      } catch (e) {
        if (!_isNetworkError(e)) {
          return {'success': false, 'message': 'Error: $e'};
        }
        if (attempt == 1) {
          return {
            'success': false,
            'offline': true,
            'message': _offlineMessage,
          };
        }
      }
      await Future.delayed(const Duration(milliseconds: 700));
    }
    return {'success': false, 'message': _offlineMessage};
  }

  static Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    bool auth = true,
  }) => _send('GET', endpoint, auth: auth);

  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) => _send('POST', endpoint, body: body, timeout: timeout);

  static Future<Map<String, dynamic>> putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) => _send('PUT', endpoint, body: body);

  static Future<Map<String, dynamic>> deleteRequest(String endpoint) =>
      _send('DELETE', endpoint);

  // Admin routes use the same Supabase session; admin rights are checked
  // server-side on every /admin/* call.
  static Future<Map<String, dynamic>> adminGetRequest(String endpoint) =>
      getRequest(endpoint);
  static Future<Map<String, dynamic>> adminPostRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) => postRequest(endpoint, body);
  static Future<Map<String, dynamic>> adminPutRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) => putRequest(endpoint, body);
  static Future<Map<String, dynamic>> adminDeleteRequest(String endpoint) =>
      deleteRequest(endpoint);
}
