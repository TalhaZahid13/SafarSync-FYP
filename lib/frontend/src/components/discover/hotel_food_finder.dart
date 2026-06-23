import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HotelFoodFinder extends StatelessWidget {
  const HotelFoodFinder({super.key});

  final List<Map<String, dynamic>> hotels = const [
    {
      'name': 'Serena Hotel Islamabad',
      'location': 'F-5, Islamabad',
      'image':
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjBob3RlbCUyMHJvb218ZW58MXx8fHwxNzY1NDE0OTcyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      'rating': 4.8,
      'price': 'Rs 25,000',
    },
    {
      'name': 'Pearl Continental Lahore',
      'location': 'Mall Road, Lahore',
      'image':
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjBob3RlbCUyMHJvb218ZW58MXx8fHwxNzY1NDE0OTcyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      'rating': 4.6,
      'price': 'Rs 18,000',
    },
  ];

  final List<Map<String, dynamic>> restaurants = const [
    {
      'name': 'Monal Restaurant',
      'cuisine': 'Pakistani & Continental',
      'image':
          'https://images.unsplash.com/photo-1651440204227-a9a5b9d19712?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZXN0YXVyYW50JTIwZm9vZCUyMGN1aXNpbmV8ZW58MXx8fHwxNzY1NTAzMDY2fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      'rating': 4.9,
      'price': 'Rs 3,000',
    },
    {
      'name': 'Bundu Khan',
      'cuisine': 'Traditional BBQ',
      'image':
          'https://images.unsplash.com/photo-1651440204227-a9a5b9d19712?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZXN0YXVyYW50JTIwZm9vZCUyMGN1aXNpbmV8ZW58MXx8fHwxNzY1NTAzMDY2fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      'rating': 4.7,
      'price': 'Rs 2,000',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 500;

        if (!isWide) {
          return Column(
            children: [
              _buildCardList(
                context: context,
                title: 'Hotel Finder',
                items: hotels,
                isHotel: true,
              ),
              const SizedBox(height: 16),
              _buildCardList(
                context: context,
                title: 'Food Spots',
                items: restaurants,
                isHotel: false,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCardList(
                context: context,
                title: 'Hotel Finder',
                items: hotels,
                isHotel: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardList(
                context: context,
                title: 'Food Spots',
                items: restaurants,
                isHotel: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardList({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
    required bool isHotel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color cardBg = theme.cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // Cards List
          Column(
            children: items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:
                    0.45,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item['image'] as String,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Favorite Icon
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Location / Cuisine
                          Text(
                            isHotel ? item['location'] : item['cuisine'],
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Rating + Price Row (no overflow)
                          Row(
                            children: [
                              // Star + Rating
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item['rating'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  item['price'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isHotel
                                        ? colorScheme.secondary
                                        : Colors.orange[300],
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
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
            }).toList(),
          ),
        ],
      ),
    );
  }
}
