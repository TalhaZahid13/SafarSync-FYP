/// App-level configuration constants for third-party client SDKs.
///
/// Only *publishable* keys belong here — they are designed to ship inside
/// the app. Secret keys (Stripe secret, Groq, SMTP, Supabase service role)
/// live exclusively in Supabase Edge Function secrets.
class AppConfig {
  /// Google Maps Directions API key (optional — the live map falls back to
  /// straight-line routing without it). Provide at build time with
  /// `--dart-define=GOOGLE_MAPS_API_KEY=...` and restrict it to this app's
  /// package name + SHA-1 in Google Cloud Console.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
  );

  /// Stripe publishable key (pk_test_… for testing, pk_live_… for production).
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51TkPj29sYqO35RjxFYPqslL4gXqkdm6tzOdMBfsLBNlg6l5e3FVPvYuSQTrMXjmjiGHvLU9S1dqmB2uF2x9tpjI100UsVOCCBB',
  );
}
