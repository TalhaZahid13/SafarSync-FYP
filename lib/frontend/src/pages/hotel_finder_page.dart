import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import 'hotel_booking_page.dart';
import 'live_map_page.dart';

class HotelFinderPage extends StatefulWidget {
  const HotelFinderPage({super.key});

  @override
  State<HotelFinderPage> createState() => _HotelFinderPageState();
}

class _HotelFinderPageState extends State<HotelFinderPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _query = '';

  final List<String> _categories = ['All', 'Luxury', 'Boutique', 'Budget'];

  // Hotels, rooms and prices come from the SafarSync API (admin-managed
  // inventory). The app never decides a price.
  List<Map<String, dynamic>> _hotels = [];
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
    final r = await ApiService.getRequest('/hotels', auth: false);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        final money = NumberFormat('#,##0');
        _hotels = [
          for (final h in (r['hotels'] as List? ?? const []))
            if (h is Map)
              {
                'hotel_id': asInt(h['hotel_id']),
                'name': '${h['name'] ?? ''}',
                'location': '${h['address'] ?? h['city'] ?? ''}',
                'image': '${h['image_url'] ?? ''}',
                'rating': asDouble(h['rating']) ?? 0.0,
                'price': asDouble(h['from_price']) != null
                    ? 'From PKR ${money.format(asDouble(h['from_price']))}'
                    : 'See rooms',
                'category': '${h['category'] ?? ''}',
                'amenities': [
                  for (final a in (h['amenities'] as List? ?? const [])) '$a',
                ],
                'lat': asDouble(h['latitude']),
                'lng': asDouble(h['longitude']),
              },
        ];
      } else {
        _error = '${r['message'] ?? r['error'] ?? 'Could not load hotels'}';
      }
    });
  }

  List<Map<String, dynamic>> get _filtered {
    return _hotels.where((h) {
      final matchesCategory =
          _selectedCategory == 'All' || h['category'] == _selectedCategory;
      final matchesQuery =
          _query.isEmpty ||
          (h['name'] as String).toLowerCase().contains(_query.toLowerCase()) ||
          (h['location'] as String).toLowerCase().contains(
            _query.toLowerCase(),
          );
      return matchesCategory && matchesQuery;
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
          'Hotel Finder',
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
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search hotels...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.turquoise),
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
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: AppTheme.turquoise,
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
          // Hotel list
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
                      'No hotels found.',
                      style: TextStyle(color: AppTheme.mediumGray),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _HotelCard(hotel: _filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final amenities = hotel['amenities'] as List<String>;
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
          // Hotel image with category badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  hotel['image'] as String,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, e) => Container(
                    height: 160,
                    color: AppTheme.lightGray,
                    child: const Icon(
                      Icons.hotel,
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
                    color: AppTheme.turquoise,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hotel['category'] as String,
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
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: AppTheme.turquoise,
                  ),
                ),
              ),
            ],
          ),
          // Hotel details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hotel['name'] as String,
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
                          hotel['rating'].toString(),
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
                        hotel['location'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Amenity chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: amenities
                      .map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkSlate,
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
                      hotel['price'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    const Text(
                      ' / night + taxes',
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
                          name: hotel['name'] as String,
                          lat: hotel['lat'] as double?,
                          lng: hotel['lng'] as double?,
                        ),
                        icon: const Icon(Icons.navigation, size: 14),
                        label: const Text(
                          'Navigate',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.turquoise,
                          side: BorderSide(color: AppTheme.turquoise),
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
                            builder: (_) => HotelBookingPage(
                              hotelId: hotel['hotel_id'] as int,
                              hotelName: hotel['name'] as String,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.turquoise,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Book Now',
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
