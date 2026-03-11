// utils/dialog_helper.dart
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';

class DialogHelper {
  // Helper method to check if context is still valid
  static bool _isContextValid(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  // Success Dialog
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onOkPressed,
    bool dismissOnTouchOutside = true,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: buttonText ?? 'Great!',
      btnOkColor: Colors.green,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onOkPressed != null && _isContextValid(context)) {
          onOkPressed();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(color: Colors.green.withOpacity(0.3), width: 2),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Error Dialog
  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onOkPressed,
    bool dismissOnTouchOutside = true,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: buttonText ?? 'OK',
      btnOkColor: Colors.red,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onOkPressed != null && _isContextValid(context)) {
          onOkPressed();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Warning Dialog
  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onOkPressed,
    bool dismissOnTouchOutside = true,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: buttonText ?? 'OK',
      btnOkColor: Colors.orange,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onOkPressed != null && _isContextValid(context)) {
          onOkPressed();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Info Dialog
  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onOkPressed,
    bool dismissOnTouchOutside = true,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: buttonText ?? 'OK',
      btnOkColor: AppColors.primary,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onOkPressed != null && _isContextValid(context)) {
          onOkPressed();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.3),
        width: 2,
      ),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Confirmation Dialog
  static void showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool dismissOnTouchOutside = false,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkText: confirmText ?? 'Yes',
      btnCancelText: cancelText ?? 'No',
      btnOkColor: AppColors.primary,
      btnCancelColor: Colors.grey,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onConfirm != null && _isContextValid(context)) {
          onConfirm();
        }
      },
      btnCancelOnPress: () {
        if (onCancel != null && _isContextValid(context)) {
          onCancel();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.3),
        width: 2,
      ),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Custom Dialog with custom body
  static void showCustom({
    required BuildContext context,
    required String title,
    required Widget body,
    String? buttonText,
    VoidCallback? onOkPressed,
    bool dismissOnTouchOutside = true,
    DialogType dialogType = DialogType.info,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: AnimType.scale,
      title: title,
      body: body,
      btnOkText: buttonText ?? 'OK',
      btnOkColor: AppColors.primary,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      btnOkOnPress: () {
        if (onOkPressed != null && _isContextValid(context)) {
          onOkPressed();
        }
      },
      dismissOnTouchOutside: dismissOnTouchOutside,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.3),
        width: 2,
      ),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Loading Dialog
  static void showLoading({required BuildContext context, String? message}) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Loading...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      dismissOnTouchOutside: false,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }

  // Network Error Dialog
  static void showNetworkError({
    required BuildContext context,
    VoidCallback? onRetry,
  }) {
    if (!_isContextValid(context)) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Network Error',
      desc: 'Please check your internet connection and try again.',
      btnOkText: 'Retry',
      btnCancelText: 'Cancel',
      btnOkColor: AppColors.primary,
      btnCancelColor: Colors.grey,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(context),
      ),
      descTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
      btnOkOnPress: () {
        if (onRetry != null && _isContextValid(context)) {
          onRetry();
        }
      },
      btnCancelOnPress: () {},
      dismissOnTouchOutside: false,
      dialogBackgroundColor: AppColors.surfaceColor(context),
      borderSide: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
      onDismissCallback: (type) {
        // Safely handle dismiss
      },
    ).show();
  }
}
