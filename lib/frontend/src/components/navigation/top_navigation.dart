import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class TopNavigation extends StatelessWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final titleFontSize = ResponsiveUtil.getResponsiveFontSize(
      context,
      mobileSize: 18,
      tabletSize: 20,
      laptopSize: 24,
    );
    final subtitleFontSize = ResponsiveUtil.getResponsiveFontSize(
      context,
      mobileSize: 12,
      tabletSize: 14,
      laptopSize: 16,
    );
    final padding = ResponsiveUtil.getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalam-o-Alaikum, Talha 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: padding * 0.25),
                Text(
                  'Ready for your next adventure?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: subtitleFontSize,
                  ),
                ),
              ],
            ),
          ),

          // Notification Button ONLY
          SizedBox(width: padding * 0.5),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: open notifications screen
                  },
                ),
              ),
              // Red dot (unread notifications)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
