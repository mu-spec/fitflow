import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Opt-in reference-inspired foundation. Existing screens keep their themes.
class WorkoutDesignTheme extends StatelessWidget {
  const WorkoutDesignTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final original = FitFlowTheme.of(context).palette;
    const slate = Color(0xFF171918);
    const citrus = Color(0xFFC8FA63);
    final page = dark ? const Color(0xFF1B1F20) : const Color(0xFFF2F3F5);
    final surface = dark ? const Color(0xFF282D2F) : Colors.white;
    final ink = dark ? const Color(0xFFF6F7F4) : slate;
    final secondary = dark ? const Color(0xFFBDC3C6) : const Color(0xFF606467);
    final accent = dark ? citrus : slate;
    final line = dark ? const Color(0xFF454D50) : const Color(0xFFDFE2E4);
    final palette = FitFlowPalette(
      brand: accent,
      onBrand: dark ? slate : Colors.white,
      brandContainer: surface,
      onBrandContainer: ink,
      accent: accent,
      onAccent: dark ? slate : Colors.white,
      accentContainer: surface,
      onAccentContainer: ink,
      background: page,
      surface: surface,
      elevatedSurface: surface,
      subtleSurface: dark ? const Color(0xFF333A3C) : const Color(0xFFEDEFF1),
      textPrimary: ink,
      textSecondary: secondary,
      textMuted: secondary,
      border: line,
      divider: line,
      success: accent,
      onSuccess: dark ? slate : Colors.white,
      warning: original.warning,
      onWarning: original.onWarning,
      error: original.error,
      onError: original.onError,
      errorContainer: original.errorContainer,
      onErrorContainer: original.onErrorContainer,
      info: secondary,
      onInfo: page,
      workoutActive: surface,
      onWorkoutActive: ink,
      workoutRest: surface,
      onWorkoutRest: ink,
      progress: accent,
      onProgress: dark ? slate : Colors.white,
      focus: ink,
    );
    final scheme = base.colorScheme.copyWith(
      primary: accent,
      onPrimary: dark ? slate : Colors.white,
      primaryContainer: surface,
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: dark ? slate : Colors.white,
      secondaryContainer: surface,
      onSecondaryContainer: ink,
      surface: page,
      onSurface: ink,
      onSurfaceVariant: secondary,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      outline: line,
      outlineVariant: line,
    );
    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: page,
        extensions: [
          ...base.extensions.values.where((e) => e is! FitFlowTheme),
          FitFlowTheme(palette)
        ],
        textTheme: text.copyWith(
          titleLarge: text.titleLarge
              ?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        iconTheme: base.iconTheme.copyWith(color: ink),
        appBarTheme: base.appBarTheme.copyWith(
            backgroundColor: page,
            foregroundColor: ink,
            surfaceTintColor: Colors.transparent),
        bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: page),
        dialogTheme: base.dialogTheme.copyWith(backgroundColor: page),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: dark ? citrus : slate,
          foregroundColor: dark ? slate : Colors.white,
          shape: const StadiumBorder(),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        )),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: line),
        )),
        dividerColor: line,
      ),
      child: child,
    );
  }
}
