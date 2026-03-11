// widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary(context),
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppColors.textSecondary(context),
                  size: 20.w,
                )
              : null,
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textHint(context),
            fontSize: 16.sp,
          ),
          filled: true,
          fillColor: AppColors.cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.w),
            borderSide: BorderSide(color: AppColors.borderColor(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.w),
            borderSide: BorderSide(color: AppColors.borderColor(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.w),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 20.w,
          ),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return '$hintText is required';
              }
              return null;
            },
      ),
    );
  }
}
