import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendPasswordReset(email);
      if (!mounted) return;
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] as String? ?? 'Failed to send reset email',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset instructions sent to $email')),
      );
      // The email contains a link (opens the app) and a 6-digit code.
      final done = await _showResetCodeDialog(email);
      if (mounted && done == true) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Lets the user finish the reset with the code from the email.
  Future<bool?> _showResetCodeDialog(String email) {
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var busy = false;
    String? error;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Enter reset code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the 6-digit code from the email (or tap the link in it), '
                'then choose a new password.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reset code'),
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (min 6 characters)',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx, true),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (codeCtrl.text.trim().length < 6 ||
                          passCtrl.text.length < 6) {
                        setLocal(
                          () => error =
                              'Enter the code and a password of at least 6 characters',
                        );
                        return;
                      }
                      setLocal(() {
                        busy = true;
                        error = null;
                      });
                      final r = await ApiService.resetPasswordWithCode(
                        email: email,
                        code: codeCtrl.text,
                        newPassword: passCtrl.text,
                      );
                      if (r['success'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx, true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(r['message'] as String)),
                          );
                        }
                      } else {
                        setLocal(() {
                          busy = false;
                          error = r['message'] as String?;
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset password'),
            ),
          ],
        ),
      ),
    );
  }

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
        title: Text(
          'Forgot Password',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.keyRound,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Reset your password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and we’ll send you a reset link.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
                _inputField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  controller: _emailController,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDB913),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black87,
                              ),
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              color: Colors.black87,
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
      ),
    );
  }

  Widget _inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    final theme = Theme.of(context);

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
          ),
        ),
      ],
    );
  }
}
