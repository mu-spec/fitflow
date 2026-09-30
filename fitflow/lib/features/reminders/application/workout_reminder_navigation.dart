import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';

/// Pure routing logic for notification taps.
///
/// - `workout_reminder` → [AppRoutes.home]; unknown payloads are ignored.
/// - Navigation only happens once the router is "ready" (inside the main
///   shell). While FitFlow is still on splash/onboarding/assessment, the
///   destination is retained and processed later — startup/profile safety
///   is never bypassed.
/// - Duplicate responses (same tap reported twice, or a tap while already at
///   the destination) never navigate twice.
class WorkoutReminderNavigationCoordinator {
  WorkoutReminderNavigationCoordinator({
    required bool Function() isRouterReady,
    required String Function() currentLocation,
    required void Function(String route) navigate,
    DateTime Function()? clock,
    this.duplicateWindow = const Duration(seconds: 2),
  })  : _isRouterReady = isRouterReady,
        _currentLocation = currentLocation,
        _navigate = navigate,
        _clock = clock ?? DateTime.now;

  final bool Function() _isRouterReady;
  final String Function() _currentLocation;
  final void Function(String route) _navigate;
  final DateTime Function() _clock;
  final Duration duplicateWindow;

  String? _pending;
  DateTime? _lastNavigatedAt;
  int _navigationCount = 0;

  String? get pendingDestination => _pending;
  int get navigationCount => _navigationCount;

  /// Maps a payload to a destination, or null when it should be ignored.
  static String? destinationFor(String? payload) =>
      payload == workoutReminderPayload ? AppRoutes.home : null;

  /// Handles a notification response (launch, foreground or background tap).
  void handlePayload(String? payload) {
    final destination = destinationFor(payload);
    if (destination == null) return;
    if (_pending == destination) return; // coalesce duplicates
    final last = _lastNavigatedAt;
    if (last != null && _clock().difference(last) < duplicateWindow) return;
    _pending = destination;
    processPending();
  }

  /// Attempts to deliver a retained destination. Call whenever the router
  /// location changes or the app finishes startup. Idempotent.
  void processPending() {
    final destination = _pending;
    if (destination == null || !_isRouterReady()) return;
    _pending = null;
    _lastNavigatedAt = _clock();
    if (_currentLocation() == destination) return; // already there
    _navigationCount++;
    _navigate(destination);
  }

  /// Routes inside the main shell where reminder navigation is safe.
  static const List<String> shellRoots = [
    AppRoutes.home,
    AppRoutes.workouts,
    AppRoutes.progress,
    AppRoutes.profile,
  ];

  static bool isShellLocation(String location) =>
      shellRoots.any((root) => location == root || location.startsWith('$root/'));
}
