import 'package:flutter/material.dart';

class GroupsPage extends StatefulWidget {
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<dynamic> groups = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  _loadGroups() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      groups = [
        {'group_id': 1, 'group_name': 'Hunza Valley Explorers', 'invite_code': 'HVE2024'},
        {'group_id': 2, 'group_name': 'Mountain Trekkers', 'invite_code': 'MTK2024'},
      ];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No groups yet'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Create First Group'),
                        onPressed: _showCreateDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (ctx, i) => GroupCard(
                    group: groups[i],
                    onTap: _showGroupDetails,
                  ),
                ),
    );
  }

  _showCreateDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Group'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;

              final inviteCode = 'GRP${DateTime.now().millisecondsSinceEpoch % 10000}'.toUpperCase();
              Navigator.pop(ctx);

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('✓ Group Created'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group: ${nameController.text}'),
                      SizedBox(height: 16),
                      Text('Share this invite code with friends:'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          inviteCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadGroups();
                      },
                      child: Text('Done'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  _showGroupDetails(group) {
    final inviteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group['group_name'] ?? 'Group',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Text('Invite Code:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                group['invite_code'] ?? 'N/A',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: inviteController,
              decoration: InputDecoration(
                labelText: 'Join with code',
                hintText: 'Enter invite code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (inviteController.text.isEmpty) return;

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Joined group!')),
                  );
                  _loadGroups();
                },
                child: Text('Join Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final group;
  final Function onTap;

  GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.group, color: Colors.blue),
        title: Text(group['group_name'] ?? 'Group'),
        subtitle: Text('Code: ${group['invite_code'] ?? 'N/A'}'),
        trailing: Icon(Icons.arrow_forward),
        onTap: () => onTap(group),
      ),
    );
  }
}
