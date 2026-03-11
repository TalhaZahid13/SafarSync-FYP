// repositories/auth_repository.dart
import 'dart:developer';

import 'package:safarsync_mobileapp/backend/models/auth_response.dart';
import 'package:safarsync_mobileapp/backend/models/user_model.dart';
import 'package:safarsync_mobileapp/backend/services/api_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class AuthRepository {
  // Login API with global token management
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: '/auth/user/login',
        body: {'email': email, 'password': password},
      );

      if (response['success'] == true) {
        final authResponse = AuthResponse.fromJson(response['data']);

        // Save token and user data globally
        await TokenManager.saveToken(authResponse.token);
        await TokenManager.saveUserData(authResponse.user);

        log('✅ Login successful - Token and user data saved globally');

        return {
          'success': true,
          'message': authResponse.message,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else {
        // Handle specific error types
        String errorMessage = response['message'] ?? 'Login failed';
        String? errorType = response['errorType'];

        if (errorType == 'Google User') {
          errorMessage =
              'This account is linked with Google. Please use Google Sign-In to continue.';
        } else if (response['statusCode'] == 401) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (response['statusCode'] == 404) {
          errorMessage = 'No account found with this email address.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response['statusCode'],
        };
      }
    } catch (e) {
      log('❌ Login Repository Error: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // Register API with global token management
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: '/auth/user/register-user',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        },
      );

      if (response['success'] == true) {
        final authResponse = AuthResponse.fromJson(response['data']);

        // Save token and user data globally
        await TokenManager.saveToken(authResponse.token);
        await TokenManager.saveUserData(authResponse.user);

        log('✅ Registration successful - Token and user data saved globally');

        return {
          'success': true,
          'message': authResponse.message,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else {
        String errorMessage = response['message'] ?? 'Registration failed';
        String? errorType = response['errorType'];

        if (response['statusCode'] == 409 ||
            errorMessage.toLowerCase().contains('already exists')) {
          errorMessage =
              'An account with this email already exists. Please try logging in instead.';
        } else if (response['statusCode'] == 422) {
          errorMessage = 'Please check your information and try again.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
          'statusCode': response['statusCode'],
        };
      }
    } catch (e) {
      log('❌ Register Repository Error: $e');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // Logout with complete cleanup
  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await TokenManager.getToken();

      // Try to call logout API if token exists
      if (token != null) {
        try {
          final response = await ApiService.post(
            endpoint: '/auth/user/logout',
            body: {},
            token: token,
          );
          log('📡 Logout API called: ${response['success']}');
        } catch (e) {
          log('⚠️ Logout API failed, but continuing with local cleanup: $e');
        }
      }

      // Always clear local data regardless of API response
      await TokenManager.clearAll();

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      log('❌ Logout Repository Error: $e');
      // Even if there's an error, try to clear local data
      await TokenManager.clearAll();
      return {'success': true, 'message': 'Logged out successfully'};
    }
  }

  // Get current user from API (with token)
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await TokenManager.getToken();

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await ApiService.get(
        endpoint: '/auth/user/profile', // Update with your actual endpoint
        token: token,
      );

      if (response['success'] == true) {
        // Update local user data if API call successful
        final userData = response['data']['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          await TokenManager.updateUserData(user);
        }
      }

      return response;
    } catch (e) {
      log('❌ Get Current User Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to get user data: ${e.toString()}',
      };
    }
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: '/auth/user/forgot-password',
        body: {'email': email},
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message':
              response['data']?['message'] ?? 'Reset email sent successfully',
        };
      } else {
        String errorMessage =
            response['message'] ?? 'Failed to send reset email';
        String? errorType = response['errorType'];

        if (errorType == 'Google User') {
          errorMessage =
              'This account uses Google Sign-In. Please reset your password through Google.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'errorType': errorType,
        };
      }
    } catch (e) {
      log('❌ Forgot Password Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to send reset email: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: '/auth/user/reset-password',
        body: {'token': token, 'email': email, 'password': password},
      );

      return {
        'success': response['success'],
        'message':
            response['data']?['message'] ??
            response['message'] ??
            'Password reset successful',
      };
    } catch (e) {
      log('❌ Reset Password Repository Error: $e');
      return {
        'success': false,
        'message': 'Password reset failed: ${e.toString()}',
      };
    }
  }
}
