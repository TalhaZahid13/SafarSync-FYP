// utils/responsive.dart
import 'dart:developer';

import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late Orientation orientation;

  // Samsung Galaxy S20 Base Dimensions
  static const double designWidth = 411.4;
  static const double designHeight = 914.3;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
  }

  // Core responsive methods
  static double w(double width) => (width / designWidth) * screenWidth;
  static double h(double height) => (height / designHeight) * screenHeight;
  static double sp(double fontSize) => (fontSize / designWidth) * screenWidth;

  // Device categories
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600;

  // Screen height categories
  static bool get isSmallScreen => screenHeight < 700;
  static bool get isNormalScreen => screenHeight >= 700 && screenHeight < 900;
  static bool get isLargeScreen => screenHeight >= 900;

  // Status bar and safe areas
  static double get statusBarHeight => _mediaQueryData.padding.top;
  static double get bottomPadding => _mediaQueryData.padding.bottom;
  static double get availableHeight =>
      screenHeight - statusBarHeight - bottomPadding;

  // Debug info
  static void printDeviceInfo() {
    log(
      '📱 Current Device: ${screenWidth.toStringAsFixed(1)} x ${screenHeight.toStringAsFixed(1)}',
    );
    log('📐 Scale Factor: ${(screenWidth / designWidth).toStringAsFixed(2)}x');
    log('📂 Category: ${isTablet ? "Tablet" : "Mobile"}');
  }
}
