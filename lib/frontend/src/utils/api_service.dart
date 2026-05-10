import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';

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

  static final String baseUrl = _resolveBaseUrl();

  /// Socket.io server URL (same host, no /api path)
  static String get socketUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _resolveBaseUrl() {
    if (_baseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlOverride);
    }

    final host = _defaultHostForPlatform();
    return 'http://$host:5000/api';
  }

  static String _defaultHostForPlatform() {
    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Physical devices should use your PC LAN IP.
        // Emulator users can override with --dart-define=ANDROID_API_HOST=10.0.2.2
        if (_androidHostOverride.isNotEmpty) {
          return _androidHostOverride;
        }
        return '192.168.1.5';
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Remove JWT token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
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

      await saveToken(user.uid);

      final existingProfile = await LocalDatabaseService.getUserProfile(
        user.uid,
      );
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

  /// Get all destinations from local SQLite
  static Future<Map<String, dynamic>> getDestinations({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    try {
      await LocalDatabaseService.ensureInitialized();
      final destinations = await LocalDatabaseService.getDestinations(
        page: page,
        limit: limit,
        category: category,
      );

      return {'success': true, 'destinations': destinations};
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'wishlist': data['wishlist']};
      } else {
        return {'success': false, 'message': 'Failed to fetch wishlist'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
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
      );

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'weather': data['weather']};
      } else {
        return {'success': false, 'message': 'Failed to fetch weather'};
      }
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'forecast': data['forecast']};
      }

      return {'success': false, 'message': 'Failed to fetch forecast'};
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'response': data['ai_response']};
      } else {
        return {'success': false, 'message': 'AI request failed'};
      }
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
        Uri.parse('$baseUrl/emergency/sos'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'location_description': locationDescription,
          'severity': severity,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'SOS activated'};
      } else {
        return {'success': false, 'message': 'Failed to activate SOS'};
      }
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'notifications': data['notifications']};
      } else {
        return {'success': false, 'message': 'Failed to fetch notifications'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
