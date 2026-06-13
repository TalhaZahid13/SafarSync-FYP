import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

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

  final List<Map<String, dynamic>> _hotels = [
    {
      'name': 'Serena Hotel Islamabad',
      'location': 'F-5, Islamabad',
      'image':
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=400&q=80',
      'rating': 4.8,
      'price': 'Rs 25,000',
      'category': 'Luxury',
      'amenities': ['WiFi', 'Pool', 'Spa', 'Restaurant'],
    },
    {
      'name': 'Pearl Continental Lahore',
      'location': 'Mall Road, Lahore',
      'image':
          'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=400&q=80',
      'rating': 4.6,
      'price': 'Rs 18,000',
      'category': 'Luxury',
      'amenities': ['WiFi', 'Pool', 'Gym', 'Restaurant'],
    },
    {
      'name': 'Avari Towers Karachi',
      'location': 'Fatima Jinnah Road, Karachi',
      'image':
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&q=80',
      'rating': 4.5,
      'price': 'Rs 22,000',
      'category': 'Luxury',
      'amenities': ['WiFi', 'Pool', 'Business Center'],
    },
    {
      'name': 'Monal Guest House Murree',
      'location': 'Mall Road, Murree',
      'image':
          'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&q=80',
      'rating': 4.3,
      'price': 'Rs 8,000',
      'category': 'Boutique',
      'amenities': ['WiFi', 'Mountain View', 'Breakfast'],
    },
    {
      'name': 'PTDC Motel Hunza',
      'location': 'Karimabad, Hunza',
      'image':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80',
      'rating': 4.1,
      'price': 'Rs 5,500',
      'category': 'Budget',
      'amenities': ['WiFi', 'Valley View', 'Parking'],
    },
    {
      'name': 'Lockwood Hotel Lahore',
      'location': 'Gulberg III, Lahore',
      'image':
          'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400&q=80',
      'rating': 4.4,
      'price': 'Rs 12,000',
      'category': 'Boutique',
      'amenities': ['WiFi', 'Restaurant', 'Bar'],
    },
  ];

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
                    prefixIcon: const Icon(Icons.search, color: AppTheme.turquoise),
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
                            color: selected
                                ? Colors.white
                                : AppTheme.darkSlate,
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
            child: _filtered.isEmpty
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  hotel['image'] as String,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, e) => Container(
                    height: 160,
                    color: AppTheme.lightGray,
                    child: const Icon(Icons.hotel,
                        size: 48, color: AppTheme.mediumGray),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.turquoise,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hotel['category'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
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
                  child: const Icon(Icons.favorite_border,
                      size: 18, color: AppTheme.turquoise),
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
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
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
                    const Icon(Icons.location_on,
                        size: 14, color: AppTheme.mediumGray),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        hotel['location'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.mediumGray),
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
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.darkSlate),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      hotel['price'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    const Text(
                      ' / night',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.mediumGray),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.turquoise,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
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