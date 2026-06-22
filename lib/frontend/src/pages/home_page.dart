import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import '../components/home/search_bar.dart';
import '../components/home/quick_access_cards.dart';
import '../components/home/feature_sections.dart';
import '../components/smart/weather_widget.dart';
import '../components/discover/popular_destinations.dart' hide Destination;
import '../components/smart/smart_route_planner.dart';
import '../components/discover/hotel_food_finder.dart';
import '../components/emergency/emergency_ice.dart';
import '../components/ai/ai_recommendations.dart';
import '../components/discover/interest_filters.dart';
import '../components/smart/smart_alerts.dart';
import '../utils/responsive.dart';
import '../ui/app_theme.dart';
import '../ui/destination_theme.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onPlanRoute;
  final Function(String)? onTabChange;

  const HomePage({super.key, required this.onPlanRoute, this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _activeFilters = const ['Nature'];

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtil.getResponsivePadding(context);
    final dtProvider = context.watch<DestinationThemeProvider>();
    final dtTheme = dtProvider.activeTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  dtTheme.heroDark[0].withValues(alpha: 0.9),
                  Theme.of(context).scaffoldBackgroundColor,
                ]
              : [
                  Theme.of(context).scaffoldBackgroundColor,
                  dtTheme.heroLight.last.withValues(alpha: 0.5),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dtProvider.isNonDefault)
              _JourneyThemeBanner(theme: dtTheme),
            SearchBar(onTabChange: widget.onTabChange),
            SizedBox(height: padding),
            // RepaintBoundary isolates each section so rebuilds don't cascade
            const RepaintBoundary(child: SmartAlerts()),
            const SizedBox(height: 16),
            const RepaintBoundary(child: QuickAccessCards()),
            const SizedBox(height: 16),
            const RepaintBoundary(child: ResponsiveWeatherEmergency()),
            const SizedBox(height: 16),
            InterestFilters(
              initialFilters: _activeFilters,
              onFiltersChanged: (filters) =>
                  setState(() => _activeFilters = filters),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: PopularDestinations(activeFilters: _activeFilters),
            ),
            const SizedBox(height: 16),
            const RepaintBoundary(child: AIRecommendations()),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SmartRoutePlanner(onPlanRoute: widget.onPlanRoute),
            ),
            const SizedBox(height: 16),
            const RepaintBoundary(child: HotelFoodFinder()),
            const SizedBox(height: 16),
            const RepaintBoundary(child: FeatureSections()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Shown when a non-default destination theme is active (auto or manual).
class _JourneyThemeBanner extends StatelessWidget {
  final DestinationTheme theme;
  const _JourneyThemeBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.heroDark,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(theme.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${theme.label} Journey Theme Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Based on your active booking destination',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveWeatherEmergency extends StatelessWidget {
  const ResponsiveWeatherEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    Widget weatherBox = Container(
      decoration: AppTheme.weatherCardDecoration, // ✅ FIXED
      padding: const EdgeInsets.all(16),
      child: const WeatherWidget(),
    );

    Widget emergencyBox = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.homeGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.turquoise.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: const EmergencyICE(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: weatherBox),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: emergencyBox),
            ],
          );
        } else {
          return Column(
            children: [weatherBox, const SizedBox(height: 16), emergencyBox],
          );
        }
      },
    );
  }
}
