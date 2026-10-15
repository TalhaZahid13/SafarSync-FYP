import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'auth_storage.dart';
import 'env_config.dart';
import 'local_database_service.dart';
import 'session_manager.dart';

enum GoogleSignInStatus { success, cancelled, failure }

class GoogleSignInResult {
  final GoogleSignInStatus status;
  final String? message;
  final User? user;

  const GoogleSignInResult._(this.status, {this.message, this.user});

  const GoogleSignInResult.success(User user)
      : this._(GoogleSignInStatus.success, user: user);
  const GoogleSignInResult.cancelled()
      : this._(GoogleSignInStatus.cancelled);
  const GoogleSignInResult.failure(String message)
      : this._(GoogleSignInStatus.failure, message: message);
}

/// Google → Firebase Auth → SafarSync backend sign-in.
///
/// 1. Google account picker returns an ID token.
/// 2. Firebase Auth signs in with that credential.
/// 3. The Firebase ID token is exchanged at the hosted backend
///    (POST /api/auth/firebase-exchange) for the app JWT, which is stored in
///    secure storage by [ApiService.exchangeFirebaseToken].
///
/// If any step fails, every partial sign-in is rolled back so the app never
/// ends up "half logged in" (Firebase user present but no backend session).
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static Future<GoogleSignInResult> signIn() async {
    final configError = EnvConfig.configurationError;
    if (configError != null) {
      debugPrint('[GoogleAuth] $configError');
      return const GoogleSignInResult.failure(
        'This build of SafarSync has no server configured. Please contact support.',
      );
    }

    final User? user;
    try {
      user = await _firebaseSignInWithGoogle();
    } on _Cancelled {
      return const GoogleSignInResult.cancelled();
    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleAuth] FirebaseAuthException ${e.code}: ${e.message}');
      await _rollback();
      return GoogleSignInResult.failure(_firebaseErrorMessage(e));
    } on PlatformException catch (e) {
      debugPrint('[GoogleAuth] PlatformException ${e.code}: ${e.message}');
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        return const GoogleSignInResult.cancelled();
      }
      await _rollback();
      return GoogleSignInResult.failure(_platformErrorMessage(e));
    } catch (e) {
      debugPrint('[GoogleAuth] Unexpected error: $e');
      await _rollback();
      return const GoogleSignInResult.failure(
        'Google sign-in failed. Please try again.',
      );
    }

    if (user == null) {
      await _rollback();
      return const GoogleSignInResult.failure(
        'Google sign-in failed. Please try again.',
      );
    }

    try {
      await LocalDatabaseService.upsertUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName,
      );
    } catch (e) {
      debugPrint('[GoogleAuth] Local profile cache failed (non-fatal): $e');
    }

    final exchange = await ApiService.exchangeFirebaseToken(user);
    if (exchange['success'] != true) {
      await _rollback();
      return GoogleSignInResult.failure(
        exchange['message'] as String? ?? 'Could not reach the SafarSync server.',
      );
    }

    // Google users always stay signed in until they log out or the 7-day
    // inactivity window in SessionManager expires.
    await SessionManager.setRememberMeEmail(user.email ?? '', true);
    await SessionManager.recordActivity();
    return GoogleSignInResult.success(user);
  }

  /// Signs out of the Google account so the account picker is shown again
  /// on the next sign-in. Safe to call when no Google session exists.
  static Future<void> signOut() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuth] Google signOut failed (non-fatal): $e');
    }
  }

  static Future<User?> _firebaseSignInWithGoogle() async {
    final auth = FirebaseAuth.instance;

    if (kIsWeb) {
      try {
        final cred = await auth.signInWithPopup(
          GoogleAuthProvider()..addScope('email'),
        );
        return cred.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw const _Cancelled();
        }
        rethrow;
      }
    }

    final account = await _googleSignIn.signIn();
    if (account == null) throw const _Cancelled();

    final googleAuth = await account.authentication;
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google returned no ID token.',
      );
    }

    final cred = await auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
    return cred.user;
  }

  static Future<void> _rollback() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await signOut();
    try {
      await AuthStorage.clearToken();
    } catch (_) {}
  }

  static String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method. '
            'Sign in with email and password instead.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled for this app yet.';
      case 'invalid-credential':
        return 'Google sign-in could not be verified. Please try again.';
      default:
        return 'Google sign-in failed: ${e.message ?? e.code}';
    }
  }

  static String _platformErrorMessage(PlatformException e) {
    if (e.code == GoogleSignIn.kNetworkError) {
      return 'No internet connection. Please check your network and try again.';
    }
    // ApiException 10 = DEVELOPER_ERROR: the app's SHA-1 / package name is not
    // registered for an Android OAuth client in the Firebase project.
    final details = '${e.message ?? ''} ${e.details ?? ''}';
    if (e.code == GoogleSignIn.kSignInFailedError && details.contains('10')) {
      debugPrint('[GoogleAuth] DEVELOPER_ERROR — add this build\'s SHA-1 to Firebase.');
      return 'Google sign-in is not configured for this build of the app.';
    }
    return 'Google sign-in failed. Please try again.';
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
