import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import 'restaurant_reservation_page.dart';
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

  // Restaurants, opening hours and table availability come from the API.
  List<Map<String, dynamic>> _restaurants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await ApiService.getRequest('/restaurants', auth: false);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        final money = NumberFormat('#,##0');
        _restaurants = [
          for (final x in (r['restaurants'] as List? ?? const []))
            if (x is Map)
              {
                ...Map<String, dynamic>.from(x),
                'name': '${x['name'] ?? ''}',
                'location': '${x['address'] ?? x['city'] ?? ''}',
                'cuisine': '${x['cuisine'] ?? ''}',
                'cuisineTag': '${x['cuisine_tag'] ?? ''}',
                'image': '${x['image_url'] ?? ''}',
                'rating': asDouble(x['rating']) ?? 0.0,
                'price': asDouble(x['avg_price_per_person']) != null
                    ? 'PKR ${money.format(asDouble(x['avg_price_per_person']))}'
                    : '',
                'tags': [
                  for (final t in (x['tags'] as List? ?? const [])) '$t',
                ],
                'lat': asDouble(x['latitude']),
                'lng': asDouble(x['longitude']),
              },
        ];
      } else {
        _error =
            '${r['message'] ?? r['error'] ?? 'Could not load restaurants'}';
      }
    });
  }

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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
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
                        // Walk-in-only places (accepts_reservations = false)
                        // cannot be reserved.
                        onPressed: restaurant['accepts_reservations'] == true
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantReservationPage(
                                    restaurant: restaurant,
                                  ),
                                ),
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          restaurant['accepts_reservations'] == true
                              ? 'Reserve Table'
                              : 'Walk-in only',
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
