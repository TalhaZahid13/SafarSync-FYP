import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';
import 'app_theme.dart';

// ─── Destination Theme System ─────────────────────────────────────────────────
// The whole app's accent palette follows the signed-in user's booked trip:
//   1. a manual choice saved to the user's account (Settings → Journey Theme)
//   2. otherwise the trip in progress (status Active)
//   3. otherwise the next upcoming Confirmed trip
//   4. otherwise the default SafarSync theme.
// Pending / Awaiting-payment / Cancelled / Refunded bookings, hotel and
// restaurant reservations, and trips that have already ended never count.
// All selection logic lives in [DestinationThemeProvider]; pages only read it.

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
  final List<Color> heroDark; // dark-mode hero/header
  final List<Color> heroLight; // light-mode hero/header
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

  /// App-wide accent for this theme. Destination palettes are darkened just
  /// enough for white button text / accent text on white to reach WCAG AA
  /// (4.5:1). The default theme keeps the exact SafarSync brand color.
  Color get uiAccent => type == DestinationThemeType.defaultTheme
      ? AppTheme.defaultAccent
      : _withContrastOnWhite(primary, 4.5);

  /// Soft tint of the accent (chips, soft fills, light borders).
  Color get uiTint => type == DestinationThemeType.defaultTheme
      ? AppTheme.defaultAccentTint
      : Color.lerp(Colors.white, uiAccent, 0.16)!;

  /// Light-mode page background (null = plain white for the default theme).
  Color? get lightBackground => type == DestinationThemeType.defaultTheme
      ? null
      : Color.lerp(Colors.white, heroLight.first, 0.6);

  // ── Predefined themes ─────────────────────────────────────────────────────

  static const DestinationTheme kDefault = DestinationTheme(
    type: DestinationThemeType.defaultTheme,
    label: 'Default',
    emoji: '✈️',
    primary: Color(0xFF2CAFBC),
    accent: Color(0xFFFDB913),
    heroDark: [Color(0xFF0D1B2A), Color(0xFF1B3A4C), Color(0xFF1B5A6E)],
    heroLight: [Color(0xFFF5F6FA), Color(0xFFEFF9FA), Color(0xFFE3F5F7)],
    navGradient: [Color(0xFF9A9E9D), Color(0xFF2CAFBC)],
  );

  static const DestinationTheme kSnow = DestinationTheme(
    type: DestinationThemeType.snow,
    label: 'Snow',
    emoji: '❄️',
    primary: Color(0xFF7EC8E3),
    accent: Color(0xFFB8E0FF),
    heroDark: [Color(0xFF1A2A3A), Color(0xFF2A3D52), Color(0xFF4A7A9B)],
    heroLight: [Color(0xFFF0F8FF), Color(0xFFDCEEFA), Color(0xFFC8DEFF)],
    navGradient: [Color(0xFF4A7A9B), Color(0xFF7EC8E3)],
  );

  static const DestinationTheme kDesert = DestinationTheme(
    type: DestinationThemeType.desert,
    label: 'Desert',
    emoji: '🏜️',
    primary: Color(0xFFD4955A),
    accent: Color(0xFFF0C070),
    heroDark: [Color(0xFF2D1B0E), Color(0xFF5C3317), Color(0xFF8B5E3C)],
    heroLight: [Color(0xFFFFF8F0), Color(0xFFFFE8D0), Color(0xFFF5D0A0)],
    navGradient: [Color(0xFF8B5E3C), Color(0xFFD4955A)],
  );

  static const DestinationTheme kBeach = DestinationTheme(
    type: DestinationThemeType.beach,
    label: 'Beach',
    emoji: '🌊',
    primary: Color(0xFF00B4D8),
    accent: Color(0xFF90E0EF),
    heroDark: [Color(0xFF03045E), Color(0xFF0077B6), Color(0xFF00B4D8)],
    heroLight: [Color(0xFFCAF0F8), Color(0xFF90E0EF), Color(0xFF48CAE4)],
    navGradient: [Color(0xFF0077B6), Color(0xFF00B4D8)],
  );

  static const DestinationTheme kMountain = DestinationTheme(
    type: DestinationThemeType.mountain,
    label: 'Mountain',
    emoji: '⛰️',
    primary: Color(0xFF4A7C59),
    accent: Color(0xFF8BC34A),
    heroDark: [Color(0xFF1A2E22), Color(0xFF2D4A35), Color(0xFF4A7C59)],
    heroLight: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
    navGradient: [Color(0xFF2D4A35), Color(0xFF4A7C59)],
  );

  static const DestinationTheme kForest = DestinationTheme(
    type: DestinationThemeType.forest,
    label: 'Forest',
    emoji: '🌲',
    primary: Color(0xFF2E7D32),
    accent: Color(0xFF66BB6A),
    heroDark: [Color(0xFF0D1F10), Color(0xFF1B3A1E), Color(0xFF2E7D32)],
    heroLight: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFF81C784)],
    navGradient: [Color(0xFF1B3A1E), Color(0xFF2E7D32)],
  );

  static const DestinationTheme kUrban = DestinationTheme(
    type: DestinationThemeType.urban,
    label: 'Urban',
    emoji: '🏙️',
    primary: Color(0xFF546E7A),
    accent: Color(0xFF78909C),
    heroDark: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    heroLight: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
    navGradient: [Color(0xFF16213E), Color(0xFF546E7A)],
  );

  static const List<DestinationTheme> all = [
    kDefault,
    kSnow,
    kDesert,
    kBeach,
    kMountain,
    kForest,
    kUrban,
  ];

  static DestinationTheme fromType(DestinationThemeType t) {
    switch (t) {
      case DestinationThemeType.snow:
        return kSnow;
      case DestinationThemeType.desert:
        return kDesert;
      case DestinationThemeType.beach:
        return kBeach;
      case DestinationThemeType.mountain:
        return kMountain;
      case DestinationThemeType.forest:
        return kForest;
      case DestinationThemeType.urban:
        return kUrban;
      case DestinationThemeType.defaultTheme:
        return kDefault;
    }
  }

  // Provider accessor — requires DestinationThemeProvider in tree
  static DestinationTheme of(BuildContext context) =>
      context.watch<DestinationThemeProvider>().activeTheme;

  static DestinationTheme read(BuildContext context) =>
      context.read<DestinationThemeProvider>().activeTheme;
}

double _contrastOnWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

Color _withContrastOnWhite(Color c, double target) {
  var hsl = HSLColor.fromColor(c);
  var out = c;
  while (_contrastOnWhite(out) < target && hsl.lightness > 0.05) {
    hsl = hsl.withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0));
    out = hsl.toColor();
  }
  return out;
}

// ─── Destination → Theme Type Mapping ────────────────────────────────────────
// Matches the destination name + city first (most specific), then falls back
// to the catalogue category (nature / adventure / history / food, and the
// tour-package categories Nature / Adventure / Cultural).

DestinationThemeType typeFromDestination(
  String name,
  String? category, {
  String? city,
}) {
  final n = '${name.toLowerCase()} ${(city ?? '').toLowerCase()}';
  final c = (category ?? '').toLowerCase().trim();

  if (_m(n, [
    'skardu',
    'k2',
    'baltoro',
    'concordia',
    'nathiagali',
    'nathia gali',
    'malam jabba',
    'kalam',
    'snow',
    'winter',
    'glacier',
    'siachen',
    'siachin',
    'frozen',
    'naltar',
  ])) {
    return DestinationThemeType.snow;
  }
  if (_m(n, [
    'beach',
    'clifton',
    'gwadar',
    'sea view',
    'ocean',
    'coastal',
    'island',
    'bay',
    'cape',
    'makran',
    'ormara',
  ])) {
    return DestinationThemeType.beach;
  }
  if (_m(n, [
    'thar',
    'desert',
    'cholistan',
    'sand dune',
    'dune',
    'arid',
    'mohenjo',
    'larkana',
    'derawar',
  ])) {
    return DestinationThemeType.desert;
  }
  if (_m(n, [
    'forest',
    'jungle',
    'mangrove',
    'rainforest',
    'woodland',
    'grove',
    'ayubia',
  ])) {
    return DestinationThemeType.forest;
  }
  if (_m(n, [
    'food street',
    'burns road',
    'lahore',
    'karachi',
    'islamabad',
    'rawalpindi',
    'downtown',
    'metro',
    'faisalabad',
    'multan',
    'peshawar',
    'hyderabad',
    'quetta',
    'sialkot',
    'urban',
  ])) {
    return DestinationThemeType.urban;
  }
  if (_m(n, [
    'hunza',
    'naran',
    'murree',
    'kaghan',
    'swat',
    'valley',
    'mountain',
    'hills',
    'peak',
    'summit',
    'trek',
    'fairy meadows',
    'deosai',
    'attabad',
    'margalla',
    'karakoram',
    'hindukush',
    'himalaya',
    'gilgit',
    'chitral',
    'nanga parbat',
    'babusar',
  ])) {
    return DestinationThemeType.mountain;
  }

  switch (c) {
    case 'nature':
    case 'adventure':
      return DestinationThemeType.mountain;
    // Heritage sites (Rohtas Fort, Mohenjo-daro) → warm sandstone palette.
    case 'history':
    case 'historical':
    case 'heritage':
      return DestinationThemeType.desert;
    case 'cultural':
    case 'food':
      return DestinationThemeType.urban;
    default:
      return DestinationThemeType.defaultTheme;
  }
}

bool _m(String text, List<String> kw) => kw.any((k) => text.contains(k));

// ─── Booking selection (pure, testable) ──────────────────────────────────────

/// Picks the booking that should drive the theme, or null.
///
/// Priority: a trip in progress (status Active) → the Confirmed trip that is
/// ongoing or starts soonest. Ignores hotel/restaurant reservations, bookings
/// without a destination, other statuses, and trips that have already ended.
Map<String, dynamic>? selectThemeBooking(
  List<Map<String, dynamic>> bookings, {
  DateTime? now,
}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  DateTime? start(Map<String, dynamic> b) =>
      DateTime.tryParse('${b['travel_date'] ?? b['booking_date'] ?? ''}');
  int days(Map<String, dynamic> b) =>
      (int.tryParse('${b['estimated_duration_days'] ?? ''}') ?? 1).clamp(
        1,
        365,
      );

  bool eligible(Map<String, dynamic> b) {
    final type = '${b['booking_type'] ?? ''}'.toLowerCase();
    if (type == 'hotel' || type == 'restaurant') return false;
    if ('${b['destination_name'] ?? ''}'.trim().isEmpty) return false;
    final status = '${b['status'] ?? ''}'.toLowerCase();
    if (status == 'active') return true;
    if (status != 'confirmed') return false;
    final s = start(b);
    if (s == null) return true; // undated confirmed trip still counts
    final lastDay = DateUtils.dateOnly(s).add(Duration(days: days(b) - 1));
    return !lastDay.isBefore(today);
  }

  final candidates = bookings.where(eligible).toList();
  if (candidates.isEmpty) return null;
  final active = candidates.where(
    (b) => '${b['status']}'.toLowerCase() == 'active',
  );
  if (active.isNotEmpty) return active.first;
  candidates.sort((a, b) {
    final sa = start(a), sb = start(b);
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return sa.compareTo(sb);
  });
  return candidates.first;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

// Legacy device-wide keys (pre per-user storage) — removed on first run.
const _kLegacyPrefKey = 'destination_theme_pref';
const _kLegacyManualKey = 'destination_theme_manual';
String _prefKey(String uid) => 'destination_theme_pref_$uid';
String _manualKey(String uid) => 'destination_theme_manual_$uid';

class DestinationThemeProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  DestinationThemeType _type = DestinationThemeType.defaultTheme;
  bool _isManual = false;
  String? _uid;
  String? _sourceName; // destination of the booking driving the theme
  DateTime? _lastRefresh;
  int _generation = 0; // bumps on every account switch; drops stale replies

  DestinationThemeType get activeType => _type;
  bool get isManual => _isManual;
  bool get isNonDefault => _type != DestinationThemeType.defaultTheme;
  DestinationTheme get activeTheme => DestinationTheme.fromType(_type);

  /// Destination name of the booking that selected the current theme
  /// (null for manual / default).
  String? get sourceName => _sourceName;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _applyAccent();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLegacyPrefKey);
      await prefs.remove(_kLegacyManualKey);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bookings can change elsewhere (admin, web, payment webhook): re-check
    // when the app comes back to the foreground, at most once a minute.
    if (state == AppLifecycleState.resumed && _uid != null) {
      final last = _lastRefresh;
      if (last == null || DateTime.now().difference(last).inSeconds > 60) {
        refresh().ignore();
      }
    }
  }

  // ── Account binding (called by UserProfileProvider) ─────────────────────────

  /// Switches the theme state to [uid]'s account; null = signed out.
  Future<void> attachUser(String? uid) async {
    if (uid == _uid) return;
    _generation++;
    _uid = uid;
    _isManual = false;
    _sourceName = null;
    _lastRefresh = null;
    _setType(DestinationThemeType.defaultTheme, persist: false);
    if (uid == null) return;

    // Restore this user's last theme instantly (no flash on cold start)…
    final gen = _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (gen != _generation) return;
      _isManual = prefs.getBool(_manualKey(uid)) ?? false;
      final s = prefs.getString(_prefKey(uid));
      if (s != null) _setType(_fromStr(s), persist: false);
    } catch (_) {}
    // …then confirm against the server.
    await refresh();
  }

  // ── Manual control (user-selected in Settings) ───────────────────────────────

  void setManualTheme(DestinationThemeType type) {
    if (type == DestinationThemeType.defaultTheme) {
      resetToAuto();
      return;
    }
    _isManual = true;
    _sourceName = null;
    _setType(type);
    _syncBackend(type);
  }

  void resetToAuto() {
    _isManual = false;
    _syncBackend(DestinationThemeType.defaultTheme);
    _persist();
    notifyListeners();
    refresh().ignore();
  }

  // ── Server refresh ───────────────────────────────────────────────────────────

  /// Re-reads the user's saved theme choice and bookings and re-selects.
  /// Call after creating, paying for, or cancelling a booking.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    final gen = _generation;
    _lastRefresh = DateTime.now();
    try {
      final results = await Future.wait([
        ApiService.getRequest('/auth/me'),
        ApiService.getRequest('/bookings?status=active&limit=20'),
        ApiService.getRequest('/bookings?status=confirmed&limit=50'),
      ]);
      if (gen != _generation) return; // account switched meanwhile

      final me = results[0];
      if (me['success'] == true) {
        final pref = '${(me['user'] as Map?)?['theme_preference'] ?? ''}';
        final manual = _fromStr(pref);
        _isManual = manual != DestinationThemeType.defaultTheme;
        if (_isManual) {
          _sourceName = null;
          _setType(manual);
          return;
        }
      }

      // A failed bookings call must not wipe a correct theme.
      if (results[1]['success'] != true || results[2]['success'] != true) {
        return;
      }
      final all = <Map<String, dynamic>>[
        for (final r in [results[1], results[2]])
          for (final b in (r['bookings'] as List? ?? const []))
            if (b is Map) Map<String, dynamic>.from(b),
      ];
      final chosen = selectThemeBooking(all);
      if (chosen == null) {
        _sourceName = null;
        _setType(DestinationThemeType.defaultTheme);
        return;
      }
      _sourceName = '${chosen['destination_name']}';
      _setType(
        typeFromDestination(
          _sourceName!,
          chosen['category'] as String?,
          city: chosen['city'] as String?,
        ),
      );
    } catch (e) {
      debugPrint('[DestinationTheme] refresh failed (keeping theme): $e');
    }
  }

  /// Back-compat entry point used by older call sites.
  Future<void> checkActiveBooking() => refresh();

  // ── Internals ───────────────────────────────────────────────────────────────

  void _setType(DestinationThemeType t, {bool persist = true}) {
    _type = t;
    _applyAccent();
    if (persist) _persist();
    // Always notify: manual/source flags may have changed even if the
    // palette did not.
    notifyListeners();
  }

  void _applyAccent() {
    final t = activeTheme;
    AppTheme.applyAccent(
      accent: t.uiAccent,
      tint: t.uiTint,
      lightBackground: t.lightBackground,
    );
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(uid), _toStr(_type));
      await prefs.setBool(_manualKey(uid), _isManual);
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
      case DestinationThemeType.snow:
        return 'snow';
      case DestinationThemeType.desert:
        return 'desert';
      case DestinationThemeType.beach:
        return 'beach';
      case DestinationThemeType.mountain:
        return 'mountain';
      case DestinationThemeType.forest:
        return 'forest';
      case DestinationThemeType.urban:
        return 'urban';
      case DestinationThemeType.defaultTheme:
        return 'default';
    }
  }

  static DestinationThemeType _fromStr(String s) {
    switch (s) {
      case 'snow':
        return DestinationThemeType.snow;
      case 'desert':
        return DestinationThemeType.desert;
      case 'beach':
        return DestinationThemeType.beach;
      case 'mountain':
        return DestinationThemeType.mountain;
      case 'forest':
        return DestinationThemeType.forest;
      case 'urban':
        return DestinationThemeType.urban;
      default:
        return DestinationThemeType.defaultTheme;
    }
  }
}
