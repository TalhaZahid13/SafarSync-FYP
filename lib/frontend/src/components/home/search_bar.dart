import 'package:flutter/material.dart';
import '../../utils/api_service.dart';
import '../../ui/app_theme.dart';

/// Home screen search bar:
/// - UI app ki theme ke mutabiq
/// - Places, Routes, Wishlist mein simple text-based search
/// - Result ek bottom sheet mein dikhaye jaate hain
/// - Result par click karne se appropriate tab par navigate hota hai
class SearchBar extends StatefulWidget {
  final Function(String)?
  onTabChange; // Optional callback for parent navigation

  const SearchBar({super.key, this.onTabChange});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _handleSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    // Show loading while searching
    _showSearchLoadingSheet(trimmed);

    try {
      final result = await ApiService.searchDestinations(trimmed);

      if (!mounted) return;
      Navigator.pop(context); // Close loading sheet

      if (result['success']) {
        final resultsData = result['results'];
        final data = result['data'];
        final destList = resultsData is List
            ? resultsData
            : (data is Map ? data['destinations'] as List? : data as List?);

        final searchResults = (destList ?? [])
            .map(
              (d) => _SearchItem(
                type: _SearchType.place,
                title: d['name'] ?? 'Unknown',
                subtitle:
                    '${d['location'] ?? d['country'] ?? 'Pakistan'} • Destination',
              ),
            )
            .toList();

        if (mounted) {
          _showResultsSheet(
            title: searchResults.isEmpty
                ? 'No matches found'
                : 'Search results',
            results: searchResults,
            query: trimmed,
          );
        }
      } else {
        if (mounted) {
          _showResultsSheet(
            title: 'Search failed',
            results: const [],
            query: trimmed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading sheet
        _showResultsSheet(
          title: 'Error searching',
          results: const [],
          query: trimmed,
        );
      }
      print('Search error: $e');
    }
  }

  void _showSearchLoadingSheet(String query) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Searching for "$query"...',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleResultTap(_SearchItem item) {
    // Navigate to appropriate tab based on result type
    switch (item.type) {
      case _SearchType.place:
        // Navigate to Explore tab
        if (mounted) {
          widget.onTabChange?.call('explore');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 ${item.title}'),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: AppTheme.turquoise,
            ),
          );
        }
        break;
      case _SearchType.route:
        // Navigate to Routes tab
        if (mounted) {
          widget.onTabChange?.call('routes');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗺️ ${item.title}'),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: AppTheme.turquoise,
            ),
          );
        }
        break;
      case _SearchType.wishlist:
        // Navigate to Wishlist tab
        if (mounted) {
          widget.onTabChange?.call('wishlist');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❤️ ${item.title}'),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: AppTheme.turquoise,
            ),
          );
        }
        break;
    }
  }

  void _showResultsSheet({
    required String title,
    required List<_SearchItem> results,
    required String query,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      results.isEmpty
                          ? 'No results for "$query"'
                          : 'Results for "$query"',
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      'Try searching by place name, route name, or a wishlist item.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: theme.dividerColor, height: 1),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: _buildTypeIcon(context, item.type),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleResultTap(item);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(BuildContext context, _SearchType type) {
    IconData icon;
    Color color;

    switch (type) {
      case _SearchType.place:
        icon = Icons.place;
        color = AppTheme.turquoise;
        break;
      case _SearchType.route:
        icon = Icons.alt_route;
        color = AppTheme.turquoise;
        break;
      case _SearchType.wishlist:
        icon = Icons.favorite_border;
        color = AppTheme.turquoise;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.iconTheme.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'Search places, routes, wishlist...',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearch,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            onPressed: () => _handleSearch(_controller.text),
          ),
        ],
      ),
    );
  }
}

/// Internal enums & model for search items
enum _SearchType { place, route, wishlist }

class _SearchItem {
  final _SearchType type;
  final String title;
  final String subtitle;

  const _SearchItem({
    required this.type,
    required this.title,
    required this.subtitle,
  });
}
