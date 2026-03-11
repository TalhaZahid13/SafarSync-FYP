// views/home/profile/profile_view.dart (IMPROVED VERSION)

import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';
import 'package:safarsync_mobileapp/backend/utils/routes.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/auth_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/profile_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/theme_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/widgets/custom_text_field.dart';
import 'package:safarsync_mobileapp/backend/widgets/primary_button.dart';
import 'package:safarsync_mobileapp/backend/utils/dialog_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:safarsync_mobileapp/backend/views/home/notification/notifications_view.dart';
import 'package:safarsync_mobileapp/backend/views/home/profile/privacy_screen.dart';
import 'package:safarsync_mobileapp/backend/views/home/profile/help_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  // late TextEditingController _addressController;
  // late TextEditingController _dateOfBirthController;
  late TextEditingController _bioController;
  // late TextEditingController _countryController;
  // late TextEditingController _languageController;
  // late TextEditingController _genderController;

  bool _isControllersInitialized = false;
  bool _isEditMode = false;

  // 🆕 Profile picture update (separate from edit mode)
  Future<void> _updateProfilePicture() async {
    try {
      // Permission check
      PermissionStatus cameraStatus = await Permission.camera.request();
      PermissionStatus storageStatus = await Permission.photos.request();

      if (cameraStatus.isDenied || storageStatus.isDenied) {
        if (mounted) {
          DialogHelper.showError(
            context: context,
            title: 'Permission Required',
            message:
                'Camera and gallery permissions are required to update profile picture.',
            buttonText: 'OK',
          );
        }
        return;
      }

      // Image picker setup
      final ImagePicker picker = ImagePicker();

      // Show bottom sheet to choose source
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppColors.surfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
        ),
        builder: (ctx) => Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderColor(context),
                  borderRadius: BorderRadius.circular(2.h),
                ),
              ),
              20.hBox,
              Text(
                'Update Profile Picture',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              20.hBox,
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40.w,
                              color: AppColors.primary,
                            ),
                            8.hBox,
                            Text(
                              'Camera',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  16.wBox,
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 40.w,
                              color: AppColors.primary,
                            ),
                            8.hBox,
                            Text(
                              'Gallery',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              20.hBox,
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Show loading
        DialogHelper.showLoading(
          context: context,
          message: 'Updating profile picture...',
        );

        // Upload image
        final profileViewModel = context.read<ProfileViewModel>();
        final success = await profileViewModel.updateProfilePicture(
          File(pickedFile.path),
        );

        // Close loading
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          if (success) {
            DialogHelper.showSuccess(
              context: context,
              title: 'Picture Updated! 📸',
              message: 'Your profile picture has been updated successfully.',
              buttonText: 'Great!',
            );
          } else {
            DialogHelper.showError(
              context: context,
              title: 'Update Failed 😞',
              message: profileViewModel.getDisplayErrorMessage(),
              buttonText: 'Try Again',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        DialogHelper.showError(
          context: context,
          title: 'Error',
          message: 'Failed to update profile picture: ${e.toString()}',
          buttonText: 'OK',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  // String formatDob(String input) {
  //   try {
  //     final parsedDate = DateFormat("dd/MM/yyyy").parse(input);
  //     return DateFormat("yyyy-MM-dd").format(parsedDate);
  //   } catch (e) {
  //     return input;
  //   }
  // }

  void _initializeControllers() {
    final profileViewModel = context.read<ProfileViewModel>();
    profileViewModel.fetchUserData().then((_) {
      if (mounted) {
        _firstnameController = TextEditingController(
          text: profileViewModel.firstName,
        );
        _lastnameController = TextEditingController(
          text: profileViewModel.lastName,
        );
        _emailController = TextEditingController(text: profileViewModel.email);
        _phoneController = TextEditingController(text: profileViewModel.phone);
        // _addressController = TextEditingController(
        //   text: profileViewModel.address,
        // );
        // _dateOfBirthController = TextEditingController(
        //   text: profileViewModel.dateOfBirth,
        // );
        _bioController = TextEditingController(text: profileViewModel.bio);
        // _countryController = TextEditingController(
        //   text: profileViewModel.country,
        // );
        // _languageController = TextEditingController(
        //   text: profileViewModel.language,
        // );
        // _genderController = TextEditingController(
        //   text: profileViewModel.gender,
        // );
        setState(() {
          _isControllersInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_isControllersInitialized) {
      _firstnameController.dispose();
      _lastnameController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      // _addressController.dispose();
      // _dateOfBirthController.dispose();
      _bioController.dispose();
      // _countryController.dispose();
      // _languageController.dispose();
      // _genderController.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }

  // 🆕 Updated Profile Header with Picture Update Option
  Widget _buildProfileHeader() {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor(context),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.w),
              bottomRight: Radius.circular(24.w),
            ),
          ),
          child: Column(
            children: [
              // Profile Picture with Update Option (Always Available)
              Stack(
                children: [
                  GestureDetector(
                    onTap: _updateProfilePicture,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50.w,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage:
                            (profileViewModel.currentUser?.profilePic != null &&
                                profileViewModel
                                    .currentUser!
                                    .profilePic!
                                    .isNotEmpty)
                            ? CachedNetworkImageProvider(
                                profileViewModel.currentUser!.profilePic!,
                              )
                            : null,
                        child:
                            (profileViewModel.currentUser?.profilePic == null ||
                                profileViewModel
                                    .currentUser!
                                    .profilePic!
                                    .isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 50.w,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Camera icon - Always visible for picture update
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _updateProfilePicture,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              8.hBox,

              // Tap to change picture hint
              Text(
                'Tap to change picture',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
              ),

              16.hBox,

              // Name and Email
              Text(
                _isControllersInitialized
                    ? '${_firstnameController.text} ${_lastnameController.text}'
                    : 'Loading...',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              4.hBox,
              Text(
                _isControllersInitialized ? _emailController.text : '',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Settings section remains same...
  Widget _buildSettingsSection() {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Settings'),

            // Theme Toggle
            Container(
              margin: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.cardColor(context),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: ListTile(
                leading: Icon(
                  themeViewModel.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: AppColors.primary,
                  size: 24.w,
                ),
                title: Text(
                  'Dark Mode',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                  ),
                ),
                trailing: Switch(
                  value: themeViewModel.isDarkMode,
                  onChanged: (value) => themeViewModel.toggleTheme(),
                  activeColor: AppColors.primary,
                ),
              ),
            ),

            // Other Settings
            Container(
              margin: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.cardColor(context),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              // Here add logics of Notifications, Privacy & Security, Help & Support, Logout
              child: Column(
                children: [
                  // 🔔 Notifications
                  ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 24.w,
                    ),
                    title: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary(context),
                      size: 16.w,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsView(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.borderColor(context)),

                  // 🔐 Privacy & Security
                  ListTile(
                    leading: Icon(
                      Icons.security_outlined,
                      color: AppColors.primary,
                      size: 24.w,
                    ),
                    title: Text(
                      'Privacy & Security',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary(context),
                      size: 16.w,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: AppColors.borderColor(context)),

                  // 🚪 Logout
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: AppColors.errorRed,
                          size: 24.w,
                        ),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                        ),
                        onTap: authViewModel.isLoading
                            ? null
                            : () => _showLogoutDialog(context, authViewModel),
                        trailing: authViewModel.isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.errorRed,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await authViewModel.logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have been logged out successfully',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      btnOkColor: AppColors.errorRed,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor(context),
        foregroundColor: AppColors.textPrimary(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
          onPressed: () {
            if (_isEditMode) {
              setState(() => _isEditMode = false);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (route) => false,
              );
            }
          },
        ),
        elevation: 0,
        title: Text(
          _isEditMode ? 'Edit Profile' : 'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.primary, size: 24.w),
              onPressed: () => setState(() => _isEditMode = true),
            ),
        ],
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          if (!_isControllersInitialized) {
            return Center(
              child: SizedBox(
                width: 40.w,
                height: 40.h,
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          if (viewModel.profileState == ViewState.error) {
            return Center(
              child: Text(
                viewModel.errorMessage ?? "Failed to load profile data.",
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary(context),
                  fontSize: 16.sp,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Profile header - Always shows profile picture with update option
                _buildProfileHeader(),
                24.hBox,

                if (!_isEditMode) ...[
                  // Settings section when not in edit mode
                  _buildSettingsSection(),
                ] else ...[
                  // Edit form - TEXT FIELDS ONLY (No profile picture here)
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Edit Information'),
                          10.hBox,
                          CustomTextField(
                            controller: _firstnameController,
                            hintText: 'First Name',
                            prefixIcon: Icons.person_outline,
                          ),
                          15.hBox,
                          CustomTextField(
                            controller: _lastnameController,
                            hintText: 'Last Name',
                            prefixIcon: Icons.person_outline,
                          ),
                          15.hBox,
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          24.hBox,

                          _buildSectionTitle('Personal Information'),
                          10.hBox,
                          CustomTextField(
                            controller: _phoneController,
                            hintText: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          15.hBox,

                          15.hBox,
                          CustomTextField(
                            controller: _bioController,
                            hintText: 'Bio',
                            prefixIcon: Icons.info_outline,
                            maxLines: 3,
                          ),
                          24.hBox,

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _isEditMode = false),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.borderColor(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.w),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                              16.wBox,
                              Expanded(
                                child: PrimaryButton(
                                  text: 'Save Changes',
                                  isLoading:
                                      viewModel.profileState ==
                                      ViewState.loading,
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      bool overallSuccess = true;

                                      // Check if name/email fields me kuch change hua hai
                                      if (_firstnameController.text
                                              .trim()
                                              .isNotEmpty ||
                                          _lastnameController.text
                                              .trim()
                                              .isNotEmpty
                                      // _emailController.text
                                      //     .trim()
                                      //     .isNotEmpty
                                      ) {
                                        final profileSuccess = await viewModel
                                            .updateProfile(
                                              firstName: _firstnameController
                                                  .text
                                                  .trim(),
                                              lastName: _lastnameController.text
                                                  .trim(),
                                              // email: _emailController.text
                                              //     .trim(),
                                            );

                                        if (!profileSuccess)
                                          overallSuccess = false;
                                      }

                                      // Check if details fields me kuch change hua hai
                                      if (_phoneController.text
                                              .trim()
                                              .isNotEmpty ||
                                          // _dateOfBirthController.text
                                          //     .trim()
                                          //     .isNotEmpty ||
                                          _bioController.text
                                              .trim()
                                              .isNotEmpty) {
                                        final detailsSuccess = await viewModel
                                            .updateUserDetails(
                                              phone: _phoneController.text
                                                  .trim(),
                                              // dob: formatDob(
                                              //   _dateOfBirthController.text
                                              //       .trim(),
                                              // ),
                                              bio: _bioController.text.trim(),
                                            );

                                        if (!detailsSuccess)
                                          overallSuccess = false;
                                      }

                                      if (mounted) {
                                        if (overallSuccess) {
                                          setState(() => _isEditMode = false);
                                          DialogHelper.showSuccess(
                                            context: context,
                                            title: 'Profile Updated! ✅',
                                            message:
                                                'Your profile information has been updated successfully.',
                                            buttonText: 'Awesome!',
                                          );
                                        } else {
                                          DialogHelper.showError(
                                            context: context,
                                            title: 'Update Failed 😞',
                                            message: viewModel
                                                .getDisplayErrorMessage(),
                                            buttonText: 'Try Again',
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          20.hBox,
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
