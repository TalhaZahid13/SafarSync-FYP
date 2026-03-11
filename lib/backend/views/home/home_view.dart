// views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/dialog_helper.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/theme_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/views/home/notification/notifications_view.dart';
import 'package:safarsync_mobileapp/backend/views/home/profile/profile_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _fabAnimationController;
  late AnimationController _borderRadiusAnimationController;
  late AnimationController _themeToggleController;
  late Animation<double> fabAnimation;
  late Animation<double> borderRadiusAnimation;
  late Animation<double> themeToggleAnimation;
  late CurvedAnimation fabCurve;
  late CurvedAnimation borderRadiusCurve;
  late AnimationController _hideBottomBarAnimationController;

  // Navigation items
  final List<IconData> _iconList = [
    Icons.work_outline,
    Icons.chat_bubble_outline,
    Icons.notifications_none,
    Icons.person_outline,
  ];

  final List<IconData> _activeIconList = [
    Icons.work,
    Icons.chat_bubble,
    Icons.notifications,
    Icons.person,
  ];

  final List<String> _labelList = ['Gigs', 'Chats', 'Notifications', 'Profile'];

  final List<Widget> _screens = const [NotificationsView(), ProfileView()];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _borderRadiusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _themeToggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    fabCurve = CurvedAnimation(
      parent: _fabAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
    borderRadiusCurve = CurvedAnimation(
      parent: _borderRadiusAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    fabAnimation = Tween<double>(begin: 0, end: 1).animate(fabCurve);
    borderRadiusAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(borderRadiusCurve);
    themeToggleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _themeToggleController, curve: Curves.elasticOut),
    );

    _hideBottomBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fabAnimationController.forward();
        _borderRadiusAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _borderRadiusAnimationController.dispose();
    _themeToggleController.dispose();
    _hideBottomBarAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    if (!mounted) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundColor(context),
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _toggleTheme() {
    if (!mounted) return;

    final themeViewModel = context.read<ThemeViewModel>();

    // Start theme toggle animation
    _themeToggleController.forward().then((_) {
      if (mounted) {
        _themeToggleController.reverse();
      }
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Toggle theme
    themeViewModel.toggleTheme();

    // Show theme change confirmation after a small delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final isDarkMode = themeViewModel.themeMode == ThemeMode.dark;

        DialogHelper.showSuccess(
          context: context,
          title: 'Theme Changed!',
          message: isDarkMode
              ? '🌙 Dark mode activated. Easy on the eyes!'
              : '☀️ Light mode activated. Bright and clear!',
          buttonText: 'Nice!',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSystemUI();
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundColor(context),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, child) {
          final isDarkMode = themeViewModel.themeMode == ThemeMode.dark;

          return ScaleTransition(
            scale: fabAnimation,
            child: AnimatedBuilder(
              animation: themeToggleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (themeToggleAnimation.value * 0.2),
                  child: FloatingActionButton(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 8,
                    onPressed: _toggleTheme,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return RotationTransition(
                              turns: animation,
                              child: child,
                            );
                          },
                      child: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        key: ValueKey<bool>(isDarkMode),
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive
              ? AppColors.primary
              : AppColors.textSecondary(context);

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: isActive
                    ? BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  isActive ? _activeIconList[index] : _iconList[index],
                  size: isActive ? 26 : 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: isActive ? 12 : 10,
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(_labelList[index]),
              ),
            ],
          );
        },
        backgroundColor: AppColors.surfaceColor(context),
        activeIndex: _selectedIndex,
        splashColor: AppColors.primary.withOpacity(0.2),
        notchAndCornersAnimation: borderRadiusAnimation,
        splashSpeedInMilliseconds: 300,
        notchSmoothness: NotchSmoothness.smoothEdge,
        gapLocation: GapLocation.center,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: _onItemTapped,
        hideAnimationController: _hideBottomBarAnimationController,
        shadow: BoxShadow(
          offset: const Offset(0, -2),
          blurRadius: 12,
          spreadRadius: 0.5,
          color: AppColors.primary.withOpacity(0.1),
        ),
        height: 75,
        elevation: 8,
      ),
    );
  }
}
