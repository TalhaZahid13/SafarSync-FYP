import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/auth_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/theme_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/widgets/custom_text_field.dart';
import 'package:safarsync_mobileapp/backend/widgets/primary_button.dart';

class ForgotPasswordView extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  ForgotPasswordView({super.key});

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
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
            child: Padding(
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
                        'Forgot Password',
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
                        'No worries! We\'ll help you reset it.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    40.hBox,

                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter email address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    40.hBox,

                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: PrimaryButton(
                        text: 'Request Reset Link',
                        isLoading: authViewModel.isLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            authViewModel
                                .forgotPassword(_emailController.text)
                                .then((success) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Reset link sent to your email!',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: AppColors.successGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to send reset link!',
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
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
