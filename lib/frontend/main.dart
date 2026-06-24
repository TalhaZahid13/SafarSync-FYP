import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/utils/app_config.dart';
import 'src/auth/login.dart';
import 'src/auth/signup.dart';
import 'src/components/navigation/top_navigation.dart';
import 'src/components/navigation/bottom_navigation.dart';
import 'src/components/emergency/floating_emergency_button.dart';
import 'src/pages/home_page.dart';
import 'src/pages/explore_page.dart';
import 'src/pages/routes_page.dart';
import 'src/pages/profile_page.dart';
import 'src/pages/smart_dashboard_page.dart';
import 'src/utils/local_database_service.dart';
import 'src/utils/theme_controller.dart';
import 'src/ui/app_theme.dart';
import 'src/utils/notification_service.dart';
import 'src/pages/emergency_sos_screen.dart';
import 'src/utils/session_manager.dart';
import 'src/utils/api_service.dart';
import 'src/utils/auth_storage.dart';
import 'src/ui/destination_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[SafarSync] ▶ App starting');

  // Load user-saved server URL before anything else touches ApiService.baseUrl
  try {
    await ApiService.initBaseUrl().timeout(const Duration(seconds: 3));
    debugPrint('[SafarSync] ✓ Server URL: ${ApiService.baseUrl}');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Server URL init failed (using default): $e');
  }

  try {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings().timeout(const Duration(seconds: 5));
    debugPrint('[SafarSync] ✓ Stripe ready');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Stripe init skipped: $e');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    debugPrint('[SafarSync] ✓ Firebase ready');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Firebase init error: $e');
  }

  try {
    await LocalDatabaseService.ensureInitialized()
        .timeout(const Duration(seconds: 5));
    debugPrint('[SafarSync] ✓ Local DB ready');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Local DB init failed (non-fatal): $e');
  }

  final themeController = ThemeController();
  try {
    await themeController.loadThemeMode().timeout(const Duration(seconds: 2));
    debugPrint('[SafarSync] ✓ Theme loaded');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Theme load failed (non-fatal): $e');
  }

  final destinationThemeProvider = DestinationThemeProvider();
  try {
    await destinationThemeProvider.init().timeout(const Duration(seconds: 2));
    debugPrint('[SafarSync] ✓ Destination theme loaded');
  } catch (e) {
    debugPrint('[SafarSync] ✗ Destination theme init (non-fatal): $e');
  }

  debugPrint('[SafarSync] ▶ Calling runApp');
  runApp(SafarSyncApp(
    themeController: themeController,
    destinationThemeProvider: destinationThemeProvider,
  ));

  NotificationService.instance.initialize().ignore();
  debugPrint('[SafarSync] ✓ Notification init started in background');
}

class SafarSyncApp extends StatelessWidget {
  final ThemeController themeController;
  final DestinationThemeProvider destinationThemeProvider;

  const SafarSyncApp({
    super.key,
    required this.themeController,
    required this.destinationThemeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: destinationThemeProvider),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'SafarSync',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: controller.themeMode,
            home: const AuthGate(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignupPage(),
              '/home': (context) => const App(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  bool _isLoggedIn = false;
  String? _sessionMessage;
  String _statusText = 'Starting up…';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    debugPrint('[AuthGate] Auth check started');
    try {
      await Future.wait([
        _doAuthCheck().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[AuthGate] ⚠ TIMEOUT — falling back to local Firebase state');
            _resolveWithFirebaseState();
          },
        ),
        Future.delayed(const Duration(milliseconds: 800)),
      ]);
    } catch (e) {
      debugPrint('[AuthGate] ✗ Unexpected error: $e');
      _resolveWithFirebaseState();
    }
  }
  void _resolveWithFirebaseState() {
    if (!mounted || !_isChecking) return;
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[AuthGate] Fallback: user=${user?.uid ?? 'null'}');
    setState(() {
      _isLoggedIn = user != null;
      _isChecking = false;
    });
  }

  Future<void> _doAuthCheck() async {
    _setStatus('Checking session…');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[AuthGate] Firebase user: ${user?.uid ?? 'none'}');

    bool expired = false;
    try {
      expired = await SessionManager.clearIfSessionExpired(
        clearRememberMe: true,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[AuthGate] Session expiry check error (non-fatal): $e');
    }

    if (!mounted) return;

    if (expired) {
      debugPrint('[AuthGate] Session expired — redirecting to login');
      if (user != null) {
        try {
          await FirebaseAuth.instance.signOut()
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
        await ApiService.removeToken();
      }
      setState(() {
        _isLoggedIn = false;
        _sessionMessage =
            'Your session has expired due to 7 days of inactivity. Please sign in again.';
        _isChecking = false;
      });
      return;
    }

    if (user != null) {
      _setStatus('Restoring session…');
      bool rememberMe = false;
      try {
        rememberMe = await AuthStorage.isRememberMeEnabled()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[AuthGate] RememberMe check error (defaulting false): $e');
      }

      if (!mounted) return;

      if (!rememberMe) {
        debugPrint('[AuthGate] RememberMe=false — signing out');
        try {
          await FirebaseAuth.instance.signOut()
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
        await ApiService.removeToken();
        if (!mounted) return;
        setState(() {
          _isLoggedIn = false;
          _isChecking = false;
        });
        return;
      }

      SessionManager.recordActivity().ignore();
      _setStatus('Preparing your experience…');
      ApiService.refreshTokenIfNeeded(user).ignore();
      debugPrint('[AuthGate] ✓ Token refresh started in background (non-blocking)');
    }

    if (!mounted) return;

    debugPrint('[AuthGate] ✓ Auth check done. loggedIn=${user != null}');
    setState(() {
      _isLoggedIn = user != null;
      _isChecking = false;
    });
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusText = msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _SplashScreen(statusText: _statusText);
    }

    if (_sessionMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sessionMessage!)),
        );
        setState(() => _sessionMessage = null);
      });
    }

    return _isLoggedIn ? const App() : const LoginPage();
  }
}
class _SplashScreen extends StatefulWidget {
  final String statusText;
  const _SplashScreen({required this.statusText});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B5A6E);
    const accent = Color(0xFF2CAFBC);

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Transform.scale(
                scale: _scale.value,
                child: Opacity(opacity: _fade.value, child: child),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'SafarSync',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your Smart Travel Companion',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),

            const Spacer(flex: 3),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                strokeWidth: 2.5,
              ),
            ),

            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                widget.statusText,
                key: ValueKey(widget.statusText),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 52),
          ],
        ),
      ),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  int _activeIndex = 0;

  static const _tabIds = ['home', 'explore', 'trips', 'routes', 'profile'];
  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _builtPages = {};
  String get activeTab => _tabIds[_activeIndex];
  static const _sosTileChannel = MethodChannel(
    'com.example.safarsync_mobileapp/sos_tile',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.startListening();
    _sosTileChannel.setMethodCallHandler(_onSosTileMethod);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingSos();
      context.read<DestinationThemeProvider>().checkActiveBooking().ignore();
    });
    SessionManager.recordActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionManager.recordActivity();
    }
  }

  Future<dynamic> _onSosTileMethod(MethodCall call) async {
    if (call.method == 'triggerSOS' && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EmergencySOSScreen(autoStart: true),
        ),
      );
    }
  }

  Future<void> _checkPendingSos() async {
    try {
      final pending =
          await _sosTileChannel.invokeMethod<bool>('hasPendingSOS') ?? false;
      if (pending && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EmergencySOSScreen(autoStart: true),
          ),
        );
      }
    } catch (_) {

    }
  }

  @override
  void dispose() {
    NotificationService.instance.stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _goToRoutes() => _onTabChange('routes');

  void _onTabChange(String tab) {
    final idx = _tabIds.indexOf(tab);
    if (idx != -1 && idx != _activeIndex) {
      setState(() {
        _visitedTabs.add(idx);
        _activeIndex = idx;
      });
      SessionManager.recordActivity();
    }
  }

  Widget _getPage(int index) {
    return _builtPages.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return HomePage(onPlanRoute: _goToRoutes, onTabChange: _onTabChange);
        case 1:
          return const ExplorePage();
        case 2:
          return const SmartDashboardPage();
        case 3:
          return RoutesPage();
        case 4:
          return const ProfilePage();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const FloatingEmergencyButton(),
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigation(),
            Expanded(
              child: IndexedStack(
                index: _activeIndex,
                children: List.generate(
                  _tabIds.length,
                  (i) => _visitedTabs.contains(i)
                      ? _getPage(i)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: _onTabChange,
      ),
      extendBody: true,
    );
  }
}
