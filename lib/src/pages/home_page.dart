import 'package:flutter/material.dart';
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
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          SearchBar(),

          SizedBox(height: 16),

          // Smart Alerts
          SmartAlerts(),

          SizedBox(height: 16),

          // Quick Access Cards
          QuickAccessCards(),

          SizedBox(height: 16),

          // Weather & EmergencyICE
          ResponsiveWeatherEmergency(),

          SizedBox(height: 16),

          // Popular Destinations
          PopularDestinations(),

          SizedBox(height: 16),

          // Interest Filters
          InterestFilters(),

          SizedBox(height: 16),

          // AI Recommendations
          AIRecommendations(),

          SizedBox(height: 16),

          // Smart Route Planner
          SmartRoutePlanner(),

          SizedBox(height: 16),

          // Hotel & Food Finder
          HotelFoodFinder(),

          SizedBox(height: 16),

          // Additional Feature Sections
          FeatureSections(),
        ],
      ),
    );
  }
}

/// A helper widget to mimic the grid layout (WeatherWidget + EmergencyICE)
class ResponsiveWeatherEmergency extends StatelessWidget {
  const ResponsiveWeatherEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Desktop / Tablet: 3-column layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 1, child: WeatherWidget()),
              SizedBox(width: 16),
              Expanded(flex: 2, child: EmergencyICE()),
            ],
          );
        } else {
          // Mobile: stacked layout
          return Column(
            children: const [
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
