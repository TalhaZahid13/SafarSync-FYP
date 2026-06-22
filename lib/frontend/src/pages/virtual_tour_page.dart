import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/app_theme.dart';

// ─── Virtual 3D Tour Page ─────────────────────────────────────────────────────
// Opens Google Maps 3D/Street View for iconic Pakistani landmarks.

class VirtualTourPage extends StatefulWidget {
  const VirtualTourPage({super.key});

  @override
  State<VirtualTourPage> createState() => _VirtualTourPageState();
}

class _VirtualTourPageState extends State<VirtualTourPage> {
  String _activeCategory = 'All';
  final _categories = ['All', 'Monuments', 'Nature', 'Cities', 'Forts'];

  static const _destinations = [
    _VTDest(
      name: 'Badshahi Mosque',
      city: 'Lahore',
      category: 'Monuments',
      lat: 31.5882,
      lng: 74.3109,
      description:
          'One of the world\'s largest mosques, this Mughal masterpiece can hold 100,000 worshippers. Explore its stunning red sandstone courtyard in 360°.',
      highlights: ['Mughal Architecture', 'Grand Courtyard', 'Historic Minarets', 'Sunset Views'],
      icon: Icons.mosque_rounded,
      gradientColors: [Color(0xFF8B4513), Color(0xFFD2691E)],
    ),
    _VTDest(
      name: 'Lahore Fort',
      city: 'Lahore',
      category: 'Forts',
      lat: 31.5921,
      lng: 74.3156,
      description:
          'A UNESCO World Heritage Site spanning over 20 hectares. This imperial fort\'s Sheesh Mahal (Hall of Mirrors) is breathtaking.',
      highlights: ['Sheesh Mahal', 'Naulakha Pavilion', 'Diwan-e-Aam', 'Persian Murals'],
      icon: Icons.castle_rounded,
      gradientColors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
    ),
    _VTDest(
      name: 'Faisal Mosque',
      city: 'Islamabad',
      category: 'Monuments',
      lat: 33.7295,
      lng: 73.0368,
      description:
          'The national mosque of Pakistan, nestled in the Margalla Hills. Its modernist design combining a Turkish tent with Bedouin desert architecture is unique worldwide.',
      highlights: ['Tent-Shaped Structure', 'Margalla Hills Backdrop', 'Interior Mosaics', 'Prayer Hall'],
      icon: Icons.mosque_rounded,
      gradientColors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    ),
    _VTDest(
      name: 'Hunza Valley',
      city: 'Gilgit-Baltistan',
      category: 'Nature',
      lat: 36.3167,
      lng: 74.6500,
      description:
          'A paradise on earth — surrounded by Rakaposhi, Ultar Sar, and Lady Finger peaks. Turquoise Attabad Lake and apricot orchards make it surreal.',
      highlights: ['Attabad Lake', 'Baltit Fort', 'Rakaposhi View', 'KKH Highway'],
      icon: Icons.landscape_rounded,
      gradientColors: [Color(0xFF0D47A1), Color(0xFF26C6DA)],
    ),
    _VTDest(
      name: 'Mohenjo-daro',
      city: 'Sindh',
      category: 'Monuments',
      lat: 27.3244,
      lng: 68.1380,
      description:
          'One of the largest ancient cities of the Indus Valley Civilisation, built around 2500 BCE. A UNESCO World Heritage Site frozen in time.',
      highlights: ['Great Bath', 'Granary', '5000-Year-Old Streets', 'Museum'],
      icon: Icons.account_balance_rounded,
      gradientColors: [Color(0xFF6D4C41), Color(0xFFA1887F)],
    ),
    _VTDest(
      name: 'Fairy Meadows',
      city: 'Gilgit-Baltistan',
      category: 'Nature',
      lat: 35.3772,
      lng: 74.5923,
      description:
          'The base camp for Nanga Parbat — the "Killer Mountain." Lush green meadows with the 9th-highest peak as a backdrop. Accessible only by jeep + trek.',
      highlights: ['Nanga Parbat View', 'Alpine Meadows', 'Star Gazing', 'Camping'],
      icon: Icons.grass_rounded,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
    ),
    _VTDest(
      name: 'Rohtas Fort',
      city: 'Punjab',
      category: 'Forts',
      lat: 32.9674,
      lng: 73.5890,
      description:
          'Built in 1541 by Sher Shah Suri to subdue the Gakhar tribes, this UNESCO-listed fort has walls stretching over 4km with 68 semi-circular bastions.',
      highlights: ['68 Bastions', 'Shahi Mosque', '4km Walls', 'Ancient Gates'],
      icon: Icons.castle_rounded,
      gradientColors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
    ),
    _VTDest(
      name: 'Skardu Valley',
      city: 'Gilgit-Baltistan',
      category: 'Nature',
      lat: 35.2971,
      lng: 75.6333,
      description:
          'Gateway to K2 and four 8000m peaks. Shangrila Resort, Deosai Plains (world\'s second highest plateau), and the crystal clear Satpara Lake are unmissable.',
      highlights: ['Deosai Plains', 'Shangrila Resort', 'Satpara Lake', 'K2 Base Camp Access'],
      icon: Icons.terrain_rounded,
      gradientColors: [Color(0xFF01579B), Color(0xFF0288D1)],
    ),
    _VTDest(
      name: 'Lahore Old City',
      city: 'Lahore',
      category: 'Cities',
      lat: 31.5808,
      lng: 74.3191,
      description:
          'Walk the 2,000-year-old walled city. Anarkali Bazaar, Food Street, Wazir Khan Mosque, and countless havelis tell the story of Mughal splendor.',
      highlights: ['Wazir Khan Mosque', 'Anarkali Bazaar', 'Food Street', 'Delhi Gate'],
      icon: Icons.location_city_rounded,
      gradientColors: [Color(0xFFBF360C), Color(0xFFFF7043)],
    ),
    _VTDest(
      name: 'Naran & Kaghan Valley',
      city: 'KPK',
      category: 'Nature',
      lat: 34.9008,
      lng: 73.6488,
      description:
          'The crown jewel of KPK — Saif ul Malook lake sits at 3,224m above sea level. Legend says a fairy queen fell in love with a prince here.',
      highlights: ['Saif ul Malook Lake', 'Lulusar Lake', 'Babusar Pass', 'River Kunhar'],
      icon: Icons.water_rounded,
      gradientColors: [Color(0xFF006064), Color(0xFF00ACC1)],
    ),
    _VTDest(
      name: 'Margalla Hills',
      city: 'Islamabad',
      category: 'Nature',
      lat: 33.7683,
      lng: 73.0579,
      description:
          'Islamabad\'s green lungs. Trail 3, 4, and 5 offer panoramic city views. The Daman-e-Koh viewpoint is the perfect sunset spot.',
      highlights: ['Trail 5 Hike', 'Daman-e-Koh', 'Faisal Mosque View', 'Wildlife'],
      icon: Icons.forest_rounded,
      gradientColors: [Color(0xFF2E7D32), Color(0xFF81C784)],
    ),
    _VTDest(
      name: 'Clifton Beach',
      city: 'Karachi',
      category: 'Cities',
      lat: 24.8030,
      lng: 67.0353,
      description:
          'Karachi\'s most famous beach. The Arabian Sea coastline stretches endlessly. Camel rides, street food, Sea View, and the busy city skyline in the background.',
      highlights: ['Arabian Sea Views', 'Camel Rides', 'Sea View Promenade', 'Sunset'],
      icon: Icons.beach_access_rounded,
      gradientColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
    ),
  ];

  List<_VTDest> get _filtered => _activeCategory == 'All'
      ? _destinations
      : _destinations.where((d) => d.category == _activeCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _DestCard(dest: _filtered[i]),
                childCount: _filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    expandedHeight: 200,
    pinned: true,
    backgroundColor: const Color(0xFF0D1B2A),
    foregroundColor: Colors.white,
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsets.only(left: 60, bottom: 14),
      title: const Text('3D Virtual Tours', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B3A4C), Color(0xFF2CAFBC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.threed_rotation, size: 48, color: Colors.white54),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore Pakistan Without Leaving Home',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.turquoise.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${_destinations.length} Iconic Destinations',
                      style: const TextStyle(color: AppTheme.turquoise, fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _buildCategoryFilter() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isActive = cat == _activeCategory;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.turquoise : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppTheme.turquoise : Colors.white24),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ─── Destination Card ─────────────────────────────────────────────────────────

class _DestCard extends StatefulWidget {
  final _VTDest dest;
  const _DestCard({required this.dest});

  @override
  State<_DestCard> createState() => _DestCardState();
}

class _DestCardState extends State<_DestCard> {
  bool _expanded = false;
  bool _launching = false;

  Future<void> _launchTour() async {
    setState(() => _launching = true);
    final lat = widget.dest.lat;
    final lng = widget.dest.lng;

    // Try to open Google Maps Street View (works on Android/iOS with Google Maps installed)
    final Uri gmapsUri = Uri.parse(
      'https://www.google.com/maps/@$lat,$lng,3a,90y,0h,90t/data=!3m6!1e1',
    );

    try {
      if (await canLaunchUrl(gmapsUri)) {
        await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Open Google Maps satellite 3D view
        final Uri fallback = Uri.parse(
          'https://maps.google.com/maps?ll=$lat,$lng&q=${Uri.encodeComponent(widget.dest.name)}&layer=c&t=h&z=17',
        );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch map. Please install Google Maps.')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.dest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dest.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(dest.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dest.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(dest.city,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 10),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(dest.category,
                                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),

              // Collapsed: launch button
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(dest.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12, height: 1.4)),
                      ),
                      const SizedBox(width: 12),
                      _tourButton(compact: true),
                    ],
                  ),
                ),

              // Expanded: full info + highlights
              if (_expanded) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(dest.description,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Highlights',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: dest.highlights
                            .map((h) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 11, color: Color(0xFFFBBF24)),
                                      const SizedBox(width: 4),
                                      Text(h,
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _tourButton(compact: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tourButton({required bool compact}) {
    if (compact) {
      return GestureDetector(
        onTap: _launching ? null : _launchTour,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _launching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.threed_rotation, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Tour', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _launching ? null : _launchTour,
      icon: _launching
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.threed_rotation),
      label: Text(_launching ? 'Opening…' : 'Start 360° Virtual Tour'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _VTDest {
  final String name;
  final String city;
  final String category;
  final double lat;
  final double lng;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final List<Color> gradientColors;

  const _VTDest({
    required this.name,
    required this.city,
    required this.category,
    required this.lat,
    required this.lng,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.gradientColors,
  });
}
