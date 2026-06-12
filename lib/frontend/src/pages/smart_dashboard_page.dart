import 'package:flutter/material.dart';

class SmartDashboardPage extends StatefulWidget {
  final int? tripId;

  const SmartDashboardPage({this.tripId});

  @override
  State<SmartDashboardPage> createState() => _SmartDashboardPageState();
}

class _SmartDashboardPageState extends State<SmartDashboardPage> {
  Map<String, dynamic> dashboardData = {
    'weather': {'temp': 22, 'condition': 'Sunny', 'icon': '☀️'},
    'trip': {'name': 'Hunza Valley Adventure', 'status': 'Active'},
    'members': 3,
    'safety_score': 25,
    'ai_tip': 'Stay hydrated - high altitude warning'
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Header
            Card(
              elevation: 0,
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboardData['trip']['name'] ?? 'Trip',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Chip(
                      label: Text(dashboardData['trip']['status'] ?? 'Planned'),
                      backgroundColor: Colors.green[200],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Weather Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dashboardData['weather']['icon']} ${dashboardData['weather']['condition'] ?? 'Sunny'}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${dashboardData['weather']['temp'] ?? 22}°C',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Icon(Icons.cloud, size: 48, color: Colors.blue),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Safety Status
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Safety Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(Icons.shield, color: Colors.green, size: 28),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Risk Level: LOW',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Score: ${dashboardData['safety_score'] ?? 25}/100',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Group Members
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Members (${dashboardData['members'] ?? 3})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMemberAvatar('A', Colors.blue),
                        SizedBox(width: 8),
                        _buildMemberAvatar('F', Colors.pink),
                        SizedBox(width: 8),
                        _buildMemberAvatar('M', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // AI Tip
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'AI Travel Tip',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(dashboardData['ai_tip'] ?? 'Stay safe during your journey'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text('Ask AI'),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text('Live Map'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.favorite),
                    label: Text('Wellness'),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.emergency_share, color: Colors.white),
                    label: Text('SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _showSOS(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(String initial, Color color) {
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  _showSOS() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🚨 Emergency SOS', style: TextStyle(color: Colors.red)),
        content: Text('Activate emergency alert to all contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('✓ SOS ACTIVATED', style: TextStyle(color: Colors.green)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('Emergency contacts notified\nHelp is on the way'),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: Text('YES, ACTIVATE'),
          ),
        ],
      ),
    );
  }
}
