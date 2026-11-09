import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import 'bookings_page.dart';
import 'live_map_page.dart';

class FoodSpotsPage extends StatefulWidget {
  const FoodSpotsPage({super.key});

  @override
  State<FoodSpotsPage> createState() => _FoodSpotsPageState();
}

class _FoodSpotsPageState extends State<FoodSpotsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCuisine = 'All';
  String _query = '';

  final List<String> _cuisines = [
    'All',
    'Pakistani',
    'BBQ',
    'Continental',
    'Fast Food',
  ];

  final List<Map<String, dynamic>> _restaurants = [
    {
      'name': 'Monal Restaurant',
      'location': 'Pir Sohawa, Islamabad',
      'cuisine': 'Pakistani & Continental',
      'cuisineTag': 'Pakistani',
      'image':
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&q=80',
      'rating': 4.9,
      'price': 'PKR 3,000',
      'priceNum': 3000.0,
      'tags': ['Rooftop', 'Family', 'Scenic View'],
      'lat': 33.7551,
      'lng': 73.0898,
    },
    {
      'name': 'Bundu Khan',
      'location': 'Main Boulevard, Lahore',
      'cuisine': 'Traditional BBQ',
      'cuisineTag': 'BBQ',
      'image':
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&q=80',
      'rating': 4.7,
      'price': 'PKR 2,000',
      'priceNum': 2000.0,
      'tags': ['BBQ', 'Dine-in', 'Takeaway'],
      'lat': 31.5201,
      'lng': 74.3587,
    },
    {
      'name': 'The Golden Fork',
      'location': 'Blue Area, Islamabad',
      'cuisine': 'Continental',
      'cuisineTag': 'Continental',
      'image':
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
      'rating': 4.5,
      'price': 'PKR 2,500',
      'priceNum': 2500.0,
      'tags': ['Fine Dining', 'Business'],
      'lat': 33.7280,
      'lng': 73.0883,
    },
    {
      'name': 'Kolachi Restaurant',
      'location': 'Do Darya, Karachi',
      'cuisine': 'Pakistani',
      'cuisineTag': 'Pakistani',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
      'rating': 4.6,
      'price': 'PKR 2,800',
      'priceNum': 2800.0,
      'tags': ['Seafood', 'Sea View', 'Family'],
      'lat': 24.8138,
      'lng': 67.0291,
    },
    {
      'name': "McDonald's",
      'location': 'Multiple Locations',
      'cuisine': 'Fast Food',
      'cuisineTag': 'Fast Food',
      'image':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
      'rating': 4.0,
      'price': 'PKR 800',
      'priceNum': 800.0,
      'tags': ['Quick Bite', 'Takeaway', 'Delivery'],
      'lat': null,
      'lng': null,
    },
    {
      'name': 'Salt\'n Pepper Village',
      'location': 'Main Canal Bank Road, Lahore',
      'cuisine': 'Pakistani',
      'cuisineTag': 'Pakistani',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
      'rating': 4.8,
      'price': 'PKR 3,500',
      'priceNum': 3500.0,
      'tags': ['Village Theme', 'Desi', 'Family'],
      'lat': 31.4792,
      'lng': 74.2917,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _restaurants.where((r) {
      final matchesCuisine =
          _selectedCuisine == 'All' || r['cuisineTag'] == _selectedCuisine;
      final matchesQuery =
          _query.isEmpty ||
          (r['name'] as String).toLowerCase().contains(_query.toLowerCase()) ||
          (r['location'] as String).toLowerCase().contains(
            _query.toLowerCase(),
          );
      return matchesCuisine && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        elevation: 0,
        title: const Text(
          'Food Spots',
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.darkSlate),
      ),
      body: Column(
        children: [
          // Search + filter header
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFFF8F00),
                    ),
                    filled: true,
                    fillColor: AppTheme.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _cuisines.map((c) {
                      final selected = _selectedCuisine == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCuisine = c),
                          selectedColor: const Color(0xFFFF8F00),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.darkSlate,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          backgroundColor: AppTheme.lightGray,
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Restaurant list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No restaurants found.',
                      style: TextStyle(color: AppTheme.mediumGray),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _RestaurantCard(restaurant: _filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final tags = restaurant['tags'] as List<String>;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  restaurant['image'] as String,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, e) => Container(
                    height: 160,
                    color: AppTheme.lightGray,
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    restaurant['cuisineTag'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          restaurant['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        restaurant['location'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant['cuisine'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF8F00,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF8F00),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      restaurant['price'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                    const Text(
                      ' / person',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => autoNavigateTo(
                          context,
                          name: restaurant['name'] as String,
                          lat: restaurant['lat'] as double?,
                          lng: restaurant['lng'] as double?,
                        ),
                        icon: const Icon(Icons.navigation, size: 14),
                        label: const Text(
                          'Navigate',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8F00),
                          side: const BorderSide(color: Color(0xFFFF8F00)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateBookingScreen(
                              presetType: 'restaurant',
                              presetItemName: restaurant['name'] as String,
                              presetPricePerUnit:
                                  restaurant['priceNum'] as double,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reserve Table',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
