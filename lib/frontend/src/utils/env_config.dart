/// Build-time configuration for the Supabase cloud backend.
///
/// The app talks only to Supabase Cloud — there is no local server, IP
/// address or backend URL for users (or developers) to configure.
///
/// Values can be overridden per environment at build time:
///
///   flutter build apk --release --dart-define-from-file=env/production.json
///
/// (see env/production.example.json). The defaults below point at the
/// production SafarSync Supabase project.
///
/// SECURITY: the publishable key is designed to ship inside client apps; every
/// table is protected by Row Level Security and privileged work happens in
/// the `api` Edge Function. Never put the service_role / secret key here.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zjjbnrqtfnewwfxuahga.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_D05-8RK9AZS9MjEUijotRg_cwAA5dCC',
  );

  /// Google OAuth *Web* client id (the same one configured in
  /// Supabase → Authentication → Providers → Google). Needed on Android so
  /// Google Sign-In returns an ID token Supabase can verify.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '495483479742-qoqoir127ehif49jln99bihlmnmssi4r.apps.googleusercontent.com',
  );

  /// Deep link that Supabase Auth emails (confirm signup, reset password)
  /// redirect back to. Must also be listed under Authentication → URL
  /// Configuration → Redirect URLs in the Supabase dashboard.
  static const String authRedirectUrl = 'io.safarsync.app://login-callback';

  /// Base URL of the SafarSync REST API (Supabase Edge Function `api`).
  static String get apiBaseUrl => '$supabaseUrl/functions/v1/api';

  /// Null when the configuration is usable, otherwise a developer-facing
  /// explanation of what is wrong.
  static String? get configurationError {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
      return 'SUPABASE_URL "$supabaseUrl" is not a valid https URL';
    }
    if (supabasePublishableKey.trim().isEmpty) {
      return 'SUPABASE_PUBLISHABLE_KEY is not set';
    }
    if (supabasePublishableKey.contains('service_role') ||
        supabasePublishableKey.startsWith('sb_secret_')) {
      return 'A secret/service_role key must never be bundled in the app';
    }
    return null;
  }

  static bool get isConfigured => configurationError == null;
}
