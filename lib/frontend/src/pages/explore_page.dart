import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'smart_route_page.dart';
import 'bookings_page.dart';
import 'virtual_tour_player_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchDestinations();
    });
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

  void _showDestinationDetails(
    BuildContext context,
    Map<String, dynamic> dest,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Hero image
                ClipRRect(
                  child: _buildDestinationImage(
                    sheetCtx,
                    dest['image'] ?? dest['image_url'],
                    height: 220,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dest['name'] ?? 'Unknown',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (dest['category'] ?? 'General')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location + rating
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (dest['location'] ??
                                      dest['country'] ??
                                      'Unknown')
                                  .toString(),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            _parseRating(dest['rating']).toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      if ((dest['description'] ?? '').toString().isNotEmpty)
                        ...[
                          Text(
                            dest['description'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      // Price chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 16, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              dest['price']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final rawId =
                                  dest['id'] ?? dest['destination_id'];
                              final id = int.tryParse('$rawId');
                              if (id == null) return;
                              Navigator.pop(sheetCtx);
                              final res = await ApiService.addToWishlist(
                                destinationId: id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['success'] == true
                                          ? 'Added to wishlist!'
                                          : res['message'] ??
                                              'Already in wishlist',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Wishlist'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetCtx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SmartRoutePage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map_outlined,
                                  color: Colors.white),
                              label: const Text(
                                'Route',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final rawId = dest['destination_id'] ?? dest['id'];
                                final destId = rawId != null ? int.tryParse('$rawId') : null;
                                final destName = dest['name']?.toString();
                                final rawCost = dest['average_cost'] ?? dest['price'];
                                final avgCost = rawCost != null ? double.tryParse('$rawCost') : null;
                                Navigator.pop(sheetCtx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateBookingScreen(
                                      initialDestinationId: destId,
                                      initialDestinationName: destName,
                                      initialAvgCost: avgCost,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.confirmation_number_outlined,
                                  color: Colors.white),
                              label: const Text(
                                'Book Now',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2CAFBC),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Virtual Tour button (shown for all destinations; checks availability)
                      _VirtualTourButton(
                        destinationId: int.tryParse('${dest['id'] ?? dest['destination_id'] ?? 0}'),
                        destinationName: dest['name']?.toString() ?? '',
                        onClose: () => Navigator.pop(sheetCtx),
                        parentContext: context,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                                        onTap: () => _showDestinationDetails(
                                          context,
                                          dest,
                                        ),
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

  Widget _buildDestinationImage(
    BuildContext context,
    String? imageSource, {
    double height = 90,
  }) {
    final theme = Theme.of(context);
    if (imageSource == null || imageSource.isEmpty) {
      return Container(
        height: height,
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
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: height,
              width: double.infinity,
              color: Colors.grey.shade800,
              child: const Icon(Icons.landscape, color: Colors.white54),
            ),
          )
        : Image.asset(
            imageSource,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: height,
              width: double.infinity,
              color: Colors.grey.shade800,
              child: const Icon(Icons.landscape, color: Colors.white54),
            ),
          );
  }
}

// ─── Virtual Tour availability button ────────────────────────────────────────
// Checks if a virtual tour exists for this destination and shows launch button.

class _VirtualTourButton extends StatefulWidget {
  final int? destinationId;
  final String destinationName;
  final VoidCallback onClose;
  final BuildContext parentContext;

  const _VirtualTourButton({
    required this.destinationId,
    required this.destinationName,
    required this.onClose,
    required this.parentContext,
  });

  @override
  State<_VirtualTourButton> createState() => _VirtualTourButtonState();
}

class _VirtualTourButtonState extends State<_VirtualTourButton> {
  bool _checking = true;
  Map<String, dynamic>? _tour;

  @override
  void initState() {
    super.initState();
    _checkTour();
  }

  Future<void> _checkTour() async {
    if (widget.destinationId == null || widget.destinationId == 0) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    try {
      final r = await ApiService.getRequest(
          '/virtual-tours/destination/${widget.destinationId}');
      if (r['success'] == true) {
        if (mounted) setState(() { _tour = r['tour'] as Map<String, dynamic>; _checking = false; });
      } else {
        if (mounted) setState(() => _checking = false);
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(color: Color(0xFF2CAFBC), minHeight: 2),
      );
    }
    if (_tour == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          widget.onClose();
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (_) => VirtualTourPlayerPage(
                tourId: _tour!['id'] as int,
                tourTitle: _tour!['title'] as String? ?? 'Virtual Tour',
                destinationId: widget.destinationId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.threed_rotation, size: 18, color: Color(0xFF2CAFBC)),
        label: const Text(
          'Start Virtual Tour',
          style: TextStyle(color: Color(0xFF2CAFBC), fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2CAFBC)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
