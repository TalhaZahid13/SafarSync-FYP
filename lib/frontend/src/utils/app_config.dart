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
}
