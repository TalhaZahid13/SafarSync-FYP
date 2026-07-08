import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';
import 'auth_storage.dart';
import 'safe_parse.dart';

class ApiService {
  // Optional override: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Optional Android host override: flutter run --dart-define=ANDROID_API_HOST=10.0.2.2
  static const String _androidHostOverride = String.fromEnvironment(
    'ANDROID_API_HOST',
    defaultValue: '',
  );

  static const String _kServerUrlPrefKey = 'server_base_url';

  // Mutable so it can be updated at runtime via setServerUrl()
  static String baseUrl = _resolveBaseUrlSync();

  /// True only when the user has explicitly saved a server URL.
  /// False on first launch → login page uses this to auto-open the config dialog.
  static bool _hasCustomUrl = false;
  static bool get isServerConfigured => _hasCustomUrl;

  /// Socket.io server URL (same host, no /api path)
  static String get socketUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Called once in main() — loads user-saved URL from SharedPreferences,
  /// validates it's actually reachable, and otherwise auto-discovers the
  /// backend on the local network. Never requires manual configuration for
  /// the common cases (emulator, real device on the same WiFi).
  static Future<void> initBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kServerUrlPrefKey);

      if (saved != null && saved.isNotEmpty) {
        final candidate = _normalizeBaseUrl(saved);
        if (await _probeHealth(_extractHost(candidate), timeout: const Duration(seconds: 3))) {
          baseUrl = candidate;
          _hasCustomUrl = true;
          return;
        }
        debugPrint('[ApiService] Saved server URL unreachable ($candidate) — re-discovering');
      }

      if (kIsWeb) {
        _hasCustomUrl = false;
        return;
      }

      // Android emulator special-case: 10.0.2.2 only resolves inside the
      // emulator's virtual NAT, so probe it before assuming it's wrong.
      if (defaultTargetPlatform == TargetPlatform.android && _androidHostOverride.isEmpty) {
        if (await _probeHealth('10.0.2.2', timeout: const Duration(milliseconds: 800))) {
          baseUrl = 'http://10.0.2.2:5000/api';
          _hasCustomUrl = false;
          return;
        }
      } else if (defaultTargetPlatform != TargetPlatform.android) {
        if (await _probeHealth('localhost', timeout: const Duration(milliseconds: 800))) {
          baseUrl = 'http://localhost:5000/api';
          _hasCustomUrl = false;
          return;
        }
      }

      // Not an emulator (or backend not on the host loopback) — scan the
      // device's own WiFi subnet for a machine answering on :5000/health.
      final lanHost = await _discoverLanHost();
      if (lanHost != null) {
        baseUrl = 'http://$lanHost:5000/api';
        _hasCustomUrl = true;
        await prefs.setString(_kServerUrlPrefKey, baseUrl);
        debugPrint('[ApiService] Auto-discovered backend at $lanHost');
        return;
      }

      debugPrint('[ApiService] No backend found automatically; keeping default $baseUrl');
    } catch (e) {
      debugPrint('[ApiService] initBaseUrl error (non-fatal): $e');
    }
    _hasCustomUrl = false;
  }

  /// Quick reachability check against a host's /health endpoint. Validates
  /// the actual JSON body (matches app.js's `{status:'OK'}` handler), not
  /// just a 200 status — a bare status check can be fooled by an unrelated
  /// server, a mobile-carrier captive portal, or a zero-balance SIM landing
  /// page that also happens to answer with HTTP 200 on port 5000.
  static Future<bool> _probeHealth(String host, {Duration timeout = const Duration(milliseconds: 600)}) async {
    try {
      final response = await http.get(Uri.parse('http://$host:5000/health')).timeout(timeout);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      return data is Map && data['status'] == 'OK';
    } catch (_) {
      return false;
    }
  }

  static String _extractHost(String url) => Uri.tryParse(url)?.host ?? url;

  /// Probes every host on the device's local WiFi /24 subnet(s) for a
  /// running SafarSync backend, returning the first IP that answers.
  static Future<String?> _discoverLanHost() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );

      final subnets = <String>{};
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
      if (subnets.isEmpty) return null;

      final completer = Completer<String?>();
      var pending = 0;
      for (final subnet in subnets) {
        for (var i = 1; i < 255; i++) {
          final host = '$subnet.$i';
          pending++;
          _probeHealth(host, timeout: const Duration(milliseconds: 900)).then((ok) {
            pending--;
            if (ok) {
              if (!completer.isCompleted) completer.complete(host);
            } else if (pending == 0 && !completer.isCompleted) {
              completer.complete(null);
            }
          });
        }
      }

      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Persist a new server base URL and update the runtime value immediately.
  static Future<void> setServerUrl(String url) async {
    final trimmed = url.trim();
    // Accept either base (http://host:port) or full (http://host:port/api)
    final normalized = trimmed.endsWith('/api')
        ? _normalizeBaseUrl(trimmed)
        : _normalizeBaseUrl('$trimmed/api');
    baseUrl = normalized;
    _hasCustomUrl = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kServerUrlPrefKey, normalized);
  }

  /// Returns the currently configured server base URL (without /api suffix).
  static String get serverHost => socketUrl;

  static String _resolveBaseUrlSync() {
    if (_baseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlOverride);
    }
    final host = _defaultHostForPlatform();
    return 'http://$host:5000/api';
  }

  static String _defaultHostForPlatform() {
    if (kIsWeb) return 'localhost';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulator: 10.0.2.2 reaches host machine.
        // Physical device: set server URL in app Settings → Server Config.
        if (_androidHostOverride.isNotEmpty) return _androidHostOverride;
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    return AuthStorage.readToken();
  }

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    await AuthStorage.writeToken(token);
  }

  /// Remove JWT token (logout)
  static Future<void> removeToken() async {
    await AuthStorage.clearToken();
  }

  /// Get headers with token
  static Future<Map<String, String>> getHeaders({
    bool needsAuth = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (needsAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ============ AUTH ENDPOINTS ============

  /// Sign up new user
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? bloodGroup,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(fullName);

      final uid = credential.user?.uid;
      if (uid != null) {
        await LocalDatabaseService.upsertUserProfile(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          bloodGroup: bloodGroup,
        );
      }

      // Reload so displayName is visible in providerData
      await credential.user?.reload();
      final freshUser = _auth.currentUser;

      // Exchange Firebase token — pass phone/blood so MySQL record is complete on first insert
      if (freshUser != null) {
        final exchangeResult = await exchangeFirebaseToken(
          freshUser,
          phoneNumber: phoneNumber,
          bloodGroup:  bloodGroup,
        );
        if (exchangeResult['success'] != true) {
          return {'success': false, 'message': exchangeResult['message'] as String? ?? 'Could not connect to server. Please check your connection and try again.'};
        }
      }

      return {'success': true, 'message': 'User registered successfully'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Signup failed: ${e.code}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return {'success': false, 'message': 'Login failed'};
      }

      // Exchange Firebase token for real MySQL-backed JWT
      final exchangeResult = await exchangeFirebaseToken(user);
      if (exchangeResult['success'] != true) {
        await _auth.signOut();
        return {'success': false, 'message': exchangeResult['message'] as String? ?? 'Could not connect to server. Please check your connection and try again.'};
      }

      final existingProfile = await LocalDatabaseService.getUserProfile(user.uid);
      if (existingProfile == null) {
        await LocalDatabaseService.upsertUserProfile(
          uid: user.uid,
          email: user.email ?? email,
          fullName: user.displayName,
        );
      }

      return {'success': true, 'uid': user.uid};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid email or password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.code}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    await _auth.signOut();
    await removeToken();
    await AuthStorage.clearLastActiveAt();
    await _clearUserData();
  }

  // ============ ADMIN AUTH ENDPOINTS ============

  /// Login as admin (direct email/password — no Firebase).
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await AuthStorage.writeAdminToken(token);
          final adminData = data['admin'] as Map<String, dynamic>?;
          if (adminData != null) await _saveAdminData(adminData);
        }
        return {'success': true, ...data};
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': false, 'message': body['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Request admin password reset OTP.
  static Future<Map<String, dynamic>> adminForgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Reset code sent if email is registered'};
      }
      return {'success': false, 'message': 'Request failed'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Verify OTP and set new admin password.
  static Future<Map<String, dynamic>> adminResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'new_password': newPassword}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Logout admin — clears admin token and SharedPreferences admin data.
  static Future<void> adminLogout() async {
    await AuthStorage.clearAdminToken();
    await _clearAdminData();
  }

  /// Returns stored admin token.
  static Future<String?> getAdminToken() => AuthStorage.readAdminToken();

  /// Headers with admin JWT for protected admin API calls.
  static Future<Map<String, String>> getAdminHeaders() async {
    final token = await getAdminToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<void> _saveAdminData(Map<String, dynamic> adminData) async {
    final prefs = await SharedPreferences.getInstance();
    if (adminData['admin_id'] != null) {
      await prefs.setInt('admin_id', (adminData['admin_id'] as num).toInt());
    }
    if (adminData['email'] != null) {
      await prefs.setString('admin_email', adminData['email'] as String);
    }
    if (adminData['full_name'] != null) {
      await prefs.setString('admin_full_name', adminData['full_name'] as String);
    }
    if (adminData['role'] != null) {
      await prefs.setString('admin_role', adminData['role'] as String);
    }
  }

  static Future<void> _clearAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_id');
    await prefs.remove('admin_email');
    await prefs.remove('admin_full_name');
    await prefs.remove('admin_role');
  }

  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_admin');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_full_name');
  }

  // ============ USER ENDPOINTS ============

  /// Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No authenticated user'};
      }

      final profile = await LocalDatabaseService.getUserProfile(user.uid);
      final localUser = {
        'uid': user.uid,
        'email': user.email,
        'name': profile?['full_name'] ?? user.displayName,
        'phoneNumber': profile?['phone_number'],
        'bloodGroup': profile?['blood_group'],
        'city': profile?['city'],
      };

      return {'success': true, 'user': localUser};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ DESTINATION ENDPOINTS ============

  /// Get all destinations — tries backend first, falls back to local SQLite.
  /// Always normalises the result so both `id` and `destination_id` are present.
  static Future<Map<String, dynamic>> getDestinations({
    int page = 1,
    int limit = 50,
    String? category,
  }) async {
    List<dynamic> normalize(List<dynamic> raw) => raw.map((d) {
      final m = Map<String, dynamic>.from(d as Map);
      // destination_id/id can arrive as a String (legacy `destination` table
      // uses a char(36) id column) or a num (modern `destinations` table) —
      // never cast blindly, that throws on the String case.
      final resolved = asInt(m['destination_id'] ?? m['id']);
      m['destination_id'] = resolved;
      m['id'] = resolved;
      return m;
    }).toList();

    // 1. Try backend endpoint
    try {
      final queryParams = 'page=$page&limit=$limit${category != null ? '&category=$category' : ''}';
      final response = await http.get(
        Uri.parse('$baseUrl/destinations?$queryParams'),
        headers: await getHeaders(),
      ).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['destinations'] as List?) ?? [];
        return {'success': true, 'destinations': normalize(list)};
      }
    } catch (_) {}

    // 2. Fall back to local SQLite seed data
    try {
      await LocalDatabaseService.ensureInitialized();
      final destinations = await LocalDatabaseService.getDestinations(
        page: page,
        limit: limit,
        category: category,
      );
      return {'success': true, 'destinations': normalize(destinations)};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Search destinations from local SQLite
  static Future<Map<String, dynamic>> searchDestinations(String query) async {
    try {
      await LocalDatabaseService.ensureInitialized();
      final results = await LocalDatabaseService.searchDestinations(query);

      return {'success': true, 'results': results};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get destination by ID
  static Future<Map<String, dynamic>> getDestinationById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/destinations/$id'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'destination': data['destination']};
      } else {
        return {'success': false, 'message': 'Destination not found'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ ROUTE ENDPOINTS ============

  /// Create route
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routes'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
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
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'route_id': data['route_id']};
      } else {
        return {'success': false, 'message': 'Failed to create route'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get user's routes
  ///
  static Future<Map<String, dynamic>> getUserRoutes({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes?page=$page&limit=$limit'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'routes': data['routes']};
      } else {
        return {'success': false, 'message': 'Failed to fetch routes'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ WISHLIST ENDPOINTS ============

  /// Get user's wishlist
  static Future<Map<String, dynamic>> getWishlist({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist?page=$page&limit=$limit'),
        headers: await getHeaders(needsAuth: true),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'wishlist': data['wishlist']};
      } else {
        return {'success': false, 'message': 'Failed to fetch wishlist'};
      }
    } on TimeoutException {
      return {'success': false, 'wishlist': [], 'message': 'Request timed out'};
    } catch (e) {
      return {'success': false, 'wishlist': [], 'message': 'Error: $e'};
    }
  }

  /// Add to wishlist
  static Future<Map<String, dynamic>> addToWishlist({
    required int destinationId,
    String? notes,
    String? priority,
    String? plannedVisitDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'destination_id': destinationId,
          'notes': notes,
          'priority': priority,
          'planned_visit_date': plannedVisitDate,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Added to wishlist'};
      } else if (response.statusCode == 409) {
        return {'success': false, 'message': 'Already in wishlist'};
      } else {
        return {'success': false, 'message': 'Failed to add to wishlist'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Check if destination in wishlist
  static Future<Map<String, dynamic>> checkInWishlist(int destinationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/check/$destinationId'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'inWishlist': data['inWishlist']};
      } else {
        return {'success': false, 'inWishlist': false};
      }
    } catch (e) {
      return {'success': false, 'inWishlist': false};
    }
  }

  /// Remove from wishlist
  static Future<Map<String, dynamic>> removeFromWishlist(
    int destinationId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/$destinationId'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Removed from wishlist'};
      } else {
        return {'success': false, 'message': 'Failed to remove'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ WEATHER ENDPOINTS ============

  /// Get latest stored user location
  static Future<Map<String, dynamic>> getLatestLocation({
    required String userIdentifier,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/latest?user_identifier=$userIdentifier'),
        headers: await getHeaders(),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'location': data['location']};
      }

      return {'success': false, 'message': 'No location found'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get current weather
  static Future<Map<String, dynamic>> getWeather(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/$lat/$lng'),
        headers: await getHeaders(),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'weather': data['weather']};
      } else {
        return {'success': false, 'message': 'Failed to fetch weather'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Weather request timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get weather forecast
  static Future<Map<String, dynamic>> getWeatherForecast(
    double lat,
    double lng, {
    int days = 4,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/$lat/$lng/forecast?days=$days'),
        headers: await getHeaders(),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'forecast': data['forecast']};
      }

      return {'success': false, 'message': 'Failed to fetch forecast'};
    } on TimeoutException {
      return {'success': false, 'message': 'Forecast request timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Push live GPS position to backend (fire-and-forget)
  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? city,
    String? country,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
          'captured_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  // ============ AI ENDPOINTS ============

  /// Send message to AI
  static Future<Map<String, dynamic>> sendAiMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'response': data['ai_response']};
      } else {
        return {'success': false, 'message': 'AI request failed'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'AI response timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ EMERGENCY ENDPOINTS ============

  /// Trigger SOS
  static Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
    String? locationDescription,
    String severity = 'High',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency/trigger'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'location_description': locationDescription,
          'severity': severity,
        }),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'SOS activated'};
      } else {
        return {'success': false, 'message': 'Failed to activate SOS'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'SOS request timed out. Check server connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ NOTIFICATIONS ENDPOINTS ============

  /// Get notifications
  static Future<Map<String, dynamic>> getNotifications({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?limit=$limit'),
        headers: await getHeaders(needsAuth: true),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'notifications': data['notifications']};
      } else {
        return {'success': false, 'message': 'Failed to fetch notifications'};
      }
    } on TimeoutException {
      return {'success': false, 'notifications': [], 'message': 'Request timed out'};
    } catch (e) {
      return {'success': false, 'notifications': [], 'message': 'Error: $e'};
    }
  }

  // ============ GENERIC HTTP METHODS ============

  static const Duration _kTimeout = Duration(seconds: 15);

  static Map<String, dynamic> _errorBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = decoded['error'] ?? decoded['message'] ?? 'Request failed: ${response.statusCode}';
      return {'success': false, 'message': msg.toString(), ...decoded};
    } catch (_) {
      return {'success': false, 'message': 'Request failed: ${response.statusCode}'};
    }
  }

  /// True once a background re-discovery has been kicked off, so repeated
  /// failed requests don't all trigger their own concurrent LAN scans.
  static bool _redetecting = false;

  /// If we're still stuck on the unvalidated compile-time default (discovery
  /// never succeeded, or the network has since changed), kick off another
  /// auto-discovery pass in the background. Fire-and-forget: the current
  /// (already-failed) request isn't retried, but the next one will pick up
  /// whatever initBaseUrl() lands on.
  static void _triggerRedetectIfStale() {
    if (_hasCustomUrl || _redetecting) return;
    _redetecting = true;
    initBaseUrl().catchError((_) {}).whenComplete(() => _redetecting = false);
  }

  /// Generic GET request
  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(needsAuth: true),
      ).timeout(_kTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _errorBody(response);
      }
    } on TimeoutException {
      _triggerRedetectIfStale();
      return {'success': false, 'message': 'Cannot reach server. Check your server URL in Settings.'};
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        _triggerRedetectIfStale();
        return {'success': false, 'message': 'Cannot connect to server ($serverHost). Check your server URL in Settings.'};
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Generic POST request
  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(timeout ?? _kTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return _errorBody(response);
      }
    } on TimeoutException {
      _triggerRedetectIfStale();
      return {'success': false, 'message': 'Cannot reach server. Check your server URL in Settings.'};
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        _triggerRedetectIfStale();
        return {'success': false, 'message': 'Cannot connect to server ($serverHost). Check your server URL in Settings.'};
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Generic PUT request
  static Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(_kTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return _errorBody(response);
      }
    } on TimeoutException {
      _triggerRedetectIfStale();
      return {'success': false, 'message': 'Cannot reach server. Check your server URL in Settings.'};
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        _triggerRedetectIfStale();
        return {'success': false, 'message': 'Cannot connect to server ($serverHost). Check your server URL in Settings.'};
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Generic DELETE request
  static Future<Map<String, dynamic>> deleteRequest(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(needsAuth: true),
      ).timeout(_kTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) return {'success': true};
        return jsonDecode(response.body);
      } else {
        return _errorBody(response);
      }
    } on TimeoutException {
      _triggerRedetectIfStale();
      return {'success': false, 'message': 'Cannot reach server. Check your server URL in Settings.'};
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        _triggerRedetectIfStale();
        return {'success': false, 'message': 'Cannot connect to server ($serverHost). Check your server URL in Settings.'};
      }
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ CURRENT USER ============

  /// Decode the stored JWT to extract the current user's DB id.
  static Future<int?> getCurrentUserId() async {
    try {
      final token = await AuthStorage.readToken();
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length < 2) return null;
      // Pad base64 to a multiple of 4
      String payload = parts[1];
      payload = payload.padRight(
          payload.length + (4 - payload.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final id = map['userId'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============ PROFILE PHOTO UPLOAD ============

  /// Upload profile photo bytes to backend. Returns {success, url}.
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    List<int> bytes,
    String filename,
  ) async {
    try {
      final token = await AuthStorage.readToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/profile/photo'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'photo', bytes, filename: filename,
      ));
      final streamed = await request.send().timeout(_kTimeout);
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Upload timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  // ============ FIREBASE TOKEN EXCHANGE ============

  /// Call after every Firebase sign-in (email, Google, Apple).
  /// Exchanges the Firebase ID token for a MySQL-backed JWT and stores it.
  /// Detects the auth provider from user.providerData and sends it to the backend
  /// so MySQL records the correct auth method.
  static Future<Map<String, dynamic>> exchangeFirebaseToken(
    User user, {
    String? phoneNumber,
    String? bloodGroup,
  }) async {
    try {
      final idToken = await user.getIdToken()
          .timeout(const Duration(seconds: 15));

      // Detect provider from Firebase user's linked provider data
      final provider = _detectAuthProvider(user);

      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase-exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_id_token':    idToken,
          'auth_provider':        provider,
          'full_name':            user.displayName,
          'profile_picture_url':  user.photoURL,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (bloodGroup  != null) 'blood_group':  bloodGroup,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await saveToken(token);
          final userData = data['user'] as Map<String, dynamic>?;
          if (userData != null) await _saveUserData(userData);
        }
        return {'success': true, ...data};
      } else {
        return {'success': false, 'message': 'Backend exchange failed: ${response.statusCode}'};
      }
    } on TimeoutException {
      debugPrint('[ApiService] exchangeFirebaseToken timed out — backend unreachable at $baseUrl');
      return {
        'success': false,
        'message': 'Cannot reach server. Please check your server URL in Settings.',
      };
    } catch (e) {
      debugPrint('[ApiService] exchangeFirebaseToken error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        return {
          'success': false,
          'message': 'Cannot connect to server ($serverHost). Please check your server URL in Settings.',
        };
      }
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Resolves the auth provider string from a Firebase [User]'s providerData.
  static String _detectAuthProvider(User user) {
    for (final info in user.providerData) {
      switch (info.providerId) {
        case 'google.com':   return 'GOOGLE';
        case 'apple.com':    return 'APPLE';
        case 'facebook.com': return 'FACEBOOK';
        case 'password':     return 'EMAIL';
      }
    }
    return 'EMAIL';
  }

  /// Save user data from firebase-exchange response to SharedPreferences
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', userData['is_admin'] == true);
    if (userData['user_id'] != null) {
      await prefs.setInt('user_id', (userData['user_id'] as num).toInt());
    }
    if (userData['email'] != null) {
      await prefs.setString('user_email', userData['email'] as String);
    }
    if (userData['full_name'] != null) {
      await prefs.setString('user_full_name', userData['full_name'] as String);
    }
    if (userData['firebase_uid'] != null) {
      await prefs.setString('firebase_uid', userData['firebase_uid'] as String);
    }
    if (userData['auth_provider'] != null) {
      await prefs.setString('auth_provider', userData['auth_provider'] as String);
    }
    if (userData['role'] != null) {
      await prefs.setString('user_role', userData['role'] as String);
    }
  }

  /// Returns the stored auth provider (EMAIL / GOOGLE / APPLE)
  static Future<String> getAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_provider') ?? 'EMAIL';
  }

  /// Returns true if the logged-in user has admin privileges.
  /// Checks both user JWT admin flag and presence of a dedicated admin JWT.
  static Future<bool> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_admin') == true) return true;
    final adminToken = await AuthStorage.readAdminToken();
    return adminToken != null && adminToken.isNotEmpty;
  }

  /// Returns the stored admin role ('super_admin' or 'moderator'), or null.
  static Future<String?> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_role');
  }

  /// Returns the stored admin display name.
  static Future<String> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_full_name')
        ?? prefs.getString('user_full_name')
        ?? 'Admin';
  }

  /// Returns stored MySQL user_id (not Firebase UID)
  static Future<int?> getMySqlUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Get current user ID (from Firebase)
  static String? get userId {
    return _auth.currentUser?.uid;
  }

  // ============ ADMIN-AUTHENTICATED HTTP METHODS ============
  // Use these for all /api/admin/* routes — they send the admin JWT, not the
  // user JWT, so pure-admin accounts (from AdminLoginPage) work correctly.

  static Future<Map<String, dynamic>> adminGetRequest(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getAdminHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Request failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminPostRequest(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getAdminHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      return {'success': false, 'message': decoded['error'] ?? 'Request failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminPutRequest(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getAdminHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      return {'success': false, 'message': decoded['error'] ?? 'Request failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> adminDeleteRequest(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getAdminHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) return {'success': true};
        return jsonDecode(response.body);
      }
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      return {'success': false, 'message': decoded['error'] ?? 'Request failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ JWT HELPERS ============

  /// Returns true if the stored JWT is missing or its exp claim is in the past.
  static Future<bool> isJwtExpired() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return true;
    return _isTokenExpired(token);
  }

  /// Silently re-exchanges the Firebase token for a fresh JWT if the current
  /// one is missing or expired. Call this on app startup.
  static Future<void> refreshTokenIfNeeded(User user) async {
    if (await isJwtExpired()) {
      try {
        await exchangeFirebaseToken(user);
      } catch (_) {
        // Backend may be offline — proceed without token; API calls will fail
        // gracefully with 401 which is handled per-screen.
      }
    }
  }

  /// Decodes a JWT (without verifying signature) and checks the exp claim.
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return false;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isBefore(DateTime.now());
    } catch (_) {
      return true;
    }
  }
}
