import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/auth/login.dart';
import 'src/auth/signup.dart';
import 'src/components/navigation/top_navigation.dart';
import 'src/components/navigation/bottom_navigation.dart';
import 'src/components/emergency/floating_emergency_button.dart';
import 'src/components/ai/ai_assistant.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Run DB init and notification init in parallel — shaves ~200ms off startup
    await Future.wait([
      LocalDatabaseService.ensureInitialized(),
      NotificationService.instance.initialize(),
    ]);
  } catch (e) {
    debugPrint('Startup error: $e');
  }
  final themeController = ThemeController();
  await themeController.loadThemeMode();

  // Run the app
  runApp(SafarSyncApp(themeController: themeController));
}

class SafarSyncApp extends StatelessWidget {
  final ThemeController themeController;

  const SafarSyncApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeController,
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
            // No custom builder
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

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    final expired = await SessionManager.clearIfSessionExpired(
      clearRememberMe: true,
    );

    if (!mounted) return;

    if (expired) {
      // Session timed out — sign out of Firebase too and clear JWT
      if (user != null) {
        await FirebaseAuth.instance.signOut();
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
      // Feature 2: if Remember Me is OFF, clear the Firebase session on every
      // cold start so the user must re-enter credentials.
      final rememberMe = await AuthStorage.isRememberMeEnabled();
      if (!rememberMe) {
        await FirebaseAuth.instance.signOut();
        await ApiService.removeToken();
        if (!mounted) return;
        setState(() { _isLoggedIn = false; _isChecking = false; });
        return;
      }

      await SessionManager.recordActivity();
      // Silently refresh the backend JWT if it is missing or expired.
      await ApiService.refreshTokenIfNeeded(user);
    }

    if (!mounted) return;

    setState(() {
      _isLoggedIn = user != null;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sessionMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_sessionMessage!)));
        setState(() => _sessionMessage = null);
      });
    }

    return _isLoggedIn ? const App() : const LoginPage();
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  int _activeIndex = 0;
  bool isAIOpen = false;

  // Tab ordering must match _pages and navItems in bottom_navigation.dart
  static const _tabIds = ['home', 'explore', 'trips', 'routes', 'profile'];

  String get activeTab => _tabIds[_activeIndex];

  // Channel matches the one declared in MainActivity.kt
  static const _sosTileChannel = MethodChannel(
    'com.example.safarsync_mobileapp/sos_tile',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start socket listener for real-time emergency + general notifications
    NotificationService.instance.startListening();
    // Handle SOS tile intent (warm-start: app already running)
    _sosTileChannel.setMethodCallHandler(_onSosTileMethod);
    // Handle SOS tile intent (cold-start: check after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingSos());
    SessionManager.recordActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionManager.recordActivity();
    }
  }

  /// Called by native when onNewIntent fires with the SOS tile action
  /// (app was already running in the background).
  Future<dynamic> _onSosTileMethod(MethodCall call) async {
    if (call.method == 'triggerSOS' && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EmergencySOSScreen(autoStart: true),
        ),
      );
    }
  }

  /// Checks whether the app was cold-started by the SOS tile.
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
      // Platform channel not available (e.g., running on iOS or in tests)
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
      setState(() => _activeIndex = idx);
      SessionManager.recordActivity();
    }
  }

  // Pages are built once and kept alive via IndexedStack.
  // This eliminates the full page rebuild that occurred on every tab switch.
  late final List<Widget> _pages = [
    HomePage(onPlanRoute: _goToRoutes, onTabChange: _onTabChange),
    const ExplorePage(),
    const SmartDashboardPage(),
    RoutesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const FloatingEmergencyButton(),
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigation(),
            Expanded(
              // IndexedStack keeps all pages alive — no rebuild on tab switch
              child: IndexedStack(index: _activeIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: _onTabChange,
      ),
      extendBody: true,
      bottomSheet: Stack(
        children: [
          if (!isAIOpen)
            Positioned(
              bottom: 80,
              right: 16,
              child: AIAssistantButton(
                onClick: () => setState(() => isAIOpen = true),
              ),
            ),
          AIAssistant(
            isOpen: isAIOpen,
            onClose: () => setState(() => isAIOpen = false),
          ),
        ],
      ),
    );
  }
}
