import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class GroupInvitationsPage extends StatefulWidget {
  const GroupInvitationsPage({super.key});

  @override
  State<GroupInvitationsPage> createState() => _GroupInvitationsPageState();
}

class _GroupInvitationsPageState extends State<GroupInvitationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> received = [];
  List<dynamic> sent = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiService.getRequest('/invitations/received'),
        ApiService.getRequest('/invitations/sent'),
      ]);
      if (mounted) {
        setState(() {
          received = results[0]['invitations'] as List<dynamic>? ?? [];
          sent = results[1]['invitations'] as List<dynamic>? ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _respond(int invitationId, String status) async {
    try {
      final response = await ApiService.putRequest(
        '/invitations/$invitationId/respond',
        {'status': status},
      );
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation $status'),
            backgroundColor: status == 'Accepted' ? Colors.green : Colors.grey,
          ),
        );
        _loadAll();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Invitations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Received'),
                  if (received.any((i) => i['status'] == 'Pending')) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        received
                            .where((i) => i['status'] == 'Pending')
                            .length
                            .toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sent'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ReceivedTab(invitations: received, onRespond: _respond),
                _SentTab(invitations: sent),
              ],
            ),
    );
  }
}

class _ReceivedTab extends StatelessWidget {
  final List<dynamic> invitations;
  final Future<void> Function(int, String) onRespond;

  const _ReceivedTab({required this.invitations, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No invitations received'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final inv = invitations[index] as Map<String, dynamic>;
        final status = inv['status'] as String? ?? 'Pending';
        final isPending = status == 'Pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        (inv['sender_name'] as String? ?? '?')[0].toUpperCase(),
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv['trip_name'] as String? ?? 'Unknown Trip',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'From: ${inv['sender_name'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                if (inv['description'] != null &&
                    (inv['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    inv['description'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Invited ${_formatDate(inv['created_at'] as String?)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              onRespond(inv['id'] as int, 'Declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              onRespond(inv['id'] as int, 'Accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _SentTab extends StatelessWidget {
  final List<dynamic> invitations;

  const _SentTab({required this.invitations});

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No invitations sent yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final inv = invitations[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                (inv['receiver_name'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Colors.purple.shade700),
              ),
            ),
            title: Text(inv['trip_name'] as String? ?? 'Unknown Trip'),
            subtitle: Text(
              'To: ${inv['receiver_name'] ?? inv['receiver_email'] ?? 'Unknown'}',
            ),
            trailing: _StatusChip(
              status: inv['status'] as String? ?? 'Pending',
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Accepted':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'Declined':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
