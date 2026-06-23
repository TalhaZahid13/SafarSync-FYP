# Integration Guide - Add New Screens to Flutter App

## Step 1: Update imports in your main home screen file

Find your main home/dashboard file (likely `lib/frontend/src/pages/home_page.dart` or similar) and add these imports at the top:

```dart
import 'smart_dashboard_page.dart';
import 'groups_page.dart';
import 'wellness_page.dart';
```

## Step 2: Add tabs to TabBar

Find where you define your `TabBar` and add these three tabs:

```dart
TabBar(
  tabs: [
    // ... your existing tabs ...
    Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
    Tab(icon: Icon(Icons.group), text: 'Groups'),
    Tab(icon: Icon(Icons.favorite), text: 'Wellness'),
  ],
)
```

## Step 3: Add page views to TabBarView

Find where you define your `TabBarView` children and add these three views:

```dart
TabBarView(
  children: [
    // ... your existing pages ...
    SmartDashboardPage(),
    GroupsPage(),
    WellnessPage(),
  ],
)
```

## Complete Example

Here's a minimal example of how your home screen should look:

```dart
import 'package:flutter/material.dart';
import 'smart_dashboard_page.dart';
import 'groups_page.dart';
import 'wellness_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Adjust length if you have more tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SafarSync'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            // ... your existing tabs ...
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.group), text: 'Groups'),
            Tab(icon: Icon(Icons.favorite), text: 'Wellness'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ... your existing pages ...
          SmartDashboardPage(),
          GroupsPage(),
          WellnessPage(),
        ],
      ),
    );
  }
}
```

## Database Tables - Manual Creation

Before running the Flutter app, create these tables in MySQL:

```bash
# Open MySQL
mysql -u root -p

# Select database
USE safarsync;

# Create groups table
CREATE TABLE IF NOT EXISTS groups (
  group_id INT AUTO_INCREMENT PRIMARY KEY,
  group_name VARCHAR(255) NOT NULL,
  created_by_id INT NOT NULL,
  invite_code VARCHAR(20) UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_created_by (created_by_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# Create group_members table
CREATE TABLE IF NOT EXISTS group_members (
  member_id INT AUTO_INCREMENT PRIMARY KEY,
  group_id INT NOT NULL,
  user_id INT NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY unique_group_user (group_id, user_id),
  INDEX idx_group_id (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# Create sos_alerts table
CREATE TABLE IF NOT EXISTS sos_alerts (
  alert_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  status ENUM('Active', 'Resolved') DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Admin Dashboard Access

Open the admin dashboard in your browser:

```
file:///C:/Users/user/Desktop/SafarSync-FYP/admin/dashboard.html
```

The dashboard will:
- Auto-refresh every 10 seconds
- Show live user count
- Show group statistics
- Display active SOS alerts
- Show system health status

## Testing the Features

### Test Smart Dashboard
1. Tap the "Dashboard" tab
2. You should see:
   - Weather display (☀️ Sunny, 22°C)
   - Safety Status (Risk: LOW, Score: 25/100)
   - Group Members (A, F, M avatars)
   - AI Travel Tip
   - Quick action buttons
3. Tap "SOS" button
4. Confirm emergency alert
5. See success message: "✓ SOS ACTIVATED"

### Test Groups
1. Tap the "Groups" tab
2. You should see pre-populated demo groups
3. Tap "+" button to create new group
4. Enter group name
5. Get randomly generated invite code
6. Tap group to view details
7. Enter code in "Join with code" field
8. Successfully join group

### Test Wellness
1. Tap the "Wellness" tab
2. Select a mood option (e.g., "😟 I'm feeling anxious")
3. See supportive response from AI
4. Type your own message
5. Get supportive response
6. Continue conversation

### Test Admin Dashboard
1. Open `admin/dashboard.html` in browser
2. See live statistics
3. Watch auto-refresh every 10 seconds
4. Navigate to see all sections

## Troubleshooting

**Pages not showing up?**
- Make sure imports are at the top of the file
- Check that the class names match exactly

**Errors about "ApiService"?**
- All API dependencies have been removed from the new screens
- They use mock data for the demo

**Admin dashboard not showing stats?**
- Make sure backend is running (`npm start` in lib/backend)
- Dashboard auto-refreshes, just wait or click refresh button

**SOS button not working?**
- It's a demo - just shows confirmation dialog
- For real functionality, backend needs to be connected to MySQL

## That's it! 🎉

Your SafarSync app now has:
✅ Smart Travel Dashboard
✅ Group Management
✅ Wellness Support
✅ Admin Dashboard
✅ Emergency SOS
✅ All features demo-ready
