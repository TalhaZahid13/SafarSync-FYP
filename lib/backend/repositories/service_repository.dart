import 'package:safarsync_mobileapp/backend/models/service_model.dart';
import 'package:safarsync_mobileapp/backend/services/api_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class ServiceRepository {
  // Fetch all services
  static Future<Map<String, dynamic>> fetchServices() async {
    try {
      final token = await TokenManager.getToken();

      final response = await ApiService.get(endpoint: '/service', token: token);

      if (response['success'] == true) {
        final List<dynamic> servicesData = response['data']['data'];
        final List<ServiceModel> services = servicesData
            .map((json) => ServiceModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'message':
              response['data']['message'] ?? 'Services fetched successfully',
          'services': services,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch services',
        };
      }
    } catch (e) {
      print('❌ Fetch Services Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch services: ${e.toString()}',
      };
    }
  }
}
