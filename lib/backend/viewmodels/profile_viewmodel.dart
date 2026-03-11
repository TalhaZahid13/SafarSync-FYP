// viewmodels/profile_viewmodel.dart
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';
import 'package:safarsync_mobileapp/backend/repositories/profile_repository.dart';
import 'package:safarsync_mobileapp/backend/models/user_model.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ViewState _profileState = ViewState.initial;
  ViewState get profileState => _profileState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Current form data
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _phone = "";
  String _address = "";
  String _dateOfBirth = "";
  String _bio = "";
  String _country = "";
  String _language = "";
  String _gender = "";
  String _profilepic = "";

  // Getters for form data
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get dateOfBirth => _dateOfBirth;
  String get bio => _bio;
  String get country => _country;
  String get language => _language;
  String get gender => _gender;
  String get profilepic => _profilepic;

  // Fetch user data from local storage and API
  Future<void> fetchUserData() async {
    _profileState = ViewState.loading;
    notifyListeners();

    try {
      // Get from local storage
      final localUser = await TokenManager.getCurrentUser();
      if (localUser != null) {
        _updateUserData(localUser);
      }

      // 🔧 TEMPORARILY DISABLED - to avoid 404
      // final response = await ProfileRepository.getCurrentUserProfile();
      // if (response['success'] == true) {
      //   final user = response['user'] as User?;
      //   if (user != null) {
      //     _updateUserData(user);
      //   }
      // }

      _profileState = ViewState.loaded;
    } catch (e) {
      log('❌ Fetch User Data Error: $e');
      _errorMessage = 'Failed to fetch user data: ${e.toString()}';
      _profileState = ViewState.error;
    }

    notifyListeners();
  }

  // Update profile with form data
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,

    // required String email,
    // required String phone,
    // required String address,
    // required String dob,
    // required String bio,
    // required String country,
    // required String language,
    // required String gender,
  }) async {
    _profileState = ViewState.loading;
    _clearMessages();
    notifyListeners();

    try {
      final response = await ProfileRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,

        // email: email,
        // phone: phone,
        // address: address,
        // dateOfBirth: dob,
        // bio: bio,
        // country: country,
        // language: language,
        // gender: gender,
      );

      if (response['success'] == true) {
        final user = response['user'] as User?;
        if (user != null) {
          _updateUserData(user);
        }
        _successMessage = response['message'] ?? 'Profile updated successfully';
        _profileState = ViewState.loaded;
        log('✅ Profile updated successfully');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update profile';
        _profileState = ViewState.error;
        log('❌ Profile update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _profileState = ViewState.error;
      log('❌ Profile update error: $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateUserDetails({
    required String phone,
    // required String address,
    // required String dob,
    required String bio,
    // required String country,
    // required String language,
    // required String gender,
  }) async {
    _profileState = ViewState.loading;
    _clearMessages();
    notifyListeners();

    try {
      final response = await ProfileRepository.updateUserDetails(
        phone: phone,
        // address: address,
        // dateOfBirth: dob,
        bio: bio,
        // country: country,
        // language: language,
        // gender: gender,
      );

      if (response['success'] == true) {
        final user = response['user'] as User?;
        if (user != null) {
          _updateUserData(user);
        }
        _successMessage = response['message'] ?? 'Profile updated successfully';
        _profileState = ViewState.loaded;
        log('✅ Profile updated successfully');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update profile';
        _profileState = ViewState.error;
        log('❌ Profile update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _profileState = ViewState.error;
      log('❌ Profile update error: $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(File imageFile) async {
    _profileState = ViewState.loading;
    _clearMessages();
    notifyListeners();

    try {
      final response = await ProfileRepository.updateProfilePicture(
        imageFile: imageFile,
      );

      if (response['success'] == true) {
        final user = response['user'] as User?;
        if (user != null) {
          _updateUserData(user);
        }
        _successMessage =
            response['message'] ?? 'Profile picture updated successfully';
        _profileState = ViewState.loaded;
        log('✅ Profile picture updated successfully');
        return true;
      } else {
        _errorMessage =
            response['message'] ?? 'Failed to update profile picture';
        _profileState = ViewState.error;
        log('❌ Profile picture update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile picture: ${e.toString()}';
      _profileState = ViewState.error;
      log('❌ Profile picture update error: $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _profileState = ViewState.loading;
    _clearMessages();
    notifyListeners();

    try {
      if (newPassword != confirmPassword) {
        _errorMessage = 'New password and confirm password do not match';
        _profileState = ViewState.error;
        notifyListeners();
        return false;
      }

      final response = await ProfileRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        _successMessage =
            response['message'] ?? 'Password changed successfully';
        _profileState = ViewState.loaded;
        log('✅ Password changed successfully');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to change password';
        _profileState = ViewState.error;
        log('❌ Password change failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to change password: ${e.toString()}';
      _profileState = ViewState.error;
      log('❌ Password change error: $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Private helper methods
  void _updateUserData(User user) {
    _currentUser = user;
    _firstName = user.firstName;
    _lastName = user.lastName;
    _email = user.email;
    _phone = user.phoneNumber ?? "";
    _address = user.address ?? "";
    _dateOfBirth = user.dob ?? "";
    _bio = user.bio ?? "";
    _country = "Pakistan"; // Default or from user data
    _language = "English, Urdu"; // Default or from user data
    _gender = "Not specified"; // Default or from user data
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  // Clear all messages
  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  // Get display error message
  String getDisplayErrorMessage() {
    if (_errorMessage == null) return '';

    if (_errorMessage!.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (_errorMessage!.toLowerCase().contains('token')) {
      return 'Session expired. Please login again.';
    }

    return _errorMessage!;
  }
}
