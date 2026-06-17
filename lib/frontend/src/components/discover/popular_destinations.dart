import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../utils/api_service.dart';
import '../../ui/app_theme.dart';
import '../../pages/explore_page.dart';

class Destination {
  final int id;
  final String name;
  final String location;
  final String image;
  final double rating;
  final int reviews;
  final String? price;
  final String? description;
  final String? category;

  Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
    required this.rating,
    required this.reviews,
    this.price,
    this.description,
    this.category,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final dynamic rawPrice = json['price'] ?? json['average_cost'];

    return Destination(
      id: _parseInt(json['id'] ?? json['destination_id']),
      name: (json['name'] ?? 'Unknown').toString(),
      location:
          (json['location'] ?? json['city'] ?? json['country'] ?? 'Unknown')
              .toString(),
      image:
          (json['image'] ??
                  json['image_url'] ??
                  'https://via.placeholder.com/400')
              .toString(),
      rating: _parseDouble(json['rating']),
      reviews: _parseInt(
        json['reviews'] ?? json['numberOfReviews'] ?? json['review_count'],
      ),
      price: rawPrice != null ? rawPrice.toString() : null,
      description: json['description'] != null
          ? json['description'].toString()
          : null,
      category: json['category'] != null ? json['category'].toString() : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class PopularDestinations extends StatefulWidget {
  final List<String> activeFilters;

  const PopularDestinations({Key? key, this.activeFilters = const []}) : super(key: key);

  @override
  State<PopularDestinations> createState() => _PopularDestinationsState();
}

class _PopularDestinationsState extends State<PopularDestinations> {
  List<Destination> destinations = <Destination>[];
  bool isLoadingDestinations = false;
  String? errorMessage;

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
      final dynamic result = await ApiService.getDestinations(
        page: 1,
        limit: 10,
      );

      if (result is Map && result['success'] == true) {
        final List<Destination> parsedDestinations =
            _extractDestinations(result).map((dynamic item) {
              return Destination.fromJson(Map<String, dynamic>.from(item));
            }).toList();

        if (!mounted) return;

        setState(() {
          destinations = parsedDestinations;
        });
      } else {
        if (!mounted) return;

        setState(() {
          errorMessage = (result is Map && result['message'] != null)
              ? result['message'].toString()
              : 'Failed to load destinations';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $e';
      });

      debugPrint('Error fetching destinations: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingDestinations = false;
      });
    }
  }

  List<dynamic> _extractDestinations(Map result) {
    final dynamic data = result['data'];
    final dynamic directDestinations = result['destinations'];

    if (data is Map && data['destinations'] is List) {
      return data['destinations'] as List<dynamic>;
    }

    if (directDestinations is List) {
      return directDestinations as List<dynamic>;
    }

    if (data is List) {
      return data as List<dynamic>;
    }

    return <dynamic>[];
  }

  static const _kFallback = SizedBox(
    height: 108,
    width: double.infinity,
    child: ColoredBox(
      color: Color(0xFF1B3A4C),
      child: Center(child: Icon(Icons.image_not_supported, color: Colors.white54)),
    ),
  );

  Widget _buildImage(String src, double height) {
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: src,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          height: height,
          child: const ColoredBox(
            color: Color(0xFF1B3A4C),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))),
          ),
        ),
        errorWidget: (_, __, ___) => _kFallback,
      );
    }
    return Image.asset(
      src,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _kFallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A4C),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Popular Destinations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExplorePage()),
                    );
                  },
                  child: const Text(
                    'View All →',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoadingDestinations) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDestinations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (destinations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No destinations found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final List<Destination> filtered = widget.activeFilters.isEmpty
        ? destinations
        : destinations.where((d) {
            final cat = (d.category ?? '').toLowerCase();
            return widget.activeFilters.any((f) => f.toLowerCase() == cat);
          }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No destinations match the selected filters',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (BuildContext context, int index) {
        final Destination dest = filtered[index];
        return _buildDestinationCard(dest);
      },
    );
  }

  Widget _buildDestinationCard(Destination dest) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: _buildImage(dest.image, 108),
                ),

                // Gradient overlay on image
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.70),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dest.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dest.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: AppTheme.turquoise,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dest.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${dest.reviews})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        dest.price != null
                            ? Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.turquoise.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.turquoise.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      dest.price!,
                                      style: const TextStyle(
                                        color: AppTheme.turquoise,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
