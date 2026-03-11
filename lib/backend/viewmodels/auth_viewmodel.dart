// viewmodels/auth_viewmodel.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/models/user_model.dart';
import 'package:safarsync_mobileapp/backend/repositories/auth_repository.dart';
import 'package:safarsync_mobileapp/backend/services/token_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  AuthState _authState = AuthState.initial;
  AuthState get authState => _authState;

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _errorType;
  String? get errorType => _errorType;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool get isLoading => _authState == AuthState.loading;
  bool get isAuthenticated => _authState == AuthState.authenticated;

  // Initialize auth state with global token manager
  Future<void> initializeAuth() async {
    _setAuthState(AuthState.loading);

    try {
      final isLoggedIn = await TokenManager.isLoggedIn();

      if (isLoggedIn) {
        final user = await TokenManager.getCurrentUser();

        if (user != null) {
          _currentUser = user;
          _setAuthState(AuthState.authenticated);
          log('✅ User authenticated from global storage: ${user.fullName}');

          // Debug: Print auth state
          await TokenManager.printAuthState();
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      log('❌ Auth initialization error: $e');
      _setErrorMessage('Failed to initialize authentication');
      _setAuthState(AuthState.error);
    }
  }

  // Login with global token management
  Future<bool> login({required String email, required String password}) async {
    _setAuthState(AuthState.loading);
    _clearError();
    _clearSuccess();

    try {
      log('🔐 Attempting login for: $email');

      final response = await AuthRepository.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = response['user'] as User;
        _setAuthState(AuthState.authenticated);
        _setSuccessMessage('Welcome back to SMAC!');
        log('✅ Login successful: ${_currentUser!.fullName}');

        // Debug: Print auth state
        await TokenManager.printAuthState();

        return true;
      } else {
        _setErrorMessage(response['message'] ?? 'Login failed');
        _setErrorType(response['errorType']);
        _setAuthState(AuthState.unauthenticated);
        log('❌ Login failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Login failed: ${e.toString()}');
      _setErrorType('unknown');
      _setAuthState(AuthState.error);
      log('❌ Login error: $e');
      return false;
    }
  }

  // Register with global token management
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setAuthState(AuthState.loading);
    _clearError();
    _clearSuccess();

    try {
      log('📝 Attempting registration for: $email');

      final response = await AuthRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = response['user'] as User;
        _setAuthState(AuthState.authenticated);
        _setSuccessMessage('Welcome to SMAC, ${_currentUser!.firstName}!');
        log('✅ Registration successful: ${_currentUser!.fullName}');

        // Debug: Print auth state
        await TokenManager.printAuthState();

        return true;
      } else {
        _setErrorMessage(response['message'] ?? 'Registration failed');
        _setErrorType(response['errorType']);
        _setAuthState(AuthState.unauthenticated);
        log('❌ Registration failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Registration failed: ${e.toString()}');
      _setErrorType('unknown');
      _setAuthState(AuthState.error);
      log('❌ Registration error: $e');
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    _setAuthState(AuthState.loading);
    _clearError();
    _clearSuccess();

    try {
      log('📧 Sending forgot password email to: $email');

      final response = await AuthRepository.forgotPassword(email: email);

      if (response['success'] == true) {
        _setAuthState(AuthState.unauthenticated);
        _setSuccessMessage('Password reset email sent to $email');
        log('✅ Forgot password email sent to: $email');
        return true;
      } else {
        _setErrorMessage(response['message'] ?? 'Failed to send reset email');
        _setErrorType(response['errorType']);
        _setAuthState(AuthState.unauthenticated);
        log('❌ Forgot password failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Failed to send reset email: ${e.toString()}');
      _setErrorType('unknown');
      _setAuthState(AuthState.error);
      log('❌ Forgot password error: $e');
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    _setAuthState(AuthState.loading);
    _clearError();
    _clearSuccess();

    try {
      log('🔑 Attempting password reset for: $email');

      final response = await AuthRepository.resetPassword(
        token: token,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _setAuthState(AuthState.unauthenticated);
        _setSuccessMessage(
          'Password reset successful! Please login with your new password.',
        );
        log('✅ Password reset successful');
        return true;
      } else {
        _setErrorMessage(response['message'] ?? 'Password reset failed');
        _setErrorType(response['errorType']);
        _setAuthState(AuthState.unauthenticated);
        log('❌ Password reset failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Password reset failed: ${e.toString()}');
      _setErrorType('unknown');
      _setAuthState(AuthState.error);
      log('❌ Password reset error: $e');
      return false;
    }
  }

  // Logout with complete cleanup
  Future<void> logout() async {
    _setAuthState(AuthState.loading);

    try {
      log('🚪 Logging out user: ${_currentUser?.fullName ?? 'Unknown'}');

      final response = await AuthRepository.logout();

      // Clear local state
      _currentUser = null;
      _clearError();
      _clearSuccess();
      _setAuthState(AuthState.unauthenticated);

      log('✅ Logout successful - All data cleared');

      // Debug: Print auth state after logout
      await TokenManager.printAuthState();
    } catch (e) {
      log('❌ Logout error: $e');
      // Even if there's an error, clear local data
      await TokenManager.clearAll();
      _currentUser = null;
      _clearError();
      _clearSuccess();
      _setAuthState(AuthState.unauthenticated);
    }
  }

  // Update user data
  Future<void> updateUserData(User updatedUser) async {
    try {
      _currentUser = updatedUser;
      await TokenManager.updateUserData(updatedUser);
      notifyListeners();
      log('✅ User data updated in AuthViewModel: ${updatedUser.fullName}');
    } catch (e) {
      log('❌ Failed to update user data in AuthViewModel: $e');
    }
  }

  // Get current token for API calls
  Future<String?> getCurrentToken() async {
    return await TokenManager.getToken();
  }

  // Private methods
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setErrorType(String? type) {
    _errorType = type;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Clear all messages
  void clearMessages() {
    _clearError();
    _clearSuccess();
  }

  // Get user-friendly error message
  String getDisplayErrorMessage() {
    if (_errorMessage == null) return '';

    // Handle common error messages
    if (_errorMessage!.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (_errorMessage!.toLowerCase().contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (_errorMessage!.toLowerCase().contains('email already exists')) {
      return 'This email is already registered. Please use a different email.';
    } else if (_errorMessage!.toLowerCase().contains('user not found')) {
      return 'No account found with this email address.';
    } else if (_errorType == 'Google User') {
      return 'This account is linked with Google. Please use Google Sign-In.';
    }

    return _errorMessage!;
  }
}
