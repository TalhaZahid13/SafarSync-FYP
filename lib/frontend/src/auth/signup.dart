import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        contact.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.signup(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: contact,
      );

      if (result['success']) {
        if (mounted) {
          if (result['needsConfirmation'] == true) {
            // Email confirmation is required before the first login.
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Verify your email'),
                content: Text(
                  result['message'] as String? ??
                      'We sent you a confirmation link. Verify your email, then log in.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Welcome to SafarSync.'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Signup failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          'Create Account',
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
                    gradient: LinearGradient(
                      colors: [colorScheme.secondary, colorScheme.primary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.userPlus,
                    size: 40,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Join SafarSync',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account to start planning trips',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                _inputField(
                  label: 'Full Name',
                  hint: 'Muhammad Talha',
                  icon: LucideIcons.user,
                  controller: _fullNameController,
                ),
                const SizedBox(height: 12),

                _inputField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                _inputField(
                  label: 'Contact Number',
                  hint: '+92 3XX XXXXXXX',
                  icon: LucideIcons.phone,
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                _inputField(
                  label: 'Password',
                  hint: '••••••••',
                  icon: LucideIcons.lock,
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 12),

                _inputField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  icon: LucideIcons.lock,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign Up',
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
      ),
    );
  }

  Widget _inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
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
                    onPressed: onToggleObscure,
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
