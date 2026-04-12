import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class WishlistPage extends StatelessWidget {
  final wishlistItems = {
    'destinations': [
      {
        'name': 'Hunza Valley',
        'location': 'Gilgit-Baltistan',
        'rating': 4.9,
        'price': 'Rs 45,000',
      },
      {
        'name': 'Naran Kaghan',
        'location': 'Khyber Pakhtunkhwa',
        'rating': 4.8,
        'price': 'Rs 35,000',
      },
    ],
    'hotels': [
      {
        'name': 'Serena Hotel Islamabad',
        'location': 'F-5, Islamabad',
        'rating': 4.8,
        'price': 'Rs 25,000',
      },
    ],
    'restaurants': [
      {
        'name': 'Monal Restaurant',
        'location': 'Islamabad',
        'rating': 4.9,
        'price': 'Rs 3,000',
      },
    ],
  };

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final gridColumns = isTablet ? 3 : 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Delete button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              item['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Handle delete
                            },
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item['location'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating and Price
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${item['rating']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                item['price'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1B5A6E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtil.getResponsivePadding(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'My Wishlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSection(
              title: 'Destinations',
              icon: Icons.place,
              items: wishlistItems['destinations']!,
            ),
            SizedBox(height: padding),
            _buildSection(
              title: 'Hotels',
              icon: Icons.hotel,
              items: wishlistItems['hotels']!,
            ),
            SizedBox(height: padding),
            _buildSection(
              title: 'Restaurants',
              icon: Icons.restaurant,
              items: wishlistItems['restaurants']!,
            ),
          ],
        ),
      ),
    );
  }
}
