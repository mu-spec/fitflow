class AppConstants {
  AppConstants._();

  static const String appName = 'Home Workout';
  static const String tagline = 'Workouts that adapt to you.';

  /// Requested minimum brand presentation on a successful cold startup.
  /// Storage failures and explicit retries do not wait for this presentation.
  static const Duration splashDelay = Duration(milliseconds: 5500);
}
