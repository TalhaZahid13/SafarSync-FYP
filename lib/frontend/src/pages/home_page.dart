import 'package:flutter/material.dart' hide SearchBar;
import '../components/home/search_bar.dart';
import '../components/home/quick_access_cards.dart';
import '../components/smart/weather_widget.dart';
import '../components/discover/popular_destinations.dart';
import '../components/smart/smart_route_planner.dart';
import '../components/discover/hotel_food_finder.dart';
import '../components/emergency/emergency_ice.dart';
import '../components/ai/ai_recommendations.dart';
import '../components/home/feature_sections.dart';
import '../components/discover/interest_filters.dart';
import '../components/smart/smart_alerts.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onPlanRoute; // 👈 important

  const HomePage({
    super.key,
    required this.onPlanRoute,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SearchBar(),
          const SizedBox(height: 16),

          const SmartAlerts(),
          const SizedBox(height: 16),

          const QuickAccessCards(),
          const SizedBox(height: 16),

          const ResponsiveWeatherEmergency(),
          const SizedBox(height: 16),

          PopularDestinations(),
          const SizedBox(height: 16),

          const InterestFilters(),
          const SizedBox(height: 16),

          const AIRecommendations(),
          const SizedBox(height: 16),

          // 🔥 yahan se Routes ko trigger karenge
          SmartRoutePlanner(
            onPlanRoute: onPlanRoute,
          ),
          const SizedBox(height: 16),

          const HotelFoodFinder(),
          const SizedBox(height: 16),

          // FeatureSections() ko hata diya tha na
        ],
      ),
    );
  }
}

class ResponsiveWeatherEmergency extends StatelessWidget {
  const ResponsiveWeatherEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: WeatherWidget()),
              SizedBox(width: 16),
              Expanded(flex: 2, child: EmergencyICE()),
            ],
          );
        } else {
          return const Column(
            children: [
              WeatherWidget(),
              SizedBox(height: 16),
              EmergencyICE(),
            ],
          );
        }
      },
    );
  }
}
