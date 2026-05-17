import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'src/pages/wishlist_page.dart';
import 'src/pages/profile_page.dart';
import 'src/utils/local_database_service.dart';
import 'src/utils/theme_controller.dart';
import 'src/ui/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // For checking if it's running on web
// DevicePreview removed

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Function to initialize notifications
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app icon

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await LocalDatabaseService.ensureInitialized();
    // Initialize local notifications after necessary services are ready
    await _initializeNotifications();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;

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

    return _isLoggedIn ? const App() : const LoginPage();
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String activeTab = 'home';
  bool isAIOpen = false;

  void _goToRoutes() {
    setState(() {
      activeTab = 'routes';
    });
  }

  Widget renderPage() {
    switch (activeTab) {
      case 'home':
        return HomePage(
          onPlanRoute: _goToRoutes,
          onTabChange: (tab) {
            setState(() {
              activeTab = tab;
            });
          },
        );
      case 'explore':
        return const ExplorePage();
      case 'routes':
        return RoutesPage();
      case 'wishlist':
        return WishlistPage();
      case 'profile':
        return const ProfilePage();
      default:
        return HomePage(
          onPlanRoute: _goToRoutes,
          onTabChange: (tab) {
            setState(() {
              activeTab = tab;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingEmergencyButton(),
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigation(),
            Expanded(child: renderPage()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: (tab) {
          setState(() {
            activeTab = tab;
          });
        },
      ),
      extendBody: true,
      bottomSheet: Stack(
        children: [
          if (!isAIOpen)
            Positioned(
              bottom: 80,
              right: 16,
              child: AIAssistantButton(
                onClick: () {
                  setState(() {
                    isAIOpen = true;
                  });
                },
              ),
            ),
          AIAssistant(
            isOpen: isAIOpen,
            onClose: () {
              setState(() {
                isAIOpen = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
