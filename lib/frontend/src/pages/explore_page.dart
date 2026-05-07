import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String searchQuery = '';
  String activeCategory = 'all';
  List<dynamic> destinations = [];
  bool isLoadingDestinations = false;
  String? errorMessage;

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

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

  Future<void> _fetchDestinations() async {
    setState(() {
      isLoadingDestinations = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getDestinations(
        page: 1,
        limit: 50,
        // sortBy: 'rating',
      );

      if (response['success']) {
        final data = response['data'];
        final directDestinations = response['destinations'];
        final fetchedDestinations = data is Map
            ? (data['destinations'] as List? ?? const [])
            : (directDestinations as List? ?? const []);

        setState(() {
          destinations = fetchedDestinations;
          isLoadingDestinations = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load destinations';
          isLoadingDestinations = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage!)));
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading destinations: $e';
        isLoadingDestinations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading destinations: $e')),
        );
      }
    }
  }

  double _parseRating(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredDestinations = destinations.where((dest) {
      final matchesCategory =
          activeCategory == 'all' || dest['category'] == activeCategory;
      final matchesSearch = ((dest['name'] ?? 'Unknown') as String)
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Pakistan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Discover amazing places across the Pakistan',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    onChanged: (val) => setState(() {
                      searchQuery = val;
                    }),
                  ),
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
                          ? LinearGradient(
                              colors: [
                                colorScheme.secondary,
                                colorScheme.primary,
                              ],
                            )
                          : null,
                      color: isActive ? null : theme.cardColor,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 16,
                          color: isActive
                              ? colorScheme.onPrimary
                              : theme.iconTheme.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? colorScheme.onPrimary
                                : theme.textTheme.bodyMedium?.color,
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
          if (isLoadingDestinations)
            const Center(child: CircularProgressIndicator())
          else if (destinations.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No destinations found',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ),
            )
          else
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

                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
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
                        child: _buildDestinationImage(
                          context,
                          dest['image'] ??
                              dest['image_url'] ??
                              'https://via.placeholder.com/400',
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
                                          dest['name'] ?? 'Unknown',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (dest['location'] ??
                                                  dest['country'] ??
                                                  'Unknown')
                                              .toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: null,
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
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          _parseRating(
                                            dest['rating'],
                                          ).toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colorScheme
                                                .onSecondaryContainer,
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
                                children: [
                                  Expanded(
                                    child: Text(
                                      dest['price'] ?? 'N/A',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: null,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
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
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.secondary,
                                                colorScheme.primary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontSize: 11,
                                            ),
                                          ),
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

          if (filteredDestinations.isEmpty && !isLoadingDestinations)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No destinations found',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationImage(BuildContext context, String? imageSource) {
    final theme = Theme.of(context);
    if (imageSource == null || imageSource.isEmpty) {
      return Container(
        height: 90,
        width: double.infinity,
        color: theme.cardColor,
        child: Icon(Icons.landscape, color: theme.iconTheme.color),
      );
    }

    final isNetworkImage =
        imageSource.startsWith('http://') || imageSource.startsWith('https://');

    return isNetworkImage
        ? Image.network(
            imageSource,
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 90,
                width: double.infinity,
                color: Colors.grey.shade800,
                child: const Icon(Icons.landscape, color: Colors.white54),
              );
            },
          )
        : Image.asset(
            imageSource,
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 90,
                width: double.infinity,
                color: Colors.grey.shade800,
                child: const Icon(Icons.landscape, color: Colors.white54),
              );
            },
          );
  }
}
