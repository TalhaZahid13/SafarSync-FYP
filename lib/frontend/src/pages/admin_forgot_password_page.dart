import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/api_service.dart';

class AdminForgotPasswordPage extends StatefulWidget {
  const AdminForgotPasswordPage({super.key});

  @override
  State<AdminForgotPasswordPage> createState() =>
      _AdminForgotPasswordPageState();
}

class _AdminForgotPasswordPageState extends State<AdminForgotPasswordPage> {
  // Step 1: enter email → get OTP
  // Step 2: enter OTP + new password → reset
  int _step = 1;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Enter your admin email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.adminForgotPassword(email);
      _snack('If that email is registered, a 6-digit code was sent.');
      if (mounted) {
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error: $e');
      }
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (otp.isEmpty || newPass.isEmpty) {
      _snack('Fill all fields');
      return;
    }
    if (newPass.length < 8) {
      _snack('Password must be at least 8 characters');
      return;
    }
    if (newPass != confirmPass) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.adminResetPassword(
        email: _emailCtrl.text.trim(),
        otp: otp,
        newPassword: newPass,
      );
      if (result['success'] == true) {
        _snack('Password reset! You can now log in.');
        if (mounted) Navigator.pop(context);
      } else {
        _snack(result['message'] ?? result['error'] ?? 'Reset failed');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Reset Admin Password',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == 1 ? _buildStep1(theme, cs) : _buildStep2(theme, cs),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.mailOpen, size: 48, color: cs.primary),
        const SizedBox(height: 16),
        Text(
          'Enter your admin email and we\'ll send a 6-digit reset code.',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 24),
        _field(
          label: 'Admin Email',
          hint: 'admin@safarsync.com',
          icon: LucideIcons.mail,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          theme: theme,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                    ),
                  )
                : const Text(
                    'Send Reset Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.keyRound, size: 48, color: cs.primary),
        const SizedBox(height: 16),
        Text(
          'Enter the 6-digit code sent to your email and choose a new password.',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 24),
        _field(
          label: 'Reset Code (6 digits)',
          hint: '123456',
          icon: LucideIcons.hash,
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'New Password',
          hint: '••••••••',
          icon: LucideIcons.lock,
          controller: _newPassCtrl,
          isPassword: true,
          obscureText: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          theme: theme,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Confirm Password',
          hint: '••••••••',
          icon: LucideIcons.lock,
          controller: _confirmPassCtrl,
          isPassword: true,
          obscureText: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          theme: theme,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ThemeData theme,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
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
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: theme.iconTheme.color, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
