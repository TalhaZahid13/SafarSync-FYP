// widgets/shimmer_widgets.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';

class ShimmerWidgets {
  // Base shimmer container
  static Widget _shimmerContainer({
    required double width,
    required double height,
    double borderRadius = 8,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // Shimmer wrapper
  static Widget shimmerWrapper({
    required Widget child,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  // Course card shimmer
  static Widget courseCardShimmer(BuildContext context) {
    return shimmerWrapper(
      context: context,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            _shimmerContainer(
              width: double.infinity,
              height: 180,
              borderRadius: 12,
              context: context,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tags
                  Row(
                    children: [
                      _shimmerContainer(
                        width: 80,
                        height: 24,
                        borderRadius: 4,
                        context: context,
                      ),
                      8.wBox,
                      _shimmerContainer(
                        width: 60,
                        height: 24,
                        borderRadius: 4,
                        context: context,
                      ),
                    ],
                  ),

                  12.hBox,

                  // Title
                  _shimmerContainer(
                    width: double.infinity,
                    height: 20,
                    context: context,
                  ),

                  8.hBox,

                  _shimmerContainer(width: 200, height: 16, context: context),

                  12.hBox,

                  // Duration info
                  Row(
                    children: [
                      _shimmerContainer(
                        width: 16,
                        height: 16,
                        borderRadius: 8,
                        context: context,
                      ),
                      6.wBox,
                      _shimmerContainer(
                        width: 60,
                        height: 14,
                        context: context,
                      ),
                      16.wBox,
                      _shimmerContainer(
                        width: 16,
                        height: 16,
                        borderRadius: 8,
                        context: context,
                      ),
                      6.wBox,
                      _shimmerContainer(
                        width: 80,
                        height: 14,
                        context: context,
                      ),
                    ],
                  ),

                  12.hBox,

                  // Instructor
                  Row(
                    children: [
                      _shimmerContainer(
                        width: 30,
                        height: 30,
                        borderRadius: 15,
                        context: context,
                      ),
                      10.wBox,
                      _shimmerContainer(
                        width: 120,
                        height: 14,
                        context: context,
                      ),
                    ],
                  ),

                  16.hBox,

                  // Price and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _shimmerContainer(
                        width: 100,
                        height: 20,
                        context: context,
                      ),
                      _shimmerContainer(
                        width: 100,
                        height: 36,
                        borderRadius: 8,
                        context: context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List item shimmer (for gigs, notifications, chats)
  static Widget listItemShimmer(BuildContext context) {
    return shimmerWrapper(
      context: context,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar/Icon
            _shimmerContainer(
              width: 50,
              height: 50,
              borderRadius: 25,
              context: context,
            ),
            16.wBox,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerContainer(
                    width: double.infinity,
                    height: 16,
                    context: context,
                  ),
                  8.hBox,
                  _shimmerContainer(width: 200, height: 14, context: context),
                  6.hBox,
                  _shimmerContainer(width: 80, height: 12, context: context),
                ],
              ),
            ),

            // Action/Time
            _shimmerContainer(width: 60, height: 12, context: context),
          ],
        ),
      ),
    );
  }

  // Chat item shimmer
  static Widget chatItemShimmer(BuildContext context) {
    return shimmerWrapper(
      context: context,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Profile image
            _shimmerContainer(
              width: 50,
              height: 50,
              borderRadius: 25,
              context: context,
            ),
            16.wBox,

            // Chat content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _shimmerContainer(
                        width: 120,
                        height: 16,
                        context: context,
                      ),
                      _shimmerContainer(
                        width: 60,
                        height: 12,
                        context: context,
                      ),
                    ],
                  ),
                  8.hBox,
                  _shimmerContainer(width: 180, height: 14, context: context),
                ],
              ),
            ),

            8.wBox,

            // Unread badge
            _shimmerContainer(
              width: 20,
              height: 20,
              borderRadius: 10,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  // Notification item shimmer
  static Widget notificationItemShimmer(BuildContext context) {
    return shimmerWrapper(
      context: context,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _shimmerContainer(
              width: 40,
              height: 40,
              borderRadius: 8,
              context: context,
            ),
            16.wBox,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerContainer(
                    width: double.infinity,
                    height: 16,
                    context: context,
                  ),
                  8.hBox,
                  _shimmerContainer(
                    width: double.infinity,
                    height: 14,
                    context: context,
                  ),
                  6.hBox,
                  _shimmerContainer(width: 100, height: 12, context: context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile section shimmer
  static Widget profileSectionShimmer(BuildContext context) {
    return shimmerWrapper(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                _shimmerContainer(
                  width: 80,
                  height: 80,
                  borderRadius: 40,
                  context: context,
                ),
                16.wBox,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerContainer(
                        width: 150,
                        height: 20,
                        context: context,
                      ),
                      8.hBox,
                      _shimmerContainer(
                        width: 120,
                        height: 16,
                        context: context,
                      ),
                      8.hBox,
                      _shimmerContainer(
                        width: 100,
                        height: 14,
                        context: context,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            24.hBox,

            // Profile details
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    _shimmerContainer(
                      width: 24,
                      height: 24,
                      borderRadius: 4,
                      context: context,
                    ),
                    16.wBox,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerContainer(
                            width: 100,
                            height: 12,
                            context: context,
                          ),
                          6.hBox,
                          _shimmerContainer(
                            width: 200,
                            height: 16,
                            context: context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button shimmer
  static Widget buttonShimmer(
    BuildContext context, {
    double width = double.infinity,
    double height = 48,
  }) {
    return shimmerWrapper(
      context: context,
      child: _shimmerContainer(
        width: width,
        height: height,
        borderRadius: 8,
        context: context,
      ),
    );
  }

  // Text shimmer
  static Widget textShimmer(
    BuildContext context, {
    double width = 100,
    double height = 16,
  }) {
    return shimmerWrapper(
      context: context,
      child: _shimmerContainer(width: width, height: height, context: context),
    );
  }

  // Generic card shimmer
  static Widget cardShimmer(BuildContext context, {double height = 120}) {
    return shimmerWrapper(
      context: context,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerContainer(
                width: double.infinity,
                height: 20,
                context: context,
              ),
              12.hBox,
              _shimmerContainer(width: 200, height: 16, context: context),
              8.hBox,
              _shimmerContainer(width: 150, height: 14, context: context),
            ],
          ),
        ),
      ),
    );
  }
}
