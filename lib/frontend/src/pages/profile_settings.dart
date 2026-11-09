import 'dart:io';
import '../utils/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/api_service.dart';
import '../utils/theme_controller.dart';
import '../ui/destination_theme.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String? _currentPhotoUrl;
  bool _photoChanged = false;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  static const _bloodGroups = [
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
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      // Try backend first for full profile data
      final r = await ApiService.getRequest('/users/profile');
      if (r['success'] == true) {
        final u = r['user'] as Map<String, dynamic>;
        _nameCtrl.text = u['full_name'] as String? ?? '';
        _emailCtrl.text = u['email'] as String? ?? '';
        _phoneCtrl.text = u['phone_number'] as String? ?? '';
        _cityCtrl.text = u['city'] as String? ?? '';
        _bioCtrl.text = u['bio'] as String? ?? '';
        _currentPhotoUrl = u['profile_picture_url'] as String?;
        final bg = u['blood_group'] as String?;
        if (bg != null && _bloodGroups.contains(bg)) _selectedBloodGroup = bg;
      } else {
        // Fall back to the signed-in auth profile
        final fu = AppAuth.currentUser;
        _nameCtrl.text = fu?.displayName ?? '';
        _emailCtrl.text = fu?.email ?? '';
        _currentPhotoUrl = fu?.photoURL;
      }
    } catch (_) {
      final fu = AppAuth.currentUser;
      _nameCtrl.text = fu?.displayName ?? '';
      _emailCtrl.text = fu?.email ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage — this already persists
      // profile_picture_url to the DB immediately, independent of Save.
      final r = await ApiService.uploadProfilePhoto(bytes, picked.name);
      if (r['success'] == true && r['url'] != null) {
        setState(() {
          _currentPhotoUrl = r['url'] as String;
          _photoChanged = true;
        });
        await AppAuth.updateProfile(photoURL: _currentPhotoUrl);
        _snack('Photo updated', success: true);
      } else {
        _snack(r['message'] as String? ?? 'Upload failed');
      }
    } catch (e) {
      _snack('Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);

    try {
      final body = <String, dynamic>{
        if (_nameCtrl.text.trim().isNotEmpty)
          'full_name': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone_number': _phoneCtrl.text.trim(),
        if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
        'blood_group': _selectedBloodGroup,
        if (_currentPhotoUrl != null) 'profile_picture_url': _currentPhotoUrl,
      };

      final r = await ApiService.putRequest('/users/profile', body);
      if (!mounted) return;

      if (r['success'] == true) {
        // Keep the auth profile (greeting/avatar) in sync with the saved row.
        await AppAuth.updateProfile(
          displayName: _nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : null,
          photoURL: _currentPhotoUrl,
        );
        _snack('Profile saved', success: true);
        // Pop with `true` so the caller knows to refresh its own copy of
        // the profile (name/city/photo) instead of showing stale data.
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack(
          r['error'] as String? ?? r['message'] as String? ?? 'Save failed',
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          // The photo upload persists immediately (independent of Save), so
          // even leaving via back without saving other fields should still
          // tell the caller to refresh if the picture changed.
          onPressed: () => Navigator.pop(context, _photoChanged),
        ),
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Profile Photo ────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cs.secondary, cs.primary],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: _uploadingPhoto
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : _currentPhotoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _currentPhotoUrl!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (ctx2, err, stack) => Icon(
                                        LucideIcons.user,
                                        size: 48,
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    LucideIcons.user,
                                    size: 48,
                                    color: cs.onPrimary,
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Text(
                        'Change Photo',
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildThemeSelector(context),
              _buildJourneyThemeSelector(context),
              const SizedBox(height: 16),

              // ─── Form Fields ──────────────────────────────────────────
              _inputField(
                'Full Name',
                _nameCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              _inputField('Email', _emailCtrl, readOnly: true),
              _inputField(
                'Contact Number',
                _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              _inputField('City', _cityCtrl),
              _inputField('Bio', _bioCtrl, maxLines: 2),
              _buildBloodGroupDropdown(theme),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
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
                icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
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
                onChanged: (v) {
                  if (v != null) themeController.setThemeMode(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyThemeSelector(BuildContext context) {
    final dtProvider = context.watch<DestinationThemeProvider>();
    final theme = Theme.of(context);
    final currentValue = dtProvider.isManual ? dtProvider.activeType : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Journey Theme',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: dtProvider.activeTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dtProvider.activeTheme.emoji,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-adapts based on your active booking destination',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          _ThemeOptionRow(
            label: 'Auto (from booking)',
            emoji: '✨',
            isSelected: !dtProvider.isManual,
            color: const Color(0xFF2CAFBC),
            onTap: () => dtProvider.resetToAuto(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 3.5,
            children: DestinationTheme.all.map((dt) {
              final isSelected = dtProvider.isManual && currentValue == dt.type;
              return _ThemeOptionRow(
                label: dt.label,
                emoji: dt.emoji,
                isSelected: isSelected,
                color: dt.primary,
                onTap: () => dtProvider.setManualTheme(dt.type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
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
            maxLines: maxLines,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            keyboardType: keyboardType,
            validator: validator,
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

  Widget _buildBloodGroupDropdown(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Group',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
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
              child: DropdownButton<String>(
                value: _selectedBloodGroup,
                dropdownColor: theme.cardColor,
                icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                isExpanded: true,
                items: _bloodGroups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedBloodGroup = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Journey theme option chip ────────────────────────────────────────────────

class _ThemeOptionRow extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ThemeOptionRow({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? color
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
