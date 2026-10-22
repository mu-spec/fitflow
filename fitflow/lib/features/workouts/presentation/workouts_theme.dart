import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Workouts-hub-only Slate + Citrus roles. The user's selected brightness is retained.
class WorkoutsTheme extends StatelessWidget {
  const WorkoutsTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final original = FitFlowTheme.of(context).palette;
    const slate = Color(0xFF202526);
    const citrus = Color(0xFFD4E779);
    final page = dark ? slate : const Color(0xFFF3F4EE);
    final surface = dark ? const Color(0xFF303737) : const Color(0xFFE4E8DD);
    final ink = dark ? const Color(0xFFF3F4EE) : slate;
    final secondary = dark ? const Color(0xFFC4CBC3) : const Color(0xFF50594E);
    final accent = dark ? citrus : const Color(0xFF526515);
    final line = dark ? const Color(0xFF505958) : const Color(0xFFC5CDBB);
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
      subtleSurface: surface,
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
      onSecondary: slate,
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
              ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500),
          titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        iconTheme: base.iconTheme.copyWith(color: ink),
        appBarTheme: base.appBarTheme.copyWith(
            backgroundColor: page,
            foregroundColor: ink,
            surfaceTintColor: Colors.transparent,
            // Nested Workouts-area screens share the hub's title rhythm.
            titleTextStyle: text.titleLarge),
        bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: page),
        dialogTheme: base.dialogTheme.copyWith(backgroundColor: page),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: citrus,
          foregroundColor: slate,
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
        popupMenuTheme: base.popupMenuTheme.copyWith(color: surface),
        dividerColor: line,
      ),
      child: child,
    );
  }
}
