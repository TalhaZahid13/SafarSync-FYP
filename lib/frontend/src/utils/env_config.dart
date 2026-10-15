import 'package:flutter/foundation.dart';

/// Build-time environment configuration.
///
/// The backend URL is baked into the app at build time — users never type an
/// IP address. Provide it with:
///
///   flutter run   --dart-define-from-file=env/production.json
///   flutter build apk --release --dart-define-from-file=env/production.json
///
/// where env/production.json contains e.g.
///   { "API_BASE_URL": "https://safarsync-api.onrender.com/api" }
///
/// See env/production.example.json.
///
/// A plain `flutter build apk --release` (no dart-define) falls back to
/// [_productionApiBaseUrl] — set it once the backend is deployed.
class EnvConfig {
  /// Hosted HTTPS backend used when API_BASE_URL is not passed at build time,
  /// e.g. 'https://safarsync-api.onrender.com/api'.
  static const String _productionApiBaseUrl = '';

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _productionApiBaseUrl,
  );

  /// Base URL of the REST API, always ending in `/api`, no trailing slash.
  static final String apiBaseUrl = _normalize(_rawApiBaseUrl);

  /// Origin of the backend (no `/api`), used for Socket.io and static uploads.
  static String get serverOrigin => apiBaseUrl.endsWith('/api')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 4)
      : apiBaseUrl;

  /// Null when the configuration is usable, otherwise a developer-facing
  /// explanation of what is wrong.
  static String? get configurationError {
    if (_rawApiBaseUrl.trim().isEmpty) {
      return 'API_BASE_URL is not set. Build with '
          '--dart-define-from-file=env/production.json';
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasAuthority) {
      return 'API_BASE_URL "$_rawApiBaseUrl" is not a valid URL';
    }
    // Release builds must talk to a hosted HTTPS endpoint. Plain http is only
    // tolerated in debug builds (e.g. pointing at a local dev server).
    if (uri.scheme != 'https' && !(kDebugMode && uri.scheme == 'http')) {
      return 'API_BASE_URL must use https:// (got "$_rawApiBaseUrl")';
    }
    return null;
  }

  static bool get isConfigured => configurationError == null;

  static String _normalize(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isNotEmpty && !url.endsWith('/api')) url = '$url/api';
    return url;
  }
}
