import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import '../ui/app_theme.dart';

// ─── Sasta Tour Packages Page ─────────────────────────────────────────────────

class SastaTourPage extends StatefulWidget {
  const SastaTourPage({super.key});

  @override
  State<SastaTourPage> createState() => _SastaTourPageState();
}

class _SastaTourPageState extends State<SastaTourPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _packages = [];
  String _activeCategory = 'all';
  double? _maxPrice;

  final _categories = ['all', 'Nature', 'Adventure', 'Cultural', 'Family'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_activeCategory != 'all') params['category'] = _activeCategory;
      if (_maxPrice != null) params['max_price'] = _maxPrice!.toStringAsFixed(0);

      final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final resp = await ApiService.getRequest('/tours/packages${qs.isEmpty ? '' : '?$qs'}');

      if (!mounted) return;
      setState(() {
        _packages = List<Map<String, dynamic>>.from(resp['packages'] ?? []);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Sasta Tour Packages'),
        backgroundColor: const Color(0xFF1B5A6E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'Budget Planner',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetPlannerPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.turquoise,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildFilters()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.turquoise)),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_packages.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PackageCard(
                      package: _packages[i],
                      onTap: () => _showDetails(_packages[i]),
                    ),
                    childCount: _packages.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B5A6E), Color(0xFF2CAFBC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'AI-Curated Packages',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Sasta Tour Packages',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Affordable travel experiences across Pakistan',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetPlannerPage()),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Budget Planner',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Enter your budget → Get a personalized itinerary',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildFilters() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isActive = cat == _activeCategory;
              return GestureDetector(
                onTap: () { setState(() => _activeCategory = cat); _load(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.turquoise : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.turquoise : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    cat == 'all' ? 'All' : cat,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.darkSlate,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Price filter
        Row(
          children: [
            const Text('Max Budget: ', style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
            const SizedBox(width: 4),
            DropdownButton<double?>(
              value: _maxPrice,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: const TextStyle(fontSize: 12, color: AppTheme.darkSlate),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 10000, child: Text('PKR 10,000')),
                DropdownMenuItem(value: 20000, child: Text('PKR 20,000')),
                DropdownMenuItem(value: 35000, child: Text('PKR 35,000')),
                DropdownMenuItem(value: 60000, child: Text('PKR 60,000+')),
              ],
              onChanged: (v) { setState(() => _maxPrice = v); _load(); },
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.mediumGray),
        const SizedBox(height: 12),
        const Text('Could not load packages', style: TextStyle(color: AppTheme.mediumGray)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.luggage_rounded, size: 56, color: AppTheme.mediumGray),
        SizedBox(height: 12),
        Text('No packages found for selected filters', style: TextStyle(color: AppTheme.mediumGray)),
      ],
    ),
  );

  void _showDetails(Map<String, dynamic> pkg) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TourPackageDetailPage(package: pkg)),
    );
  }
}

// ─── Package Card ─────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dests = (package['destinations'] as List?)?.cast<String>() ?? [];
    final includes = (package['includes'] as List?)?.cast<String>() ?? [];
    final price = (package['total_price'] as num?)?.toDouble() ?? 0;
    final days = package['duration_days'] as int? ?? 0;
    final category = package['category'] as String? ?? 'General';

    final catColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor.withValues(alpha: 0.8), catColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(package['title'] as String? ?? 'Package',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dests.join(' → '),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('PKR ${_fmtPrice(price)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('per person', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chip(Icons.calendar_today_rounded, '$days Days', Colors.blue),
                        const SizedBox(width: 8),
                        _chip(Icons.place_rounded, '${dests.length} Stops', Colors.orange),
                        const SizedBox(width: 8),
                        _chip(Icons.label_rounded, category, catColor),
                      ],
                    ),
                    if ((package['description'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(package['description'] as String,
                          style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (includes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: includes.take(3).map((inc) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 10, color: Colors.green),
                              const SizedBox(width: 3),
                              Text(inc, style: const TextStyle(fontSize: 10, color: Colors.green)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.turquoise,
                              side: const BorderSide(color: AppTheme.turquoise),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'nature': return Colors.green.shade600;
      case 'adventure': return Colors.orange.shade700;
      case 'cultural': return Colors.purple.shade600;
      case 'family': return Colors.blue.shade600;
      default: return const Color(0xFF1B5A6E);
    }
  }

  String _fmtPrice(double p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return p.toStringAsFixed(0);
  }
}

// ─── Package Detail Page ──────────────────────────────────────────────────────

class TourPackageDetailPage extends StatelessWidget {
  final Map<String, dynamic> package;
  const TourPackageDetailPage({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final itinerary = (package['itinerary'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final includes = (package['includes'] as List?)?.cast<String>() ?? [];
    final dests = (package['destinations'] as List?)?.cast<String>() ?? [];
    final price = (package['total_price'] as num?)?.toDouble() ?? 0;
    final days = package['duration_days'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1B5A6E),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 14),
              title: Text(package['title'] as String? ?? 'Package',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B4D), Color(0xFF2CAFBC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Text('PKR ${_fmtPrice(price)}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      Text('per person · $days days',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Destinations
                if (dests.isNotEmpty) ...[
                  _sectionTitle('Destinations'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dests.map((d) => Chip(
                      avatar: const Icon(Icons.place_rounded, size: 14, color: AppTheme.turquoise),
                      label: Text(d, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                if ((package['description'] as String? ?? '').isNotEmpty) ...[
                  _sectionTitle('About This Package'),
                  Text(package['description'] as String,
                      style: const TextStyle(fontSize: 13, color: AppTheme.darkSlate, height: 1.5)),
                  const SizedBox(height: 16),
                ],

                // What's included
                if (includes.isNotEmpty) ...[
                  _sectionTitle('What\'s Included'),
                  ...includes.map((inc) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(inc, style: const TextStyle(fontSize: 13, color: AppTheme.darkSlate))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Itinerary
                if (itinerary.isNotEmpty) ...[
                  _sectionTitle('Day-by-Day Itinerary'),
                  ...itinerary.map((day) => _DayCard(day: day)),
                  const SizedBox(height: 16),
                ],

                // Book via budget planner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5A6E), Color(0xFF2CAFBC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Interested in this package?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Use the AI Budget Planner to customize a trip within your budget',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetPlannerPage()),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Customize with AI Budget Planner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5A6E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
  );

  String _fmtPrice(double p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return p.toStringAsFixed(0);
  }
}

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final activities = (day['activities'] as List?)?.cast<String>() ?? [];
    final desc = day['desc'] as String? ?? day['description'] as String? ?? '';
    final transport = day['transport'] as String?;
    final accommodation = day['accommodation'] as String?;
    final cost = day['estimated_cost'] as num?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.turquoise,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day['day'] ?? ''}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day['title'] as String? ?? day['location'] as String? ?? 'Day ${day['day']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate),
                      ),
                    ),
                    if (cost != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'PKR ${cost >= 1000 ? '${(cost / 1000).toStringAsFixed(0)}K' : cost.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
                ],
                if (activities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...activities.map((act) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star_rounded, size: 11, color: AppTheme.turquoise),
                        const SizedBox(width: 4),
                        Expanded(child: Text(act, style: const TextStyle(fontSize: 11, color: AppTheme.darkSlate))),
                      ],
                    ),
                  )),
                ],
                if (accommodation != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.hotel_rounded, size: 11, color: AppTheme.mediumGray),
                    const SizedBox(width: 4),
                    Expanded(child: Text(accommodation, style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray))),
                  ]),
                ],
                if (transport != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.directions_bus_rounded, size: 11, color: AppTheme.mediumGray),
                    const SizedBox(width: 4),
                    Expanded(child: Text(transport, style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray))),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget Planner Page ──────────────────────────────────────────────────────

class BudgetPlannerPage extends StatefulWidget {
  const BudgetPlannerPage({super.key});

  @override
  State<BudgetPlannerPage> createState() => _BudgetPlannerPageState();
}

class _BudgetPlannerPageState extends State<BudgetPlannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _budgetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _prefCtrl = TextEditingController();
  int _travelers = 2;
  int _days = 5;
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _cityCtrl.dispose();
    _prefCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _result = null; });
    try {
      final resp = await ApiService.postRequest(
        '/tours/budget-plan',
        {
          'budget_amount': double.parse(_budgetCtrl.text.replaceAll(',', '')),
          'num_travelers': _travelers,
          'duration_days': _days,
          'start_city': _cityCtrl.text.trim(),
          'preferences': _prefCtrl.text.trim(),
        },
        timeout: const Duration(seconds: 35),
      );
      if (!mounted) return;
      if (resp['success'] != true) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp['message'] as String? ?? 'Failed to generate plan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() { _result = resp; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('AI Budget Planner'),
        backgroundColor: const Color(0xFF1B5A6E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppTheme.turquoise, size: 20),
                        SizedBox(width: 8),
                        Text('Plan Your Dream Trip',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Enter your budget and let AI create a perfect itinerary',
                        style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
                    const SizedBox(height: 20),

                    // Budget
                    _label('Total Budget (PKR)'),
                    TextFormField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('e.g. 25000', Icons.account_balance_wallet_rounded),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your budget';
                        final n = double.tryParse(v.replaceAll(',', ''));
                        if (n == null || n < 1000) return 'Minimum budget is PKR 1,000';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Travelers & Days row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Travelers'),
                              _stepper(_travelers, (v) => setState(() => _travelers = v), 1, 20),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Days'),
                              _stepper(_days, (v) => setState(() => _days = v), 1, 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start city
                    _label('Start City (Optional)'),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: _inputDec('e.g. Lahore', Icons.location_city_rounded),
                    ),
                    const SizedBox(height: 16),

                    // Preferences
                    _label('Preferences (Optional)'),
                    TextFormField(
                      controller: _prefCtrl,
                      decoration: _inputDec('e.g. mountains, culture, food', Icons.interests_rounded),
                    ),
                    const SizedBox(height: 24),

                    // Budget per person preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.turquoise.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.turquoise),
                          const SizedBox(width: 8),
                          ValueListenableBuilder(
                            valueListenable: _budgetCtrl,
                            builder: (_, __, ___) {
                              final total = double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0;
                              final perPerson = _travelers > 0 ? total / _travelers : 0;
                              final perDay = _days > 0 ? perPerson / _days : 0;
                              return Text(
                                'PKR ${perPerson.toStringAsFixed(0)} per person  ·  '
                                'PKR ${perDay.toStringAsFixed(0)}/day',
                                style: const TextStyle(fontSize: 12, color: AppTheme.turquoise, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(_loading ? 'Generating…' : 'Generate My Itinerary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5A6E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 20),
              _BudgetPlanResult(result: _result!),
            ],

            // Matching packages
            if (_result != null && (_result!['matching_packages'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              const Text('Matching Packages',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
              const SizedBox(height: 12),
              ...(_result!['matching_packages'] as List).cast<Map<String, dynamic>>().map(
                (pkg) => _PackageCard(
                  package: pkg,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TourPackageDetailPage(package: pkg)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkSlate)),
  );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: AppTheme.mediumGray),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.turquoise, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _stepper(int value, ValueChanged<int> onChange, int min, int max) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: value > min ? () => onChange(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: value < max ? () => onChange(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ─── Budget Plan Result ───────────────────────────────────────────────────────

class _BudgetPlanResult extends StatelessWidget {
  final Map<String, dynamic> result;
  const _BudgetPlanResult({required this.result});

  String _fmt(dynamic v) {
    if (v == null) return '--';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return v.toString();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final plan = result['budget_plan'] as Map<String, dynamic>? ?? {};
    final itinerary = (plan['itinerary'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tips = (plan['money_saving_tips'] as List?)?.cast<String>() ?? [];
    final included = (plan['included_in_budget'] as List?)?.cast<String>() ?? [];
    final dests = (plan['recommended_destinations'] as List?)?.cast<String>() ?? [];
    final affordableDests = (result['affordable_destinations'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plan header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B5A6E), Color(0xFF2CAFBC)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Your Personalized Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text(plan['title'] as String? ?? 'Budget Travel Plan',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _stat('Total Cost', 'PKR ${_fmt(plan['total_estimated_cost'])}'),
                const SizedBox(width: 16),
                _stat('Daily Budget', 'PKR ${_fmt(plan['daily_budget'])}'),
                const SizedBox(width: 16),
                _stat('Best Season', plan['best_time_to_go'] as String? ?? '--'),
              ]),
            ],
          ),
        ),

        // Recommended destinations (AI-suggested names)
        if (dests.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Recommended Destinations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dests.map((d) => Chip(
              avatar: const Icon(Icons.place_rounded, size: 14, color: AppTheme.turquoise),
              label: Text(d, style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
        ],

        // Affordable destinations with cost breakdown
        if (affordableDests.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Places Within Your Budget',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
          const SizedBox(height: 8),
          ...affordableDests.map((dest) => _DestinationCostCard(dest: dest)),
        ],

        // Itinerary
        if (itinerary.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Day-by-Day Itinerary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
          const SizedBox(height: 8),
          ...itinerary.map((day) => _DayCard(day: day)),
        ],

        // Included
        if (included.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Included in Budget',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: included.map((inc) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_rounded, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(inc, style: const TextStyle(fontSize: 11, color: Colors.green)),
              ]),
            )).toList(),
          ),
        ],

        // Money saving tips
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Money Saving Tips',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
          const SizedBox(height: 8),
          ...tips.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value,
                    style: const TextStyle(fontSize: 12, color: AppTheme.darkSlate, height: 1.4))),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    ],
  );
}

// ─── Destination Cost Card ────────────────────────────────────────────────────

class _DestinationCostCard extends StatelessWidget {
  final Map<String, dynamic> dest;
  const _DestinationCostCard({required this.dest});

  @override
  Widget build(BuildContext context) {
    final name = dest['name'] as String? ?? 'Unknown';
    final city = dest['city'] as String? ?? '';
    final category = dest['category'] as String? ?? '';
    final avgCost = (dest['average_cost'] as num?)?.toDouble();
    final description = dest['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.turquoise.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: AppTheme.turquoise, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkSlate)),
                if (city.isNotEmpty)
                  Text(city, style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray)),
                if (description.isNotEmpty)
                  Text(description,
                      style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (category.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.turquoise.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(category, style: const TextStyle(fontSize: 10, color: AppTheme.turquoise, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (avgCost != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${avgCost >= 1000 ? '${(avgCost / 1000).toStringAsFixed(0)}K' : avgCost.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5A6E)),
                ),
                const Text('avg/day', style: TextStyle(fontSize: 10, color: AppTheme.mediumGray)),
              ],
            ),
        ],
      ),
    );
  }
}
