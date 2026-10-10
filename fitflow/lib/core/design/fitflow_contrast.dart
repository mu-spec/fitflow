import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG relative-luminance contrast. Used by the design-system tests and
/// available if a later screen needs to check a custom pair.
double fitflowContrast(Color foreground, Color background) {
  final lighter = math.max(
    _relativeLuminance(foreground),
    _relativeLuminance(background),
  );
  final darker = math.min(
    _relativeLuminance(foreground),
    _relativeLuminance(background),
  );
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double srgb) {
    return srgb <= 0.04045
        ? srgb / 12.92
        : math.pow((srgb + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
