import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'src/auth/login.dart';
import 'src/auth/signup.dart';
import 'src/components/navigation/top_navigation.dart';
import 'src/components/navigation/bottom_navigation.dart';
import 'src/components/emergency/floating_emergency_button.dart';
import 'src/components/ai/ai_assistant.dart';
import 'src/components/home/search_bar.dart';
import 'src/pages/home_page.dart';
import 'src/pages/explore_page.dart';
import 'src/pages/routes_page.dart';
import 'src/pages/wishlist_page.dart';
import 'src/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SafarSyncApp());
}

class SafarSyncApp extends StatelessWidget {
  const SafarSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafarSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF2C2C2C),
      ),
      home: const AuthGate(), // 🔐 login vs app decision here
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const App();
        }

        return const LoginPage();
      },
    );
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

