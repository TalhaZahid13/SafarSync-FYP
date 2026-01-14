import 'package:flutter/material.dart';

// Import your components
import 'src/components/navigation/top_navigation.dart';
import 'src/components/navigation/bottom_navigation.dart';
import 'src/components/emergency/floating_emergency_button.dart';
import 'src/components/ai/ai_assistant.dart';
import 'src/pages/home_page.dart';
import 'src/pages/explore_page.dart';
import 'src/pages/routes_page.dart';
import 'src/pages/wishlist_page.dart';
import 'src/pages/profile_page.dart';

void main() {
  runApp(const SafarSyncApp());
}

class SafarSyncApp extends StatelessWidget {
  const SafarSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafarSync',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const App(),
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

  Widget renderPage() {
    switch (activeTab) {
      case 'home':
        return const HomePage();
      case 'explore':
        return const ExplorePage();
      case 'routes':
        return RoutesPage();
      case 'wishlist':
        return WishlistPage();
      case 'profile':
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating Emergency Button
      floatingActionButton: FloatingEmergencyButton(),

      // Body
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            const TopNavigation(),

            // Page content
            Expanded(child: renderPage()),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: (String tab) {
          setState(() {
            activeTab = tab;
          });
        },
      ),

      // AI Assistant overlay
      // Using Stack to show AI button and AI panel
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
