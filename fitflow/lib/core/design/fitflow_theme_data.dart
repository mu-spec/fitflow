import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_typography.dart';
import 'package:flutter/material.dart';

/// Builds the light and dark [ThemeData] from semantic tokens.
class FitFlowThemeData {
  const FitFlowThemeData._();

  static ThemeData get light => _build(FitFlowColors.light, FitFlowTheme.light);

  static ThemeData get dark => _build(FitFlowColors.dark, FitFlowTheme.dark);

  static ThemeData _build(FitFlowPalette palette, FitFlowTheme extension) {
    final isDark = palette == FitFlowColors.dark;
    final textTheme = FitFlowTypography.textTheme().apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );
    final colorScheme = _colorScheme(palette, isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [extension],
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: SystemMotionTheme.transitions(reducedMotion: false),
      dividerColor: palette.divider,
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FitFlowRadius.cardBorder,
          side: BorderSide(color: palette.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.brand.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: _overlay(palette),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.brand : palette.textSecondary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? palette.brand : palette.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        indicatorColor: palette.brand.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: palette.brand, size: 24),
        unselectedIconTheme:
            IconThemeData(color: palette.textSecondary, size: 24),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.brand,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        minWidth: 80,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(palette),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(palette),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle(palette),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: palette.textPrimary,
        ).copyWith(overlayColor: _overlay(palette)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.subtleSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.error),
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
        focusedBorder: _inputBorder(palette.brand, width: 2),
        errorBorder: _inputBorder(palette.error),
        focusedErrorBorder: _inputBorder(palette.error, width: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.subtleSurface,
        selectedColor: palette.brandContainer,
        disabledColor: palette.subtleSurface.withValues(alpha: 0.6),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: palette.textPrimary,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: palette.onBrandContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: palette.border),
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: palette.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: FitFlowRadius.cardBorder,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: palette.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: FitFlowRadius.sheetBorder,
        ),
        showDragHandle: false,
        dragHandleColor: palette.border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.brand,
        linearTrackColor: palette.subtleSurface,
        circularTrackColor: palette.subtleSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isDark ? palette.elevatedSurface : palette.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? palette.textPrimary : palette.background,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: FitFlowRadius.mediumBorder,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: textTheme.labelMedium?.copyWith(color: palette.background),
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: FitFlowRadius.smallBorder,
        ),
      ),
    );
  }

  static ColorScheme _colorScheme(FitFlowPalette palette, bool isDark) {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: palette.brand,
      onPrimary: palette.onBrand,
      primaryContainer: palette.brandContainer,
      onPrimaryContainer: palette.onBrandContainer,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.accentContainer,
      onSecondaryContainer: palette.onAccentContainer,
      tertiary: palette.info,
      onTertiary: palette.onInfo,
      tertiaryContainer: palette.subtleSurface,
      onTertiaryContainer: palette.textPrimary,
      error: palette.error,
      onError: palette.onError,
      errorContainer: palette.errorContainer,
      onErrorContainer: palette.onErrorContainer,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.divider,
      shadow: const Color(0xFF13211C),
      scrim: const Color(0xFF13211C),
      inverseSurface: isDark ? palette.textPrimary : const Color(0xFF24312C),
      onInverseSurface: isDark ? palette.background : const Color(0xFFF2F6F4),
      inversePrimary:
          isDark ? FitFlowColors.brandPrimary : const Color(0xFF7ED9C4),
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: isDark ? palette.background : palette.surface,
      surfaceContainerLow:
          isDark ? const Color(0xFF121916) : const Color(0xFFF7FAF8),
      surfaceContainer: isDark ? palette.surface : const Color(0xFFEEF3F0),
      surfaceContainerHigh:
          isDark ? palette.elevatedSurface : palette.subtleSurface,
      surfaceContainerHighest:
          isDark ? const Color(0xFF24302B) : const Color(0xFFDCE6E1),
    );
  }

  static ButtonStyle _filledStyle(FitFlowPalette palette) {
    return FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      elevation: 0,
      backgroundColor: palette.brand,
      foregroundColor: palette.onBrand,
      disabledBackgroundColor: palette.subtleSurface,
      disabledForegroundColor: palette.textMuted,
      textStyle: FitFlowTypography.label,
      shape: const RoundedRectangleBorder(
        borderRadius: FitFlowRadius.mediumBorder,
      ),
    ).copyWith(
      overlayColor: _overlay(palette, on: palette.onBrand),
      side: _focusSide(palette),
    );
  }

  static ButtonStyle _outlinedStyle(FitFlowPalette palette) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: palette.brand,
      disabledForegroundColor: palette.textMuted,
      textStyle: FitFlowTypography.label,
      side: BorderSide(color: palette.border),
      shape: const RoundedRectangleBorder(
        borderRadius: FitFlowRadius.mediumBorder,
      ),
    ).copyWith(
      overlayColor: _overlay(palette),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: palette.border.withValues(alpha: 0.6));
        }
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: palette.focus, width: 2);
        }
        return BorderSide(color: palette.brand);
      }),
    );
  }

  static ButtonStyle _textStyle(FitFlowPalette palette) {
    return TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: palette.brand,
      disabledForegroundColor: palette.textMuted,
      textStyle: FitFlowTypography.label,
      shape: const RoundedRectangleBorder(
        borderRadius: FitFlowRadius.mediumBorder,
      ),
    ).copyWith(
      overlayColor: _overlay(palette),
      side: _focusSide(palette),
    );
  }

  static WidgetStateProperty<Color?> _overlay(
    FitFlowPalette palette, {
    Color? on,
  }) {
    final color = on ?? palette.brand;
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: 0.08);
      }
      return null;
    });
  }

  static WidgetStateProperty<BorderSide?> _focusSide(FitFlowPalette palette) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: palette.focus, width: 2);
      }
      return BorderSide.none;
    });
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: FitFlowRadius.mediumBorder,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
