import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  const GoogleSignInResult.cancelled() : this._(GoogleSignInStatus.cancelled);
  const GoogleSignInResult.failure(String message)
    : this._(GoogleSignInStatus.failure, message: message);
}

/// Native Google Sign-In → Supabase Auth.
///
/// 1. The Google account picker returns an ID token (issued for the *web*
///    OAuth client, [EnvConfig.googleWebClientId]).
/// 2. `signInWithIdToken` exchanges it for a Supabase session.
/// 3. The session is registered with the SafarSync API.
///
/// Any failure rolls every step back so the app is never half signed in.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: kIsWeb ? null : EnvConfig.googleWebClientId,
  );

  static Future<GoogleSignInResult> signIn() async {
    final client = Supabase.instance.client;
    try {
      if (kIsWeb) {
        await client.auth.signInWithOAuth(OAuthProvider.google);
        return const GoogleSignInResult.cancelled(); // completes via redirect
      }

      final account = await _googleSignIn.signIn();
      if (account == null) return const GoogleSignInResult.cancelled();

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        await _rollback();
        return const GoogleSignInResult.failure(
          'Google did not return an ID token. Google sign-in is not fully configured for this build.',
        );
      }

      final res = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      final user = res.user;
      if (user == null) {
        await _rollback();
        return const GoogleSignInResult.failure(
          'Google sign-in failed. Please try again.',
        );
      }

      try {
        await LocalDatabaseService.upsertUserProfile(
          uid: user.id,
          email: user.email ?? '',
          fullName: ApiService.displayName(user),
        );
      } catch (e) {
        debugPrint('[GoogleAuth] Local profile cache failed (non-fatal): $e');
      }

      final sync = await ApiService.syncSession();
      if (sync['success'] != true) {
        await _rollback();
        return GoogleSignInResult.failure(
          sync['message'] as String? ??
              'Could not reach SafarSync. Please try again.',
        );
      }

      // Google users stay signed in until they log out or the 7-day
      // inactivity window in SessionManager expires.
      await SessionManager.setRememberMeEmail(user.email ?? '', true);
      await SessionManager.recordActivity();
      return GoogleSignInResult.success(user);
    } on AuthException catch (e) {
      debugPrint('[GoogleAuth] AuthException ${e.statusCode}: ${e.message}');
      await _rollback();
      final m = e.message.toLowerCase();
      if (m.contains('provider is not enabled') ||
          m.contains('unsupported provider')) {
        return const GoogleSignInResult.failure(
          'Google sign-in is not enabled for this app yet.',
        );
      }
      return GoogleSignInResult.failure('Google sign-in failed: ${e.message}');
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
  }

  /// Signs out of the Google account so the picker is shown next time.
  static Future<void> signOut() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuth] Google signOut failed (non-fatal): $e');
    }
  }

  static Future<void> _rollback() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await signOut();
    try {
      await AuthStorage.clearToken();
    } catch (_) {}
  }

  static String _platformErrorMessage(PlatformException e) {
    if (e.code == GoogleSignIn.kNetworkError) {
      return 'No internet connection. Please check your network and try again.';
    }
    // ApiException 10 = DEVELOPER_ERROR: this build's package name / SHA-1
    // is not registered as an Android OAuth client in Google Cloud.
    final details = '${e.message ?? ''} ${e.details ?? ''}';
    if (e.code == GoogleSignIn.kSignInFailedError && details.contains('10')) {
      debugPrint(
        "[GoogleAuth] DEVELOPER_ERROR — register this build's SHA-1 in Google Cloud.",
      );
      return 'Google sign-in is not configured for this build of the app.';
    }
    return 'Google sign-in failed. Please try again.';
  }
}
