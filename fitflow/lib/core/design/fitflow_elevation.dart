import 'package:flutter/material.dart';

/// Depth comes from tone and hairline borders first. Shadows stay rare.
class FitFlowElevation {
  const FitFlowElevation._();

  static const double none = 0;
  static const double overlay = 1;

  static const List<BoxShadow> lightRaised = [
    BoxShadow(
      color: Color(0x1413211C),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Dark mode uses a lighter surface instead of a drop shadow.
  static const List<BoxShadow> darkRaised = [];
}
