import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Centralized FitFlow Material 3 themes.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF167A66);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0E1412)
          : const Color(0xFFF7F9F7),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF131A17) : Colors.white,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
