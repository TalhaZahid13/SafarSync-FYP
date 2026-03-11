// widgets/text_button_custom.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';

class TextButtonCustom extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const TextButtonCustom({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primary,
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: textColor ?? AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
    );
  }
}
