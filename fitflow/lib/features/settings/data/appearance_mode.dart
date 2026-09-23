import 'package:flutter/material.dart';

/// The appearance modes the user can select in Settings.
enum AppearanceMode {
  system,
  light,
  dark;

  ThemeMode toThemeMode() => switch (this) {
        system => ThemeMode.system,
        light => ThemeMode.light,
        dark => ThemeMode.dark,
      };

  /// Parses a persisted value, falling back to [system] for unknown input.
  static AppearanceMode fromString(String? value) {
    return values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => system,
    );
  }
}
