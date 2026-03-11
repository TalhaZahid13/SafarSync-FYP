// views/auth/login_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/dialog_helper.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/auth_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/theme_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/widgets/custom_text_field.dart';
import 'package:animate_do/animate_do.dart';
import 'package:safarsync_mobileapp/backend/widgets/primary_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _hasShownDialog = false; // Prevent multiple dialogs

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Reset dialog flag
      _hasShownDialog = false;

      final authViewModel = context.read<AuthViewModel>();

      // Just call login - don't handle navigation here
      // Let the main.dart Consumer<AuthViewModel> handle navigation
      await authViewModel.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w, top: 8.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor(context),
              borderRadius: BorderRadius.circular(12.w),
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(isDarkMode),
                  color: AppColors.primary,
                  size: 20.w,
                ),
              ),
              onPressed: () => themeViewModel.toggleTheme(),
            ),
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // Handle dialogs safely
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _hasShownDialog) return;

            if (authViewModel.successMessage != null) {
              _hasShownDialog = true;
              DialogHelper.showSuccess(
                context: context,
                title: 'Welcome Back! 🎉',
                message: authViewModel.successMessage!,
                buttonText: 'Continue',
                onOkPressed: () {
                  authViewModel.clearMessages();
                  // Navigation will be handled automatically by main.dart
                },
              );
            } else if (authViewModel.errorMessage != null) {
              _hasShownDialog = true;
              DialogHelper.showError(
                context: context,
                title: 'Login Failed 😞',
                message: authViewModel.getDisplayErrorMessage(),
                buttonText: 'Try Again',
                onOkPressed: () {
                  authViewModel.clearMessages();
                },
              );
            }
          });

          return SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Logo with enhanced animation
                        FadeInDown(
                          child: Hero(
                            tag: 'smac_logo',
                            child: Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.primary.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.w),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                isDarkMode
                                    ? 'assets/images/dark_smac_logo.png'
                                    : 'assets/images/smac_logo.png',
                                height: 45.h,
                              ),
                            ),
                          ),
                        ),
                        30.hBox,

                        // Title with bounce animation
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Welcome Back! 👋',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        8.hBox,

                        // Subtitle
                        FadeInDown(
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            'Sign in to continue your learning journey',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        40.hBox,

                        // Email Field with enhanced animation
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: CustomTextField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        20.hBox,

                        // Password Field with enhanced animation
                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: CustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  key: ValueKey(_isPasswordVisible),
                                  color: AppColors.textSecondary(context),
                                  size: 18.w,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Forgot Password with enhanced styling
                        FadeInUp(
                          delay: const Duration(milliseconds: 800),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                DialogHelper.showInfo(
                                  context: context,
                                  title: 'Forgot Password?',
                                  message:
                                      'Password reset functionality will be available soon!',
                                  buttonText: 'Got it',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        20.hBox,

                        // Sign In Button with loading state
                        FadeInUp(
                          delay: const Duration(milliseconds: 900),
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.w),
                                boxShadow: authViewModel.isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                              ),
                              child: PrimaryButton(
                                text: authViewModel.isLoading
                                    ? 'Signing In...'
                                    : 'Sign In',
                                isLoading: authViewModel.isLoading,
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : _handleLogin,
                              ),
                            ),
                          ),
                        ),

                        // Loading indicator text
                        if (authViewModel.isLoading)
                          FadeIn(
                            delay: const Duration(milliseconds: 100),
                            child: Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: Text(
                                'Please wait while we sign you in...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary(context),
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        30.hBox,

                        // Divider
                        FadeInUp(
                          delay: const Duration(milliseconds: 950),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.borderColor(context),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppColors.borderColor(context),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        20.hBox,

                        // Sign Up Link with enhanced styling
                        FadeInUp(
                          delay: const Duration(milliseconds: 1000),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor(context),
                              borderRadius: BorderRadius.circular(12.w),
                              border: Border.all(
                                color: AppColors.borderColor(context),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    DialogHelper.showInfo(
                                      context: context,
                                      title: 'Sign Up',
                                      message:
                                          'Registration functionality will be available soon!',
                                      buttonText: 'Got it',
                                    );
                                  },
                                  child: Text(
                                    'Sign up here',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Quick demo login option
                        FadeInUp(
                          delay: const Duration(milliseconds: 1100),
                          child: Padding(
                            padding: EdgeInsets.only(top: 20.h),
                            child: TextButton.icon(
                              onPressed: () {
                                _emailController.text = 'demo@smac.com';
                                _passwordController.text = 'demo123';
                                DialogHelper.showInfo(
                                  context: context,
                                  title: 'Demo Credentials',
                                  message:
                                      'Demo login credentials have been filled for you!',
                                  buttonText: 'Great!',
                                );
                              },
                              icon: Icon(
                                Icons.speed,
                                color: AppColors.primary,
                                size: 16.w,
                              ),
                              label: Text(
                                'Use Demo Login',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
