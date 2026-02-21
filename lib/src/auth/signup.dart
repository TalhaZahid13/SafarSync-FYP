import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final _auth = FirebaseAuth.instance;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Display name set
      await cred.user?.updateDisplayName(fullName);

      // TODO: contact number / extra data ko Firestore / Realtime DB mein save kar sakte ho

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        // AuthGate user ko logged-in dekh ke App() dikha dega
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'operation-not-allowed':
          message =
          'Email/password sign-in is disabled. Enable it in Firebase console.';
          break;
        default:
          message = 'Signup failed (${e.code})';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon / Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.userPlus,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Join SafarSync',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your account to start planning trips',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Full Name
                _inputField(
                  label: 'Full Name',
                  hint: 'Muhammad Talha',
                  icon: LucideIcons.user,
                  controller: _fullNameController,
                ),
                const SizedBox(height: 12),

                // Email
                _inputField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Contact Number
                _inputField(
                  label: 'Contact Number',
                  hint: '+92 3XX XXXXXXX',
                  icon: LucideIcons.phone,
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // Password
                _inputField(
                  label: 'Password',
                  hint: '••••••••',
                  icon: LucideIcons.lock,
                  controller: _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 12),

                // Confirm Password
                _inputField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  icon: LucideIcons.lock,
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),

                const SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
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
                      'Sign Up',
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
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
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
