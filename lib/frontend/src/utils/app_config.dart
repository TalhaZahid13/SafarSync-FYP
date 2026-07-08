import 'api_service.dart';

/// App-level configuration constants.
///
/// HOW TO GET YOUR GOOGLE MAPS KEY:
/// 1. Go to https://console.cloud.google.com
/// 2. Select your Firebase project (same project as google-services.json)
/// 3. APIs & Services → Library → enable "Directions API"
/// 4. APIs & Services → Credentials → Create API Key
/// 5. Paste the key below.
///
/// Free monthly quota: $200 credit ≈ 40,000 Directions requests — more than enough.
class AppConfig {
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Stripe — get from https://dashboard.stripe.com/apikeys
  // Use pk_test_... for development, pk_live_... for production
  static const String stripePublishableKey =
      'pk_test_51TkPj29sYqO35RjxFYPqslL4gXqkdm6tzOdMBfsLBNlg6l5e3FVPvYuSQTrMXjmjiGHvLU9S1dqmB2uF2x9tpjI100UsVOCCBB';

  // Socket.io server URL — always derived from ApiService so there is one source of truth.
  static String get baseUrl => ApiService.socketUrl;
}
