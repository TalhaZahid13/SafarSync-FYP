import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'group_live_tracking_page.dart';
import 'group_invitations_page.dart';

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _groupStatusColor(String? s) {
  switch (s) {
    case 'Open': return Colors.blue;
    case 'Full': return Colors.amber;
    case 'Active': return Colors.teal;
    case 'Completed': return Colors.grey;
    case 'Cancelled': return Colors.red;
    default: return Colors.indigo;
  }
}

// ─── GroupBookingsPage ────────────────────────────────────────────────────────

class GroupBookingsPage extends StatefulWidget {
  const GroupBookingsPage({super.key});

  @override
  State<GroupBookingsPage> createState() => _GroupBookingsPageState();
}

class _GroupBookingsPageState extends State<GroupBookingsPage> {
  List<dynamic> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getRequest('/group-bookings/list');
      if (mounted && r['success'] == true) {
        setState(() {
          _groups = r['group_bookings'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinByIdDialog() async {
    final controller = TextEditingController();
    final groupId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group Trip'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Group ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Join')),
        ],
      ),
    );
    if (groupId == null || groupId.isEmpty) return;

    try {
      final r = await ApiService.postRequest('/group-bookings/$groupId/join', {});
      if (!mounted) return;
      _snack(
        r['success'] == true
            ? r['message'] as String? ?? 'Joined group'
            : r['error'] as String? ?? 'Failed to join',
        success: r['success'] == true,
      );
      if (r['success'] == true) _load();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Join by ID',
            onPressed: _joinByIdDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Group',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateGroupBookingScreen()),
            ).then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (_, i) {
                      final g = _groups[i];
                      return _GroupCard(
                        group: g,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupBookingDetailsScreen(
                              groupBookingId: g['group_booking_id'] as int,
                            ),
                          ),
                        ).then((_) => _load()),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No group trips yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateGroupBookingScreen()),
              ).then((_) => _load()),
              child: const Text('Create Group Trip'),
            ),
          ],
        ),
      );
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = group['status'] as String? ?? 'Planning';
    final color = _groupStatusColor(status);
    final members = group['member_count'] as int? ?? 0;
    final maxMembers = group['max_members'] as int? ?? 20;
    final myRole = group['my_role'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group['trip_name'] as String? ?? 'Unknown Trip',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14,
                      color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$members / $maxMembers members',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  if (myRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: myRole == 'organizer'
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        myRole == 'organizer' ? 'Organizer' : 'Member',
                        style: TextStyle(
                          fontSize: 10,
                          color: myRole == 'organizer'
                              ? Colors.amber[800]
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CreateGroupBookingScreen ─────────────────────────────────────────────────

class CreateGroupBookingScreen extends StatefulWidget {
  const CreateGroupBookingScreen({super.key});

  @override
  State<CreateGroupBookingScreen> createState() =>
      _CreateGroupBookingScreenState();
}

class _CreateGroupBookingScreenState extends State<CreateGroupBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tripName = '';
  String _description = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int _maxMembers = 10;
  int? _destinationId;
  List<dynamic> _destinations = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final r = await ApiService.getDestinations();
      if (mounted && r['success'] == true) {
        setState(() => _destinations = r['destinations'] as List? ?? []);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _submitting = true);
    try {
      final r = await ApiService.postRequest('/group-bookings/create', {
        'trip_name': _tripName,
        'description': _description,
        'start_date': _startDate != null
            ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
            : null,
        'end_date': _endDate != null
            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
            : null,
        'max_members': _maxMembers,
        if (_destinationId != null) 'destination_id': _destinationId,
      });

      if (!mounted) return;
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Group trip created! You are the organizer.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['error'] as String? ?? 'Error')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group Trip')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: _dec('Trip Name', Icons.hiking),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Trip name is required' : null,
                onSaved: (v) => _tripName = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _dec('Description', Icons.notes),
                maxLines: 3,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 16),
              if (_destinations.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _destinationId,
                  decoration: _dec('Destination (optional)', Icons.place),
                  items: _destinations
                      .map((d) => DropdownMenuItem<int>(
                            value: d['destination_id'] as int,
                            child: Text(d['name'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _destinationId = v),
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '10',
                keyboardType: TextInputType.number,
                decoration: _dec('Max Members', Icons.people),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2) return 'Min 2 members';
                  if (n > 100) return 'Max 100 members';
                  return null;
                },
                onChanged: (v) =>
                    setState(() => _maxMembers = int.tryParse(v) ?? 10),
                onSaved: (v) => _maxMembers = int.tryParse(v ?? '10') ?? 10,
              ),
              const SizedBox(height: 16),
              _DatePicker(
                label: 'Start Date',
                value: _startDate,
                firstDate: DateTime.now(),
                onPicked: (d) => setState(() => _startDate = d),
              ),
              const SizedBox(height: 16),
              _DatePicker(
                label: 'End Date',
                value: _endDate,
                firstDate: _startDate ?? DateTime.now(),
                onPicked: (d) => setState(() => _endDate = d),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Trip', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GroupBookingDetailsScreen ────────────────────────────────────────────────

class GroupBookingDetailsScreen extends StatefulWidget {
  final int groupBookingId;
  const GroupBookingDetailsScreen({super.key, required this.groupBookingId});

  @override
  State<GroupBookingDetailsScreen> createState() =>
      _GroupBookingDetailsScreenState();
}

class _GroupBookingDetailsScreenState
    extends State<GroupBookingDetailsScreen> {
  Map<String, dynamic>? _gb;
  bool _loading = true;
  bool _isOrganizer = false;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _load();
  }

  Future<void> _loadUserId() async {
    final id = await ApiService.getMySqlUserId();
    if (mounted) setState(() => _myUserId = id);
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getRequest(
          '/group-bookings/${widget.groupBookingId}');
      if (mounted && r['success'] == true) {
        final gb = r['group_booking'] as Map<String, dynamic>;
        final members = gb['members'] as List? ?? [];
        final myRole = members
            .where((m) =>
                m['user_id'] == _myUserId ||
                (gb['created_by'] is int &&
                    gb['created_by'] == _myUserId))
            .map((m) => m['role'] as String?)
            .firstWhere((r) => r != null, orElse: () => null);
        setState(() {
          _gb = gb;
          _isOrganizer = myRole == 'organizer' ||
              gb['created_by'] == _myUserId;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startTracking() async {
    try {
      await ApiService.postRequest('/group-bookings/tracking/start',
          {'group_booking_id': widget.groupBookingId});
    } catch (_) {}
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupLiveTrackingPage(
            groupBookingId: widget.groupBookingId),
      ),
    );
  }

  Future<void> _inviteDialog() async {
    final emailCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of the SafarSync user to invite.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Invite')),
        ],
      ),
    );
    if (confirmed != true) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;

    try {
      final r = await ApiService.postRequest('/invitations/send', {
        'group_booking_id': widget.groupBookingId,
        'receiver_email': email,
      });
      if (!mounted) return;
      _snack(
        r['success'] == true
            ? r['message'] as String? ?? 'Invitation sent'
            : r['error'] as String? ?? 'Failed to send',
        success: r['success'] == true,
      );
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _removeMember(int userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Remove this member from the group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final r = await ApiService.deleteRequest(
          '/group-bookings/${widget.groupBookingId}/members/$userId');
      if (!mounted) return;
      _snack(
        r['success'] == true ? 'Member removed' : r['error'] as String? ?? 'Error',
        success: r['success'] == true,
      );
      if (r['success'] == true) _load();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _closeGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Group'),
        content: const Text('This will cancel the group trip. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Group',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final r = await ApiService.postRequest(
          '/group-bookings/${widget.groupBookingId}/close', {});
      if (!mounted) return;
      _snack(
        r['success'] == true ? 'Group closed' : r['error'] as String? ?? 'Error',
        success: r['success'] == true,
      );
      if (r['success'] == true) _load();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_gb == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final gb = _gb!;
    final status = gb['status'] as String? ?? 'Planning';
    final members = gb['members'] as List? ?? [];
    final maxMembers = gb['max_members'] as int? ?? 20;
    final color = _groupStatusColor(status);
    final canClose = _isOrganizer &&
        !['Completed', 'Cancelled'].contains(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Invite',
            onPressed: _inviteDialog,
          ),
          if (canClose)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close Group',
              onPressed: _closeGroup,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gb['trip_name'] as String? ?? 'Unknown Trip',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text('${members.length}/$maxMembers members',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              if (gb['destination_name'] != null)
                _infoRow(Icons.place, gb['destination_name'] as String),
              if (gb['start_date'] != null)
                _infoRow(Icons.calendar_today,
                    '${gb['start_date']} – ${gb['end_date'] ?? '?'}'),
              if (gb['description'] != null &&
                  (gb['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(gb['description'] as String,
                    style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Members',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Invite'),
                    onPressed: _inviteDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...members.map((m) => _MemberTile(
                    member: m as Map<String, dynamic>,
                    isOrganizer: _isOrganizer,
                    isMe: m['user_id'] == _myUserId,
                    onRemove: () =>
                        _removeMember(m['user_id'] as int),
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startTracking,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Live Tracking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GroupInvitationsPage()),
                    ),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Invitations'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isOrganizer;
  final bool isMe;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.isOrganizer,
    required this.isMe,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final role = member['role'] as String? ?? 'member';
    final isOrganizerMember = role == 'organizer';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: CircleAvatar(
        backgroundImage: member['profile_picture_url'] != null
            ? NetworkImage(member['profile_picture_url'] as String)
            : null,
        child: member['profile_picture_url'] == null
            ? Text((member['full_name'] as String? ?? 'U')[0].toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Text(member['full_name'] as String? ?? 'Unknown'),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('You',
                  style: TextStyle(fontSize: 10, color: Colors.blue)),
            ),
          if (isOrganizerMember)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Organizer',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Text(member['email'] as String? ?? '',
          style: const TextStyle(fontSize: 12)),
      trailing: isOrganizer && !isMe && !isOrganizerMember
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 20),
              tooltip: 'Remove member',
              onPressed: onRemove,
            )
          : null,
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final ValueChanged<DateTime> onPicked;

  const _DatePicker({
    required this.label,
    this.value,
    required this.firstDate,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: value != null
              ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
              : '',
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? firstDate,
            firstDate: firstDate,
            lastDate: DateTime.now().add(const Duration(days: 730)),
          );
          if (picked != null) onPicked(picked);
        },
      );
}
