import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Opt-in Workouts-area Slate + Citrus roles. The user's selected brightness is retained.
class WorkoutsTheme extends StatelessWidget {
  const WorkoutsTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final original = FitFlowTheme.of(context).palette;
    const slate = Color(0xFF202526);

    final page = dark ? const Color(0xFF17191E) : const Color(0xFFF5F6F9);
    final surface = dark ? const Color(0xFF252831) : Colors.white;
    final ink = dark ? const Color(0xFFF3F4EE) : slate;
    final secondary = dark ? const Color(0xFFC4CBC3) : const Color(0xFF50594E);
    final accent = dark ? Colors.white : Colors.black;
    final line = dark ? const Color(0xFF414650) : const Color(0xFFE3E6ED);
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
            titleTextStyle: text.titleLarge
                ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500)),
        bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: page),
        dialogTheme: base.dialogTheme.copyWith(
          backgroundColor: page,
          titleTextStyle: text.titleLarge
              ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500),
          contentTextStyle: text.bodyMedium?.copyWith(color: secondary),
        ),
        cardTheme: base.cardTheme.copyWith(
          color: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: ink,
            minimumSize: const Size(48, 48),
          ),
        ),
        listTileTheme: base.listTileTheme.copyWith(
          textColor: ink,
          iconColor: secondary,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: surface,
          hintStyle: text.bodyMedium?.copyWith(color: secondary),
          labelStyle: text.bodyMedium?.copyWith(color: secondary),
          floatingLabelStyle: text.bodyMedium?.copyWith(color: accent),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        textSelectionTheme: base.textSelectionTheme.copyWith(
          cursorColor: accent,
          selectionColor: accent.withValues(alpha: .25),
          selectionHandleColor: accent,
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: surface,
          selectedColor: Colors.black,
          secondarySelectedColor: Colors.black,
          disabledColor: surface,
          checkmarkColor: Colors.white,
          labelStyle: text.labelMedium?.copyWith(
            color: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Colors.white : ink),
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: text.labelMedium?.copyWith(color: Colors.white),
          side: BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
          color: accent,
          linearTrackColor: surface,
          circularTrackColor: surface,
        ),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
        popupMenuTheme: base.popupMenuTheme.copyWith(
          color: surface,
          textStyle: text.bodyMedium,
        ),
        dividerTheme: base.dividerTheme.copyWith(color: line),
        dividerColor: line,
      ),
      child: child,
    );
  }
}
