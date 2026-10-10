import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_theme_data.dart';
import 'package:flutter/material.dart';

/// Public theme entry. Tokens live in `core/design`; this keeps the existing
/// `AppTheme.light` / `AppTheme.dark` call sites stable.
class AppTheme {
  const AppTheme._();

  /// Provisional brand color. Not a locked logo color.
  static const Color seedColor = FitFlowColors.brandPrimary;

  static ThemeData get light => FitFlowThemeData.light;

  static ThemeData get dark => FitFlowThemeData.dark;
}
