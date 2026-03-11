// views/home/notification/notifications_view.dart - Updated with shimmer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:safarsync_mobileapp/backend/utils/app_colors.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive_extension.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart';
import 'package:safarsync_mobileapp/backend/utils/dialog_helper.dart';
import 'package:safarsync_mobileapp/backend/viewmodels/home_viewmodel.dart';
import 'package:safarsync_mobileapp/backend/widgets/shimmer_widgets.dart'; // Add this import

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surfaceColor(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.mark_email_read,
              color: AppColors.textPrimary(context),
            ),
            onPressed: () {
              DialogHelper.showInfo(
                context: context,
                title: 'Mark All Read',
                message: 'All notifications marked as read!',
                buttonText: 'OK',
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor(context),
      body: Consumer<HomeViewModel>(
        builder: (context, homeViewModel, child) {
          if (homeViewModel.notificationsState == ViewState.loading) {
            // Show shimmer loading effect
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8, // Show 8 shimmer items
              itemBuilder: (context, index) {
                return ShimmerWidgets.notificationItemShimmer(context);
              },
            );
          }

          if (homeViewModel.notificationsState == ViewState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    16.hBox,
                    Text(
                      "Failed to load notifications",
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    16.hBox,
                    ElevatedButton(
                      onPressed: () => homeViewModel.getNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Try Again',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (homeViewModel.notificationsState == ViewState.empty ||
              homeViewModel.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  16.hBox,
                  Text(
                    "No notifications yet.",
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(context),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = homeViewModel.notifications;
          return RefreshIndicator(
            onRefresh: () => homeViewModel.getNotifications(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderColor(context),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      12.wBox,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            4.hBox,
                            Text(
                              notification.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            8.hBox,
                            Text(
                              notification.time,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
