import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService.getRequest('/emergency-contacts');
      if (!mounted) return;
      final raw = resp['contacts'] as List? ?? [];
      setState(() {
        _contacts = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int contactId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Remove this emergency contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final c = _contacts[index];
      await ApiService.deleteRequest('/emergency-contacts/${c['contact_id']}');
      if (!mounted) return;
      setState(() => _contacts.removeAt(index));
    } catch (_) {}
  }

  void _openForm({Map<String, dynamic>? contact, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactForm(
        initial: contact,
        onSaved: (data) async {
          try {
            if (contact == null) {
              // Create
              final resp = await ApiService.postRequest('/emergency-contacts', data);
              if (!mounted) return;
              if (resp['success'] == true) _load();
            } else {
              // Update
              await ApiService.putRequest('/emergency-contacts/${contact['contact_id']}', data);
              if (!mounted) return;
              _load();
            }
          } catch (_) {}
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF3E0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'When you trigger an SOS, emails are sent automatically to contacts that have an email address.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? _EmptyState(onAdd: () => _openForm())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _contacts.length,
                          itemBuilder: (_, i) {
                            final c = _contacts[i];
                            return _ContactTile(
                              contact: c,
                              onEdit: () => _openForm(contact: c, index: i),
                              onDelete: () => _delete(c['contact_id'] as int, i),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = contact['contact_name'] as String? ?? 'Unknown';
    final phone = contact['contact_phone'] as String? ?? '';
    final email = contact['contact_email'] as String?;
    final relationship = contact['relationship'] as String?;
    final isPrimary = contact['is_primary'] == 1 || contact['is_primary'] == true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPrimary ? const Color(0xFFE53935) : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPrimary ? const Color(0xFFB71C1C) : Colors.blueGrey.shade100,
          foregroundColor: isPrimary ? Colors.white : Colors.blueGrey.shade700,
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(phone, style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.email, size: 13, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Flexible(child: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)))),
                ],
              ),
            ] else ...[
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.email_outlined, size: 13, color: Colors.orange),
                  SizedBox(width: 4),
                  Text('No email — SOS email won\'t be sent', style: TextStyle(fontSize: 11, color: Colors.orange)),
                ],
              ),
            ],
            if (relationship != null && relationship.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(relationship, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: Colors.blueGrey,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: Colors.red.shade400,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit form (bottom sheet) ────────────────────────────────────────────
class _ContactForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic> data) onSaved;

  const _ContactForm({this.initial, required this.onSaved});

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _relationship;
  bool _isPrimary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name         = TextEditingController(text: c?['contact_name']  as String? ?? '');
    _phone        = TextEditingController(text: c?['contact_phone'] as String? ?? '');
    _email        = TextEditingController(text: c?['contact_email'] as String? ?? '');
    _relationship = TextEditingController(text: c?['relationship']  as String? ?? '');
    _isPrimary    = c?['is_primary'] == 1 || c?['is_primary'] == true;
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose(); _relationship.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSaved({
      'contact_name':  _name.text.trim(),
      'contact_phone': _phone.text.trim(),
      'contact_email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'relationship':  _relationship.text.trim().isEmpty ? null : _relationship.text.trim(),
      'is_primary':    _isPrimary,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isEditing ? 'Edit Contact' : 'Add Emergency Contact',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _Field(controller: _name, label: 'Full Name', hint: 'e.g. Ahmad Khan', required: true),
            const SizedBox(height: 14),
            _Field(
              controller: _phone, label: 'Phone Number', hint: 'e.g. +92 300 1234567',
              required: true, keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _email, label: 'Email Address (optional)',
              hint: 'SOS alert will be sent here',
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(controller: _relationship, label: 'Relationship (optional)', hint: 'e.g. Father, Friend, Doctor'),
            const SizedBox(height: 14),

            // Primary toggle
            Container(
              decoration: BoxDecoration(
                color: _isPrimary ? const Color(0xFFFFF3F3) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isPrimary ? const Color(0xFFE53935) : Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
                title: const Text('Primary Contact', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Gets highlighted; used first in emergencies', style: TextStyle(fontSize: 12)),
                activeColor: const Color(0xFFB71C1C),
                dense: true,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEditing ? 'Save Changes' : 'Add Contact', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator ??
          (v) {
            if (required && (v == null || v.trim().isEmpty)) return '$label is required';
            return null;
          },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_emergency_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('No Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Add trusted people who should be notified by email when you trigger an SOS.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
