// views/auth/reset_password_view.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';
import 'package:safarsync_mobileapp/backend/utils/routes.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/auth_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/theme_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/widgets/custom_text_field.dart';
import 'package:safarsync_mobileapp/backend/widgets/primary_button.dart';

class ResetPasswordView extends StatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordView({super.key, this.token, this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
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
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                40.hBox,

                // Logo
                FadeInDown(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
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
                      ),
                      child: Image.asset(
                        isDarkMode
                            ? 'assets/images/dark_smac_logo.png'
                            : 'assets/images/smac_logo.png',
                        height: 50.h,
                      ),
                    ),
                  ),
                ),
                30.hBox,

                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                8.hBox,
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Enter your reset code and new password.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                40.hBox,

                // Reset Token Field
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: CustomTextField(
                    controller: _tokenController,
                    hintText: 'Enter reset code',
                    prefixIcon: Icons.verified_user_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reset code is required';
                      }
                      return null;
                    },
                  ),
                ),
                20.hBox,

                // New Password Field
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: CustomTextField(
                    controller: _newPasswordController,
                    hintText: 'New password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: !_isNewPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary(context),
                        size: 18.w,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                ),
                20.hBox,

                // Confirm Password Field
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm new password',
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary(context),
                        size: 18.w,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                40.hBox,

                // Reset Password Button
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: PrimaryButton(
                    text: 'Reset Password',
                    isLoading: authViewModel.isLoading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        authViewModel
                            .resetPassword(
                              email: widget.email ?? '',
                              token: _tokenController.text.trim(),
                              password: _newPasswordController.text.trim(),
                            )
                            .then((success) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Password reset successfully!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  Routes.login,
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to reset password!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.errorRed,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            });
                      }
                    },
                  ),
                ),
                30.hBox,

                // Back to Login Link
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember your password? ",
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(context),
                          fontSize: 14.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.login,
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Sign In',
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
                20.hBox,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
