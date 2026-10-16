import 'package:flutter/material.dart';

/// FitFlow presentation tokens. Dark brand values follow the Phase 1 written
/// brief; final visual-reference matching is pending reference delivery.
///
/// [brandPrimary] is a working brand color, not a locked logo color. Later
/// branding can replace this one constant without scattering raw values.
class FitFlowColors {
  const FitFlowColors._();

  /// Provisional brand teal. Swap this before Play release if branding changes.
  static const Color brandPrimary = Color(0xFF0E6B5A);

  static const FitFlowPalette light = FitFlowPalette(
    brand: brandPrimary,
    onBrand: Color(0xFFFFFFFF),
    brandContainer: Color(0xFFD5F0E8),
    onBrandContainer: Color(0xFF06382F),
    accent: Color(0xFF8A4E16),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFF6E4D4),
    onAccentContainer: Color(0xFF3E240C),
    background: Color(0xFFF4F6F3),
    surface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFFFFFFF),
    subtleSurface: Color(0xFFE7EEEA),
    textPrimary: Color(0xFF13211C),
    textSecondary: Color(0xFF3C5249),
    textMuted: Color(0xFF536862),
    border: Color(0xFFD5E0DA),
    divider: Color(0xFFE3EBE7),
    success: Color(0xFF1B7A46),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF7A4E0E),
    onWarning: Color(0xFFFFFFFF),
    error: Color(0xFFB42318),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9D9D6),
    onErrorContainer: Color(0xFF410E0B),
    info: Color(0xFF1D5C86),
    onInfo: Color(0xFFFFFFFF),
    workoutActive: brandPrimary,
    onWorkoutActive: Color(0xFFFFFFFF),
    workoutRest: Color(0xFF2C5874),
    onWorkoutRest: Color(0xFFFFFFFF),
    progress: Color(0xFF7A4E0E),
    onProgress: Color(0xFFFFFFFF),
    focus: Color(0xFF13211C),
  );

  static const FitFlowPalette dark = FitFlowPalette(
    brand: Color(0xFF67E8C3),
    onBrand: Color(0xFF06241C),
    brandContainer: Color(0xFF163C32),
    onBrandContainer: Color(0xFFD5F0E8),
    accent: Color(0xFF45BFA6),
    onAccent: Color(0xFF06241C),
    accentContainer: Color(0xFF123A31),
    onAccentContainer: Color(0xFFC3EEE1),
    background: Color(0xFF0B1210),
    surface: Color(0xFF141E19),
    elevatedSurface: Color(0xFF202D25),
    subtleSurface: Color(0xFF19251F),
    textPrimary: Color(0xFFF3F7F4),
    textSecondary: Color(0xFFB9C7BF),
    textMuted: Color(0xFF97ACA0),
    border: Color(0xFF304138),
    divider: Color(0xFF25362C),
    success: Color(0xFF7DCEA0),
    onSuccess: Color(0xFF06241C),
    warning: Color(0xFFE0B15A),
    onWarning: Color(0xFF2A1C06),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF410E0B),
    errorContainer: Color(0xFF5C1A16),
    onErrorContainer: Color(0xFFF9D9D6),
    info: Color(0xFF9ECAE8),
    onInfo: Color(0xFF0C2433),
    workoutActive: Color(0xFF67E8C3),
    onWorkoutActive: Color(0xFF06241C),
    workoutRest: Color(0xFF8EB4D4),
    onWorkoutRest: Color(0xFF0C2433),
    progress: Color(0xFFE0B15A),
    onProgress: Color(0xFF2A1C06),
    focus: Color(0xFFF2F6F4),
  );
}

/// Semantic colors for one brightness.
class FitFlowPalette {
  const FitFlowPalette({
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.subtleSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.info,
    required this.onInfo,
    required this.workoutActive,
    required this.onWorkoutActive,
    required this.workoutRest,
    required this.onWorkoutRest,
    required this.progress,
    required this.onProgress,
    required this.focus,
  });

  final Color brand;
  final Color onBrand;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color subtleSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color info;
  final Color onInfo;
  final Color workoutActive;
  final Color onWorkoutActive;
  final Color workoutRest;
  final Color onWorkoutRest;
  final Color progress;
  final Color onProgress;
  final Color focus;
}
