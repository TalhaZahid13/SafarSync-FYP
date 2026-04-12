import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

/// Home screen search bar:
/// - UI app ki theme ke mutabiq
/// - Places, Routes, Wishlist mein simple text-based search
/// - Result ek bottom sheet mein dikhaye jaate hain
class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  // Demo data: tum baad mein isko apne actual data se replace kar sakte ho
  final List<_SearchItem> _allItems = const [
    // Places
    _SearchItem(
      type: _SearchType.place,
      title: 'Hunza Valley',
      subtitle: 'Gilgit-Baltistan • Place',
    ),
    _SearchItem(
      type: _SearchType.place,
      title: 'Skardu Valley',
      subtitle: 'Gilgit-Baltistan • Place',
    ),
    _SearchItem(
      type: _SearchType.place,
      title: 'Fairy Meadows',
      subtitle: 'Gilgit-Baltistan • Place',
    ),
    _SearchItem(
      type: _SearchType.place,
      title: 'Food Street Lahore',
      subtitle: 'Punjab • Food Spot',
    ),

    // Routes
    _SearchItem(
      type: _SearchType.route,
      title: 'Northern Pakistan Tour',
      subtitle: 'Islamabad → Hunza Valley • Route',
    ),
    _SearchItem(
      type: _SearchType.route,
      title: 'Coastal Journey',
      subtitle: 'Karachi → Gwadar • Route',
    ),

    // Wishlist
    _SearchItem(
      type: _SearchType.wishlist,
      title: 'K2 Base Camp Trek',
      subtitle: 'Wishlist • High Altitude Adventure',
    ),
    _SearchItem(
      type: _SearchType.wishlist,
      title: 'Chitral Valley Roadtrip',
      subtitle: 'Wishlist • Scenic Route',
    ),
  ];

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
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Searching for "$query"...',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResultsSheet({
    required String title,
    required List<_SearchItem> results,
    required String query,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
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
                          Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: _buildTypeIcon(item.type),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () {
                            // TODO: yahan se tum navigate kar sakte ho:
                            // - Place -> Explore tab
                            // - Route -> Routes tab
                            // - Wishlist -> Wishlist tab
                            Navigator.pop(context);
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

  Widget _buildTypeIcon(_SearchType type) {
    IconData icon;
    Color color;

    switch (type) {
      case _SearchType.place:
        icon = Icons.place;
        color = Colors.lightBlueAccent;
        break;
      case _SearchType.route:
        icon = Icons.alt_route;
        color = Colors.amberAccent;
        break;
      case _SearchType.wishlist:
        icon = Icons.favorite_border;
        color = Colors.pinkAccent;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search places, routes, wishlist...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearch,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFDB913), size: 22),
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
