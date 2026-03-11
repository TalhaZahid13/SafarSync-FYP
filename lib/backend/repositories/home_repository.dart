import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safarsync_mobileapp/backend/models/gig_model.dart'; // Correct model import
import 'package:safarsync_mobileapp/backend/models/notification_model.dart'; // Correct model import

class HomeRepository {
  final String _baseUrl = "https://smacltd.com/api";

  Future<List<GigModel>> fetchGigs() async {
    // Gig ko GigModel kar diya
    final response = await http.get(Uri.parse("$_baseUrl/gigs"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => GigModel.fromJson(json))
          .toList(); // Gig.fromJson ko GigModel.fromJson kar diya
    } else {
      // API call failed, throw a more descriptive exception
      throw Exception(
        "Failed to load gigs: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    // AppNotification ko NotificationModel kar diya
    final response = await http.get(Uri.parse("$_baseUrl/notifications"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => NotificationModel.fromJson(json))
          .toList(); // AppNotification.fromJson ko NotificationModel.fromJson kar diya
    } else {
      // API call failed, throw a more descriptive exception
      throw Exception(
        "Failed to load notifications: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
