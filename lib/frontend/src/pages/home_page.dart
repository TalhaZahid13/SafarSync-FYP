import 'package:flutter/material.dart' hide SearchBar;
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).cardColor.withValues(alpha: 0.65),
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
