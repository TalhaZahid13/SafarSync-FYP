import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../ui/app_theme.dart';

class WishlistPage extends StatelessWidget {
  WishlistPage({super.key});

  static const Color _bgTop = AppTheme.pureWhite;
  static const Color _bgMid = AppTheme.offWhite;
  static const Color _bgBottom = AppTheme.pureWhite;
  static const Color _cardBg = AppTheme.pureWhite;
  static const Color _primaryText = AppTheme.darkSlate;
  static const Color _secondaryText = AppTheme.mediumGray;
  static const Color _priceColor = AppTheme.turquoise;
  static const Color _surfaceOutline = AppTheme.veryLightGray;

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
      {
        'name': 'Fairy Meadows',
        'location': 'Gilgit-Baltistan',
        'rating': 4.9,
        'price': 'Rs 40,000',
      },
    ],
    'hotels': [
      {
        'name': 'Serena Hotel Islamabad',
        'location': 'F-5, Islamabad',
        'rating': 4.8,
        'price': 'Rs 25,000',
      },
      {
        'name': 'Pearl Continental',
        'location': 'Mall Road, Lahore',
        'rating': 4.6,
        'price': 'Rs 18,000',
      },
    ],
    'restaurants': [
      {
        'name': 'Monal Restaurant',
        'location': 'Pakistani & Continental',
        'rating': 4.9,
        'price': 'Rs 3,000',
      },
    ],
  };

  int get _savedCount {
    return wishlistItems.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
  }

  int _resolveGridColumns(double width, int itemCount) {
    if (width < 720) return 1;
    if (width < 1100) return itemCount >= 2 ? 2 : 1;
    if (itemCount >= 3) return 3;
    return itemCount;
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Color> ctaGradient,
    required List<Map<String, dynamic>> items,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridColumns = _resolveGridColumns(
          constraints.maxWidth,
          items.length,
        );
        final isMobile = constraints.maxWidth < 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _primaryText,
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
                      color: AppTheme.turquoise.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.turquoise.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isMobile ? 2.1 : 2.0,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _surfaceOutline),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                fontSize: 15,
                                color: _primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.veryLightGray,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: _secondaryText,
                              ),
                              onPressed: () {},
                              iconSize: 14,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: _secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item['location'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _priceColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${item['rating']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['price'],
                            style: const TextStyle(
                              fontSize: 20,
                              color: _priceColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(colors: ctaGradient),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgMid, _bgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding,
            padding,
            padding,
            padding + 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Wishlist',
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your saved places and experiences',
                          style: TextStyle(fontSize: 13, color: _secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.turquoise.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.turquoise.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: AppTheme.turquoise,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_savedCount saved',
                          style: const TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding * 0.9),
              _buildSection(
                title: 'Destinations',
                icon: Icons.place_outlined,
                accent: AppTheme.turquoise,
                ctaGradient: const [AppTheme.turquoise, AppTheme.lightGray],
                items: wishlistItems['destinations']!,
              ),
              SizedBox(height: padding * 0.9),
              _buildSection(
                title: 'Hotels',
                icon: Icons.apartment_rounded,
                accent: AppTheme.turquoise,
                ctaGradient: const [AppTheme.turquoise, AppTheme.mediumGray],
                items: wishlistItems['hotels']!,
              ),
              SizedBox(height: padding * 0.9),
              _buildSection(
                title: 'Restaurants',
                icon: Icons.restaurant_rounded,
                accent: AppTheme.turquoise,
                ctaGradient: const [AppTheme.turquoise, AppTheme.darkSlate],
                items: wishlistItems['restaurants']!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
