import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'virtual_tour_player_page.dart';

// ─── Virtual Tours Browse Page ────────────────────────────────────────────────
// Shows all available virtual tours. Tapping one opens the 360° player.

class VirtualTourPage extends StatefulWidget {
  const VirtualTourPage({super.key});

  @override
  State<VirtualTourPage> createState() => _VirtualTourPageState();
}

class _VirtualTourPageState extends State<VirtualTourPage> {
  List<dynamic> _tours = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiService.getRequest('/virtual-tours');
      setState(() => _tours = (resp['tours'] as List? ?? []));
    } catch (e) {
      setState(() => _error = 'Could not load tours: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTour(Map<String, dynamic> tour) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VirtualTourPlayerPage(
        tourId: tour['id'] as int,
        tourTitle: tour['title'] as String? ?? 'Virtual Tour',
        destinationId: tour['destination_id'] as int?,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B2A), Color(0xFF1B3A4C), Color(0xFF1B5A6E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('360°', style: TextStyle(color: Color(0xFF2CAFBC), fontSize: 32, fontWeight: FontWeight.w900)),
                        const Text('Virtual Tours', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${_tours.length} tours available',
                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF0D1B2A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2CAFBC)))
            : _error != null
                ? _buildError()
                : _tours.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFF2CAFBC),
                        onRefresh: _fetchTours,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tours.length,
                          itemBuilder: (_, i) => _TourCard(
                            tour: _tours[i] as Map<String, dynamic>,
                            onTap: () => _openTour(_tours[i] as Map<String, dynamic>),
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🌐', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9A9E9D), fontSize: 14)),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2CAFBC)),
          onPressed: _fetchTours,
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🏔️', style: TextStyle(fontSize: 52)),
        SizedBox(height: 12),
        Text('No virtual tours yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
        SizedBox(height: 6),
        Text('Check back soon for immersive experiences',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    ),
  );
}

// ─── Tour Card ────────────────────────────────────────────────────────────────

class _TourCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onTap;

  const _TourCard({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sceneCount = tour['scene_count'] ?? 0;
    final hasThumb = (tour['thumbnail_url'] ?? '').toString().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image / gradient
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B2A), Color(0xFF1B5A6E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  image: hasThumb
                      ? DecorationImage(
                          image: NetworkImage(tour['thumbnail_url'] as String),
                          fit: BoxFit.cover, colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.35), BlendMode.darken))
                      : null,
                ),
                child: Stack(
                  children: [
                    // 360 badge
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CAFBC).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('360°',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                    // Play button
                    Center(
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    // Scene count bottom-left
                    if (sceneCount > 0)
                      Positioned(
                        bottom: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$sceneCount scenes',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tour['title'] ?? 'Virtual Tour',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if ((tour['destination_name'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 13, color: Color(0xFF2CAFBC)),
                          const SizedBox(width: 4),
                          Text(tour['destination_name'].toString(),
                            style: const TextStyle(color: Color(0xFF2CAFBC), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    if ((tour['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(tour['description'].toString(),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, height: 1.5)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.threed_rotation, size: 18),
                        label: const Text('Start Virtual Tour'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2CAFBC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
