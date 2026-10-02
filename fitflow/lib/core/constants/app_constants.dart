class AppConstants {
  AppConstants._();

  static const String appName = 'FitFlow';
  static const String tagline = 'Workouts that adapt to you.';

  /// Legacy settling budget kept for test pumps only.
  ///
  /// Startup no longer waits any fixed delay: the splash routes as soon as
  /// the required persisted state resolves (M21 Part 1). Do not reintroduce
  /// an artificial startup delay.
  static const Duration splashDelay = Duration(milliseconds: 1500);
}
