import 'package:flutter/material.dart';

/// A short type scale. Roles map onto Material text styles so existing
/// screens inherit the hierarchy without a screen-by-screen rewrite.
///
/// Colors are left unset so text follows [ColorScheme.onSurface] and system
/// text scaling. Do not set [TextScaler] or `textScaleFactor` here.
class FitFlowTypography {
  const FitFlowTypography._();

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle displayHero = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle cardHeading = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle secondaryBody = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  /// Large workout numerals. Tabular figures keep the countdown from jittering.
  static const TextStyle timer = TextStyle(
    fontSize: 56,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    fontFeatures: tabular,
  );

  static const TextStyle stat = TextStyle(
    fontSize: 32,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: tabular,
  );

  static TextTheme textTheme() {
    return const TextTheme(
      displayLarge: timer,
      displayMedium: stat,
      displaySmall: displayHero,
      headlineMedium: screenTitle,
      headlineSmall: sectionHeading,
      titleLarge: sectionHeading,
      titleMedium: cardHeading,
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: secondaryBody,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: caption,
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
