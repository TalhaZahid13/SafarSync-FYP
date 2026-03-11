// repositories/profile_repository.dart (NEW FILE)
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:safarsync_mobileapp/backend/services/api_service.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';
import 'package:safarsync_mobileapp/backend/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileRepository {
  // Update profile with text data
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    // required String email,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final id = await TokenManager; //.getID();

      final response = await ApiService.put(
        endpoint: '/user/user-personal',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          // 'email': email,
          // 'phoneNumber': phone,
          // 'address': address,
          // 'dob': dateOfBirth,
          // 'bio': bio,
          // 'country': country,
          // 'language': language,
          // 'gender': gender,
        },
        token: token,
        //id: id,
      );

      if (response['success'] == true) {
        // Update local user data
        final userData = response['data']['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          await TokenManager.updateUserData(user);
        }

        return {
          'success': true,
          'message':
              response['data']['message'] ?? 'Profile updated successfully',
          'user': userData != null ? User.fromJson(userData) : null,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      log('❌ Update Profile Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserDetails({
    required String phone,
    // required String dateOfBirth,
    required String bio,
  }) async {
    try {
      final token = await TokenManager.getToken();

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      log("🌐 PATCH: ${ApiService.baseUrl}/user/user-details");

      final body = {"phoneNumber": phone, "bio": bio};

      final response = await http.patch(
        Uri.parse("${ApiService.baseUrl}/user/user-details"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📩 Update User Details Response: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);

        if (responseData['data'] != null) {
          final user = User.fromJson(responseData['data']);
          await TokenManager.updateUserData(user);
        }

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'User details updated successfully',
          'user': responseData['data'] != null
              ? User.fromJson(responseData['data'])
              : null,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update user details',
        };
      }
    } catch (e) {
      log('❌ Update User Details Error: $e');
      return {
        'success': false,
        'message': 'Failed to update user details: ${e.toString()}',
      };
    }
  }

  // Update profile picture
  static Future<Map<String, dynamic>> updateProfilePicture({
    required File imageFile,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final id = await TokenManager; //.getID();

      if (token == null || id == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      // Detect extension
      String ext = imageFile.path.split('.').last.toLowerCase();
      final contentType = (ext == 'png')
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      log("🌐 PATCH: ${ApiService.baseUrl}/user/profilepic");
      log("📂 Uploading File: ${imageFile.path}");
      log("📑 Detected ContentType: $contentType");

      // Create multipart request
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiService.baseUrl}/user/profilepic'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePic',
          imageFile.path,
          contentType: contentType,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('📷 Profile Picture Update Response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);

        // Update local user data
        if (responseData['data'] != null) {
          final user = User.fromJson(responseData['data']);
          await TokenManager.updateUserData(user);
        }

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Profile picture updated successfully',
          'user': User.fromJson(responseData['data']),
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to update profile picture',
        };
      }
    } catch (e) {
      log('❌ Update Profile Picture Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to update profile picture: ${e.toString()}',
      };
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await TokenManager.getToken();

      final response = await ApiService.put(
        endpoint: '/auth/user/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        token: token,
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message':
              response['data']['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      log('❌ Change Password Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to change password: ${e.toString()}',
      };
    }
  }

  // Get current user profile from API
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final token = await TokenManager.getToken();

      // 🔧 TRY THIS ENDPOINT - common alternative
      final response = await ApiService.get(
        endpoint: '/user/profile', // Changed from '/auth/user/profile'
        token: token,
      );

      if (response['success'] == true) {
        final userData = response['data']['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          await TokenManager.updateUserData(user);
        }

        return {
          'success': true,
          'message': 'Profile fetched successfully',
          'user': userData != null ? User.fromJson(userData) : null,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      log('❌ Get Profile Repository Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch profile: ${e.toString()}',
      };
    }
  }
}
