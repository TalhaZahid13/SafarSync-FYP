import 'package:flutter/foundation.dart';

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
  static const String stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE';

  // Base URL for Socket.io
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.5:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }
}
