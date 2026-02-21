import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String searchQuery = '';
  String activeCategory = 'all';

  final categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.place},
    {'id': 'nature', 'name': 'Nature', 'icon': Icons.terrain},
    {'id': 'history', 'name': 'History', 'icon': Icons.account_balance},
    {'id': 'food', 'name': 'Food', 'icon': Icons.restaurant},
    {
      'id': 'adventure',
      'name': 'Adventure',
      'icon': Icons.transfer_within_a_station,
    },
  ];

  /// Make sure every destination has an `image` entry.
  final destinations = [
    {
      'name': 'Fairy Meadows',
      'location': 'Gilgit-Baltistan',
      'category': 'nature',
      'rating': 4.9,
      'price': 'Rs 40,000',
      'image':
      'https://images.unsplash.com/photo-1614104072206-056aa80e59ff?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Skardu Valley',
      'location': 'Gilgit-Baltistan',
      'category': 'nature',
      'rating': 4.8,
      'price': 'Rs 45,000',
      'image':
      'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90d2?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Mohenjo-daro',
      'location': 'Sindh',
      'category': 'history',
      'rating': 4.6,
      'price': 'Rs 20,000',
      'image':
      'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Rohtas Fort',
      'location': 'Punjab',
      'category': 'history',
      'rating': 4.5,
      'price': 'Rs 15,000',
      'image':
      'https://images.unsplash.com/photo-1599661046289-3a4aaf9a4926?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Food Street Lahore',
      'location': 'Punjab',
      'category': 'food',
      'rating': 4.7,
      'price': 'Rs 5,000',
      'image':
      'https://images.unsplash.com/photo-1544027993-37dbfe43562a?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Burns Road Karachi',
      'location': 'Sindh',
      'category': 'food',
      'rating': 4.8,
      'price': 'Rs 4,000',
      'image':
      'https://images.unsplash.com/photo-1592861956120-e524fc739696?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'K2 Base Camp',
      'location': 'Gilgit-Baltistan',
      'category': 'adventure',
      'rating': 5.0,
      'price': 'Rs 150,000',
      'image':
      'https://images.unsplash.com/photo-1526481280695-3c687fd543c0?auto=format&fit=crop&w=900&q=80',
    },
    {
      'name': 'Chitral Valley Trek',
      'location': 'Khyber Pakhtunkhwa',
      'category': 'adventure',
      'rating': 4.7,
      'price': 'Rs 55,000',
      'image':
      'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=900&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = destinations.where((dest) {
      final matchesCategory =
          activeCategory == 'all' || dest['category'] == activeCategory;
      final matchesSearch = (dest['name'] as String)
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Pakistan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Discover amazing places across the country',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search destinations...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() {
                      searchQuery = val;
                    }),
                  ),
                ),
                IconButton(
                  icon:
                  const Icon(Icons.filter_list, color: Color(0xFF1B5A6E)),
                  onPressed: () {
                    // TODO: implement filter
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isActive = category['id'] == activeCategory;
                return GestureDetector(
                  onTap: () => setState(() {
                    activeCategory = category['id'] as String;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isActive
                          ? const LinearGradient(
                        colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                      )
                          : null,
                      color: isActive ? null : Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Destinations Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDestinations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final dest = filteredDestinations[index];

              // SAFE image read: may be null
              final String? imageUrl = dest['image'] as String?;
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE (or placeholder if null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                        imageUrl,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 90,
                        width: double.infinity,
                        color: Colors.grey.shade800,
                        child: const Icon(
                          Icons.landscape,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    // CONTENT
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name & Rating
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dest['name'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dest['location'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.yellow,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${dest['rating']}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Price & Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dest['price'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFFFFC837),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    // TODO: open details
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFDB913),
                                          Color(0xFF1B5A6E),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (filteredDestinations.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No destinations found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
