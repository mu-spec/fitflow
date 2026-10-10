import 'package:flutter/material.dart';

/// Restrained motion language. No bounce, no looping decoration.
///
/// Route changes still go through [FitFlowPageTransitionsBuilder], which
/// uses [emphasized] and collapses to zero under reduced motion.
class FitFlowMotion {
  const FitFlowMotion._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 320);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
}
