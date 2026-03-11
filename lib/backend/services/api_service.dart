// services/api_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class ApiService {
  static const String baseUrl = 'https://smacltd.com/api';
  static const Duration timeout = Duration(seconds: 30);

  // Headers with token from global manager
  static Future<Map<String, String>> _getHeaders({String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // If token is not provided, try to get from global manager
    token ??= await TokenManager.getToken();

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // POST Request with token from global manager
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      log('🌐 POST: $baseUrl$endpoint');
      log('📤 Request Body: ${jsonEncode(body)}');

      final headers = await _getHeaders(token: token);

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      log('📱 Response Status: ${response.statusCode}');
      log('📱 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = responseData['message'] ?? 'An error occurred';
        String? errorType = responseData['error'];

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'errorType': 'network',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
        'errorType': 'network',
      };
    } catch (e) {
      log('❌ POST Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // GET Request with token from global manager
  static Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
  }) async {
    try {
      log('🌐 GET: $baseUrl$endpoint');

      final headers = await _getHeaders(token: token);

      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeout);

      log('📱 Response Status: ${response.statusCode}');
      log('📱 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = responseData['message'] ?? 'An error occurred';
        String? errorType = responseData['error'];

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'errorType': 'network',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
        'errorType': 'network',
      };
    } catch (e) {
      log('❌ GET Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // PUT Request with token from global manager
  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      log('🌐 PUT: $baseUrl$endpoint');
      log('📤 Request Body: ${jsonEncode(body)}');

      final headers = await _getHeaders(token: token);

      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      log('📱 Response Status: ${response.statusCode}');
      log('📱 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = responseData['message'] ?? 'An error occurred';
        String? errorType = responseData['error'];

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } catch (e) {
      log('❌ PUT Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // DELETE Request with token from global manager
  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    String? token,
  }) async {
    try {
      log('🌐 DELETE: $baseUrl$endpoint');

      final headers = await _getHeaders(token: token);

      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeout);

      log('📱 Response Status: ${response.statusCode}');
      log('📱 Response Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMessage = responseData['message'] ?? 'An error occurred';
        String? errorType = responseData['error'];

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } catch (e) {
      log('❌ DELETE Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }
}
