// repositories/course_repository.dart - Simplified version
import 'package:safarsync_mobileapp/backend/models/course_model.dart';
import 'package:safarsync_mobileapp/backend/services/api_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class CourseRepository {
  // Fetch all courses
  static Future<Map<String, dynamic>> fetchCourses() async {
    try {
      final token = await TokenManager.getToken();

      final response = await ApiService.get(endpoint: '/course', token: token);

      if (response['success'] == true) {
        final List<dynamic> coursesData = response['data']['data'];
        final List<CourseModel> courses = coursesData
            .map((json) => CourseModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'message':
              response['data']['message'] ?? 'Courses fetched successfully',
          'courses': courses,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch courses',
        };
      }
    } catch (e) {
      print('❌ Fetch Courses Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch courses: ${e.toString()}',
      };
    }
  }
}
