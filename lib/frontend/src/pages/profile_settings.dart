import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/theme_controller.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;

  String selectedBloodGroup = 'O+';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _cityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _nameCtrl.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameCtrl.text.trim());
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save — please try again')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.secondary, colorScheme.primary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.user,
                      size: 48,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // TODO: change avatar
                    },
                    child: Text(
                      'Change Photo',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildThemeSelector(context),

            const SizedBox(height: 24),

            // Form Fields
            _inputField('Full Name', _nameCtrl),
            _inputField('Email', _emailCtrl, readOnly: true),
            _inputField('Contact Number', _phoneCtrl,
                keyboardType: TextInputType.phone),
            _inputField('City', _cityCtrl),
            _buildBloodGroupDropdown(),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: themeController.themeMode,
                dropdownColor: theme.cardColor,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  themeController.setThemeMode(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generic text field for most profile inputs
  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Special field: Blood Group with dropdown
  Widget _buildBloodGroupDropdown() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blood Group', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBloodGroup,
                dropdownColor: theme.cardColor,
                icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                isExpanded: true,
                items: bloodGroups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
