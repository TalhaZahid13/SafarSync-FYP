import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'group_live_tracking_page.dart';
import 'group_invitations_page.dart';

class GroupBookingsPage extends StatefulWidget {
  const GroupBookingsPage({super.key});

  @override
  State<GroupBookingsPage> createState() => _GroupBookingsPageState();
}

class _GroupBookingsPageState extends State<GroupBookingsPage> {
  List<dynamic> groupBookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupBookings();
  }

  Future<void> _loadGroupBookings() async {
    try {
      final response = await ApiService.getRequest('/group-bookings/list');
      if (mounted && response['success'] == true) {
        setState(() {
          groupBookings = response['group_bookings'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group bookings: $e')),
        );
      }
    }
  }

  Future<void> _showJoinGroupDialog() async {
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
            hintText: 'Enter the group booking ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (groupId == null || groupId.isEmpty) return;

    try {
      final response = await ApiService.postRequest(
        '/group-bookings/$groupId/join',
        {},
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group successfully')),
        );
        _loadGroupBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to join group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Join Group',
            onPressed: _showJoinGroupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupBookingScreen()),
              ).then((_) => _loadGroupBookings());
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : groupBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No group trips yet'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateGroupBookingScreen(),
                            ),
                          ).then((_) => _loadGroupBookings());
                        },
                        child: const Text('Create Group Trip'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupBookings.length,
                  itemBuilder: (context, index) {
                    final gb = groupBookings[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupBookingDetailsScreen(
                              groupBookingId: gb['group_booking_id'] as int,
                            ),
                          ),
                        ).then((_) => _loadGroupBookings());
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gb['trip_name'] as String? ?? 'Unknown Trip',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(gb['status'] as String? ?? 'Planning'),
                                    backgroundColor: _getStatusColor(gb['status'] as String?),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.group, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${gb['member_count'] ?? 0} members'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Planning':
        return Colors.blue.withValues(alpha: 0.3);
      case 'Active':
        return Colors.green.withValues(alpha: 0.3);
      case 'Completed':
        return Colors.grey.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }
}

class CreateGroupBookingScreen extends StatefulWidget {
  const CreateGroupBookingScreen({super.key});

  @override
  State<CreateGroupBookingScreen> createState() => _CreateGroupBookingScreenState();
}

class _CreateGroupBookingScreenState extends State<CreateGroupBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String tripName = '';
  String description = '';
  DateTime? startDate;
  DateTime? endDate;
  bool loading = false;

  Future<void> _createGroupBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => loading = true);
    try {
      final response = await ApiService.postRequest('/group-bookings/create', {
        'trip_name': tripName,
        'description': description,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
      });

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group trip created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

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
                decoration: InputDecoration(
                  labelText: 'Trip Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'e.g., Northern Areas Trip',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Trip name is required' : null,
                onSaved: (value) => tripName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
                onSaved: (value) => description = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: startDate?.toLocal().toString().split(' ')[0] ?? '',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: endDate?.toLocal().toString().split(' ')[0] ?? '',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _createGroupBooking,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupBookingDetailsScreen extends StatefulWidget {
  final int groupBookingId;

  const GroupBookingDetailsScreen({super.key, required this.groupBookingId});

  @override
  State<GroupBookingDetailsScreen> createState() => _GroupBookingDetailsScreenState();
}

class _GroupBookingDetailsScreenState extends State<GroupBookingDetailsScreen> {
  Map<String, dynamic>? groupBooking;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupBooking();
  }

  Future<void> _loadGroupBooking() async {
    try {
      final response = await ApiService
          .getRequest('/group-bookings/${widget.groupBookingId}');
      if (mounted && response['success'] == true) {
        setState(() {
          groupBooking = response['group_booking'] as Map<String, dynamic>?;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _startTracking() async {
    try {
      await ApiService.postRequest(
        '/group-bookings/tracking/start',
        {'group_booking_id': widget.groupBookingId},
      );
    } catch (_) {
      // Ignore — session may already exist; proceed to tracking screen
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupLiveTrackingPage(groupBookingId: widget.groupBookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (groupBooking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final gb = groupBooking!;
    final members = gb['members'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Invite Member',
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gb['trip_name'] as String? ?? 'Unknown Trip',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(gb['status'] as String? ?? 'Planning'),
                  backgroundColor: _getStatusColor(gb['status'] as String?),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.group, size: 16),
                  label: Text('${members.length} members'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (gb['description'] != null &&
                (gb['description'] as String).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(gb['description'] as String),
                  const SizedBox(height: 16),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Members',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Invite'),
                  onPressed: _showInviteDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member['profile_picture_url'] != null
                        ? NetworkImage(member['profile_picture_url'])
                        : null,
                    child: member['profile_picture_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(member['full_name'] ?? 'Unknown'),
                  subtitle: Text(member['email'] ?? ''),
                  trailing: const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                );
              },
            ),
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
    );
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email address of the SafarSync user you want to invite.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'ahmed@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      final response = await ApiService.postRequest('/invitations/send', {
        'group_booking_id': widget.groupBookingId,
        'receiver_email': email,
      });
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Invitation sent'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to send invitation')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Planning':
        return Colors.blue.withValues(alpha: 0.3);
      case 'Active':
        return Colors.green.withValues(alpha: 0.3);
      case 'Completed':
        return Colors.grey.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }
}

