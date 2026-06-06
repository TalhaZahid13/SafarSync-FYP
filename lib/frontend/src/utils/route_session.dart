import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'vehicle_type.dart';

/// Persists one "active route" to SharedPreferences so it survives app restarts.
/// Also syncs to the backend (fire-and-forget) so the route is stored in the DB.
class RouteSession {
  static const _key = 'active_route_v1';

  static Future<void> activate({
    required String routeName,
    required String fromName,
    required String toName,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    DateTime? travelDate,
    VehicleType vehicleType = VehicleType.car,
  }) async {
    final data = {
      'route_name': routeName,
      'from_name': fromName,
      'to_name': toName,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'vehicle_type': vehicleType.name,
      if (travelDate != null) 'travel_date': travelDate.toIso8601String(),
      'activated_at': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));

    // Sync to backend — fire-and-forget, errors must not block navigation.
    ApiService.createRoute(
      routeName: routeName,
      startLocation: fromName,
      endLocation: toName,
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    ).ignore();
  }

  static Future<Map<String, dynamic>?> getActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
