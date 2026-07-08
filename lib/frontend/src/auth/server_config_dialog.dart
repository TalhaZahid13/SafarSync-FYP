
import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  String? _error;

  static const _emulatorUrl   = 'http://10.0.2.2:5000';
  static const _localhostUrl  = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    final display = ApiService.isServerConfigured ? ApiService.serverHost : '';
    _ctrl = TextEditingController(text: display);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _usePreset(String base) {
    _ctrl.text = base;
    setState(() => _error = null);
  }

  Future<void> _save() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'URL cannot be empty');
      return;
    }
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      setState(() => _error = 'Must start with http:// or https://');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await ApiService.setServerUrl(raw);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server set to: ${ApiService.baseUrl}')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_ethernet, size: 20),
          SizedBox(width: 8),
          Text('Server Configuration'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick presets
            Text('Quick Presets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 6),
            Row(
              children: [
                _PresetChip(label: 'Emulator', onTap: () => _usePreset(_emulatorUrl)),
                const SizedBox(width: 8),
                _PresetChip(label: 'Localhost', onTap: () => _usePreset(_localhostUrl)),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Enter your backend server address.\n'
              '• Android emulator → http://10.0.2.2:5000\n'
              '• Real device (same WiFi) → http://YOUR_PC_IP:5000\n'
              '  Find your PC IP: run ipconfig (Windows) or ifconfig (Mac/Linux)',
              style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color, height: 1.5),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://192.168.x.x:5000',
                border: const OutlineInputBorder(),
                errorText: _error,
                prefixIcon: const Icon(Icons.link, size: 18),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save & Connect'),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
