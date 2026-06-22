import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';

// ─── Destination Theme System ─────────────────────────────────────────────────
// Adapts accent colors + gradients based on the user's active/upcoming booking
// destination. Manual override in Settings always takes priority.

enum DestinationThemeType {
  defaultTheme,
  snow,
  desert,
  beach,
  mountain,
  forest,
  urban,
}

// ─── Theme Data ───────────────────────────────────────────────────────────────

class DestinationTheme {
  final DestinationThemeType type;
  final String label;
  final String emoji;
  final Color primary;
  final Color accent;
  final List<Color> heroDark;    // dark-mode hero/header
  final List<Color> heroLight;   // light-mode hero/header
  final List<Color> navGradient; // bottom nav active gradient

  const DestinationTheme({
    required this.type,
    required this.label,
    required this.emoji,
    required this.primary,
    required this.accent,
    required this.heroDark,
    required this.heroLight,
    required this.navGradient,
  });

  LinearGradient get heroGradientDark => LinearGradient(
        colors: heroDark,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradientLight => LinearGradient(
        colors: heroLight,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get navActiveGradient => LinearGradient(
        colors: navGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Predefined themes ─────────────────────────────────────────────────────

  static const DestinationTheme kDefault = DestinationTheme(
    type: DestinationThemeType.defaultTheme,
    label: 'Default',
    emoji: '✈️',
    primary: Color(0xFF2CAFBC),
    accent: Color(0xFFFDB913),
    heroDark:  [Color(0xFF0D1B2A), Color(0xFF1B3A4C), Color(0xFF1B5A6E)],
    heroLight: [Color(0xFFF5F6FA), Color(0xFFEFF9FA), Color(0xFFE3F5F7)],
    navGradient: [Color(0xFF9A9E9D), Color(0xFF2CAFBC)],
  );

  static const DestinationTheme kSnow = DestinationTheme(
    type: DestinationThemeType.snow,
    label: 'Snow',
    emoji: '❄️',
    primary: Color(0xFF7EC8E3),
    accent: Color(0xFFB8E0FF),
    heroDark:  [Color(0xFF1A2A3A), Color(0xFF2A3D52), Color(0xFF4A7A9B)],
    heroLight: [Color(0xFFF0F8FF), Color(0xFFDCEEFA), Color(0xFFC8DEFF)],
    navGradient: [Color(0xFF4A7A9B), Color(0xFF7EC8E3)],
  );

  static const DestinationTheme kDesert = DestinationTheme(
    type: DestinationThemeType.desert,
    label: 'Desert',
    emoji: '🏜️',
    primary: Color(0xFFD4955A),
    accent: Color(0xFFF0C070),
    heroDark:  [Color(0xFF2D1B0E), Color(0xFF5C3317), Color(0xFF8B5E3C)],
    heroLight: [Color(0xFFFFF8F0), Color(0xFFFFE8D0), Color(0xFFF5D0A0)],
    navGradient: [Color(0xFF8B5E3C), Color(0xFFD4955A)],
  );

  static const DestinationTheme kBeach = DestinationTheme(
    type: DestinationThemeType.beach,
    label: 'Beach',
    emoji: '🌊',
    primary: Color(0xFF00B4D8),
    accent: Color(0xFF90E0EF),
    heroDark:  [Color(0xFF03045E), Color(0xFF0077B6), Color(0xFF00B4D8)],
    heroLight: [Color(0xFFCAF0F8), Color(0xFF90E0EF), Color(0xFF48CAE4)],
    navGradient: [Color(0xFF0077B6), Color(0xFF00B4D8)],
  );

  static const DestinationTheme kMountain = DestinationTheme(
    type: DestinationThemeType.mountain,
    label: 'Mountain',
    emoji: '⛰️',
    primary: Color(0xFF4A7C59),
    accent: Color(0xFF8BC34A),
    heroDark:  [Color(0xFF1A2E22), Color(0xFF2D4A35), Color(0xFF4A7C59)],
    heroLight: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
    navGradient: [Color(0xFF2D4A35), Color(0xFF4A7C59)],
  );

  static const DestinationTheme kForest = DestinationTheme(
    type: DestinationThemeType.forest,
    label: 'Forest',
    emoji: '🌲',
    primary: Color(0xFF2E7D32),
    accent: Color(0xFF66BB6A),
    heroDark:  [Color(0xFF0D1F10), Color(0xFF1B3A1E), Color(0xFF2E7D32)],
    heroLight: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFF81C784)],
    navGradient: [Color(0xFF1B3A1E), Color(0xFF2E7D32)],
  );

  static const DestinationTheme kUrban = DestinationTheme(
    type: DestinationThemeType.urban,
    label: 'Urban',
    emoji: '🏙️',
    primary: Color(0xFF546E7A),
    accent: Color(0xFF78909C),
    heroDark:  [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    heroLight: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
    navGradient: [Color(0xFF16213E), Color(0xFF546E7A)],
  );

  static const List<DestinationTheme> all = [
    kDefault, kSnow, kDesert, kBeach, kMountain, kForest, kUrban,
  ];

  static DestinationTheme fromType(DestinationThemeType t) {
    switch (t) {
      case DestinationThemeType.snow:    return kSnow;
      case DestinationThemeType.desert:  return kDesert;
      case DestinationThemeType.beach:   return kBeach;
      case DestinationThemeType.mountain: return kMountain;
      case DestinationThemeType.forest:  return kForest;
      case DestinationThemeType.urban:   return kUrban;
      case DestinationThemeType.defaultTheme: return kDefault;
    }
  }

  // Provider accessor — requires DestinationThemeProvider in tree
  static DestinationTheme of(BuildContext context) =>
      context.watch<DestinationThemeProvider>().activeTheme;

  static DestinationTheme read(BuildContext context) =>
      context.read<DestinationThemeProvider>().activeTheme;
}

// ─── Destination → Theme Type Mapping ────────────────────────────────────────

DestinationThemeType typeFromDestination(String name, String? category) {
  final n = name.toLowerCase();
  final c = (category ?? '').toLowerCase();

  if (_m(n, ['skardu', 'nathiagali', 'malam jabba', 'kalam', 'snow',
      'winter', 'glacier', 'siachin', 'frozen', 'naltar'])) {
    return DestinationThemeType.snow;
  }
  if (_m(n, ['beach', 'clifton', 'maldives', 'gwadar', 'sea view',
      'ocean', 'coastal', 'island', 'bay', 'cape', 'makran', 'ormara'])) {
    return DestinationThemeType.beach;
  }
  if (_m(n, ['thar', 'desert', 'dubai', 'cholistan', 'sand dune',
      'dune', 'arid', 'rajasthan', 'sinai', 'sahara', 'barren'])) {
    return DestinationThemeType.desert;
  }
  if (_m(n, ['forest', 'jungle', 'amazon', 'deosai', 'mangrove',
      'rainforest', 'woodland', 'timber', 'grove'])) {
    return DestinationThemeType.forest;
  }
  if (_m(n, ['lahore', 'karachi', 'islamabad', 'rawalpindi', 'city',
      'downtown', 'metro', 'faisalabad', 'multan', 'peshawar',
      'hyderabad', 'quetta', 'sialkot', 'gujranwala', 'urban'])) {
    return DestinationThemeType.urban;
  }
  if (_m(n, ['hunza', 'naran', 'murree', 'kaghan', 'swat', 'valley',
      'mountain', 'hills', 'peak', 'summit', 'pass', 'k2', 'trek',
      'fairy meadows', 'attabad', 'khyber', 'margalla', 'karakoram',
      'hindukush', 'himalaya', 'gilgit', 'baltistan', 'chitral',
      'rohtas', 'fort', 'lake', 'nanga parbat', 'babusar'])) {
    return DestinationThemeType.mountain;
  }

  switch (c) {
    case 'nature':    return DestinationThemeType.mountain;
    case 'adventure': return DestinationThemeType.mountain;
    case 'cultural':  return DestinationThemeType.urban;
    case 'food':      return DestinationThemeType.urban;
    case 'history':   return DestinationThemeType.urban;
    default:          return DestinationThemeType.defaultTheme;
  }
}

// Applies weather code override: heavy snow always overrides
DestinationThemeType applyWeatherModifier(DestinationThemeType base, int code) {
  if (code >= 71 && code <= 86) return DestinationThemeType.snow;
  return base;
}

bool _m(String text, List<String> kw) => kw.any((k) => text.contains(k));

// ─── Provider ─────────────────────────────────────────────────────────────────

const _kPrefKey    = 'destination_theme_pref';
const _kManualKey  = 'destination_theme_manual';

class DestinationThemeProvider extends ChangeNotifier {
  DestinationThemeType _type = DestinationThemeType.defaultTheme;
  bool _isManual = false;

  DestinationThemeType get activeType => _type;
  bool get isManual => _isManual;
  bool get isNonDefault => _type != DestinationThemeType.defaultTheme;
  DestinationTheme get activeTheme => DestinationTheme.fromType(_type);

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isManual = prefs.getBool(_kManualKey) ?? false;
      final s = prefs.getString(_kPrefKey);
      if (s != null) _type = _fromStr(s);
      notifyListeners();
    } catch (_) {}
  }

  // ── Manual control (user-selected in Settings) ───────────────────────────────

  void setManualTheme(DestinationThemeType type) {
    _isManual = (type != DestinationThemeType.defaultTheme);
    _type = type;
    notifyListeners();
    _persist();
    if (_isManual) _syncBackend(type);
  }

  void resetToAuto() {
    _isManual = false;
    _type = DestinationThemeType.defaultTheme;
    notifyListeners();
    _persist();
  }

  // ── Auto-detection (called after login) ──────────────────────────────────────

  Future<void> checkActiveBooking({int? weatherCode}) async {
    if (_isManual) return;
    try {
      final r = await ApiService.getRequest('/bookings?status=confirmed&limit=1');
      final bookings = (r['bookings'] as List?) ?? [];
      if (bookings.isEmpty) {
        final r2 = await ApiService.getRequest('/bookings?status=upcoming&limit=1');
        final upcoming = (r2['bookings'] as List?) ?? [];
        if (upcoming.isEmpty) { _setAuto(DestinationThemeType.defaultTheme); return; }
        _applyBooking(upcoming.first as Map<String, dynamic>, weatherCode);
        return;
      }
      _applyBooking(bookings.first as Map<String, dynamic>, weatherCode);
    } catch (_) {}
  }

  void _applyBooking(Map<String, dynamic> b, int? weatherCode) {
    final name = (b['destination_name'] ?? b['name'] ?? '') as String;
    final cat  = (b['category'] ?? '') as String;
    var t = typeFromDestination(name, cat);
    if (weatherCode != null) t = applyWeatherModifier(t, weatherCode);
    _setAuto(t);
  }

  // Called from weather widget when live weather is available
  void applyWeatherCode(int code) {
    if (_isManual) return;
    final modified = applyWeatherModifier(_type, code);
    if (modified == _type) return;
    _type = modified;
    notifyListeners();
    _persist();
  }

  void _setAuto(DestinationThemeType t) {
    if (_isManual || t == _type) return;
    _type = t;
    notifyListeners();
    _persist();
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, _toStr(_type));
      await prefs.setBool(_kManualKey, _isManual);
    } catch (_) {}
  }

  void _syncBackend(DestinationThemeType type) {
    ApiService.putRequest('/users/theme-preference', {
      'theme_preference': _toStr(type),
    }).ignore();
  }

  // ── Serialization ─────────────────────────────────────────────────────────────

  static String _toStr(DestinationThemeType t) {
    switch (t) {
      case DestinationThemeType.snow:     return 'snow';
      case DestinationThemeType.desert:   return 'desert';
      case DestinationThemeType.beach:    return 'beach';
      case DestinationThemeType.mountain: return 'mountain';
      case DestinationThemeType.forest:   return 'forest';
      case DestinationThemeType.urban:    return 'urban';
      case DestinationThemeType.defaultTheme: return 'default';
    }
  }

  static DestinationThemeType _fromStr(String s) {
    switch (s) {
      case 'snow':     return DestinationThemeType.snow;
      case 'desert':   return DestinationThemeType.desert;
      case 'beach':    return DestinationThemeType.beach;
      case 'mountain': return DestinationThemeType.mountain;
      case 'forest':   return DestinationThemeType.forest;
      case 'urban':    return DestinationThemeType.urban;
      default:         return DestinationThemeType.defaultTheme;
    }
  }
}
