// utils/responsive_extension.dart
import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/utils/responsive.dart';

extension ResponsiveInt on int {
  double get w => Responsive.w(toDouble());
  double get h => Responsive.h(toDouble());
  double get sp => Responsive.sp(toDouble());

  SizedBox get wBox => SizedBox(width: w);
  SizedBox get hBox => SizedBox(height: h);
}

extension ResponsiveDouble on double {
  double get w => Responsive.w(this);
  double get h => Responsive.h(this);
  double get sp => Responsive.sp(this);

  SizedBox get wBox => SizedBox(width: w);
  SizedBox get hBox => SizedBox(height: h);
}
