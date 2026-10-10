import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:flutter/material.dart';

/// Semantic colors that [ColorScheme] does not name: workout phase, progress,
/// and the muted text/surface roles used by shared components.
class FitFlowTheme extends ThemeExtension<FitFlowTheme> {
  const FitFlowTheme(this.palette);

  final FitFlowPalette palette;

  static const FitFlowTheme light = FitFlowTheme(FitFlowColors.light);
  static const FitFlowTheme dark = FitFlowTheme(FitFlowColors.dark);

  static FitFlowTheme of(BuildContext context) {
    return Theme.of(context).extension<FitFlowTheme>() ?? light;
  }

  Color get brand => palette.brand;
  Color get onBrand => palette.onBrand;
  Color get accent => palette.accent;
  Color get background => palette.background;
  Color get surface => palette.surface;
  Color get elevatedSurface => palette.elevatedSurface;
  Color get subtleSurface => palette.subtleSurface;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  Color get textMuted => palette.textMuted;
  Color get border => palette.border;
  Color get divider => palette.divider;
  Color get success => palette.success;
  Color get onSuccess => palette.onSuccess;
  Color get warning => palette.warning;
  Color get onWarning => palette.onWarning;
  Color get error => palette.error;
  Color get onError => palette.onError;
  Color get info => palette.info;
  Color get onInfo => palette.onInfo;
  Color get workoutActive => palette.workoutActive;
  Color get onWorkoutActive => palette.onWorkoutActive;
  Color get workoutRest => palette.workoutRest;
  Color get onWorkoutRest => palette.onWorkoutRest;
  Color get progress => palette.progress;
  Color get onProgress => palette.onProgress;
  Color get focus => palette.focus;

  @override
  FitFlowTheme copyWith({FitFlowPalette? palette}) {
    return FitFlowTheme(palette ?? this.palette);
  }

  @override
  FitFlowTheme lerp(FitFlowTheme? other, double t) {
    if (other == null) return this;
    return FitFlowTheme(_lerpPalette(palette, other.palette, t));
  }
}

FitFlowPalette _lerpPalette(FitFlowPalette a, FitFlowPalette b, double t) {
  Color mix(Color left, Color right) => Color.lerp(left, right, t)!;
  return FitFlowPalette(
    brand: mix(a.brand, b.brand),
    onBrand: mix(a.onBrand, b.onBrand),
    brandContainer: mix(a.brandContainer, b.brandContainer),
    onBrandContainer: mix(a.onBrandContainer, b.onBrandContainer),
    accent: mix(a.accent, b.accent),
    onAccent: mix(a.onAccent, b.onAccent),
    accentContainer: mix(a.accentContainer, b.accentContainer),
    onAccentContainer: mix(a.onAccentContainer, b.onAccentContainer),
    background: mix(a.background, b.background),
    surface: mix(a.surface, b.surface),
    elevatedSurface: mix(a.elevatedSurface, b.elevatedSurface),
    subtleSurface: mix(a.subtleSurface, b.subtleSurface),
    textPrimary: mix(a.textPrimary, b.textPrimary),
    textSecondary: mix(a.textSecondary, b.textSecondary),
    textMuted: mix(a.textMuted, b.textMuted),
    border: mix(a.border, b.border),
    divider: mix(a.divider, b.divider),
    success: mix(a.success, b.success),
    onSuccess: mix(a.onSuccess, b.onSuccess),
    warning: mix(a.warning, b.warning),
    onWarning: mix(a.onWarning, b.onWarning),
    error: mix(a.error, b.error),
    onError: mix(a.onError, b.onError),
    errorContainer: mix(a.errorContainer, b.errorContainer),
    onErrorContainer: mix(a.onErrorContainer, b.onErrorContainer),
    info: mix(a.info, b.info),
    onInfo: mix(a.onInfo, b.onInfo),
    workoutActive: mix(a.workoutActive, b.workoutActive),
    onWorkoutActive: mix(a.onWorkoutActive, b.onWorkoutActive),
    workoutRest: mix(a.workoutRest, b.workoutRest),
    onWorkoutRest: mix(a.onWorkoutRest, b.onWorkoutRest),
    progress: mix(a.progress, b.progress),
    onProgress: mix(a.onProgress, b.onProgress),
    focus: mix(a.focus, b.focus),
  );
}
