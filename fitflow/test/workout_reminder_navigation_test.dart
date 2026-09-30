import 'package:fitflow/app/app.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/reminders/application/workout_reminder_navigation.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  late List<String> navigated;
  late bool ready;
  late String location;
  DateTime now = DateTime.utc(2026, 9, 30, 12);

  WorkoutReminderNavigationCoordinator make() => WorkoutReminderNavigationCoordinator(
        isRouterReady: () => ready,
        currentLocation: () => location,
        navigate: (route) {
          navigated.add(route);
          location = route;
        },
        clock: () => now,
      );

  setUp(() {
    navigated = [];
    ready = true;
    location = AppRoutes.workouts;
    now = DateTime.utc(2026, 9, 30, 12);
  });

  test('workout_reminder payload → Home', () {
    final c = make();
    c.handlePayload('workout_reminder');
    expect(navigated, [AppRoutes.home]);
    expect(WorkoutReminderNavigationCoordinator.destinationFor('workout_reminder'), AppRoutes.home);
  });

  test('unknown / null payload ignored safely', () {
    final c = make();
    c.handlePayload(null);
    c.handlePayload('');
    c.handlePayload('program_session:balanced_foundations_w1_s1');
    c.handlePayload('WORKOUT_REMINDER');
    expect(navigated, isEmpty);
    expect(c.pendingDestination, isNull);
  });

  test('duplicate response does not duplicate navigation', () {
    final c = make();
    c.handlePayload('workout_reminder');
    c.handlePayload('workout_reminder'); // same tap reported twice
    now = now.add(const Duration(milliseconds: 500));
    c.handlePayload('workout_reminder');
    expect(navigated, [AppRoutes.home]);
    expect(c.navigationCount, 1);
    // A genuinely new tap later (already at Home) → no redundant navigation.
    now = now.add(const Duration(seconds: 5));
    c.handlePayload('workout_reminder');
    expect(navigated, [AppRoutes.home]);
    // New tap from another tab later → navigates again exactly once.
    location = AppRoutes.progress;
    now = now.add(const Duration(seconds: 5));
    c.handlePayload('workout_reminder');
    expect(navigated, [AppRoutes.home, AppRoutes.home]);
  });

  test('pending launch response retained until router ready, processed once', () {
    ready = false;
    location = AppRoutes.splash;
    final c = make();
    c.handlePayload('workout_reminder');
    expect(navigated, isEmpty);
    expect(c.pendingDestination, AppRoutes.home);
    c.processPending();
    c.processPending();
    expect(navigated, isEmpty, reason: 'startup safety: never bypass splash');
    // Splash routed the user into the shell (e.g. Home).
    ready = true;
    location = AppRoutes.home;
    c.processPending();
    expect(navigated, isEmpty, reason: 'already at destination');
    expect(c.pendingDestination, isNull);
    c.processPending();
    expect(navigated, isEmpty);
  });

  test('pending response delivered once when the shell becomes ready on another tab', () {
    ready = false;
    location = AppRoutes.onboarding;
    final c = make();
    c.handlePayload('workout_reminder');
    ready = true;
    location = AppRoutes.workouts;
    c.processPending();
    c.processPending();
    expect(navigated, [AppRoutes.home]);
  });

  test('shell location detection', () {
    expect(WorkoutReminderNavigationCoordinator.isShellLocation(AppRoutes.home), isTrue);
    expect(WorkoutReminderNavigationCoordinator.isShellLocation('/workouts/programs/x'), isTrue);
    expect(WorkoutReminderNavigationCoordinator.isShellLocation(AppRoutes.splash), isFalse);
    expect(WorkoutReminderNavigationCoordinator.isShellLocation(AppRoutes.onboarding), isFalse);
    expect(WorkoutReminderNavigationCoordinator.isShellLocation(AppRoutes.capabilityAssessment), isFalse);
  });

  testWidgets('app startup remains safe with reminders wired (no profile → onboarding)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeWorkoutReminderNotificationService()
      ..launchPayload = 'workout_reminder';
    await tester.pumpWidget(ProviderScope(
      overrides: reminderOverrides(service: service),
      child: const FitFlowApp(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Launch tap never bypasses onboarding.
    expect(find.byType(FitFlowApp), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(service.permissionRequests, 0, reason: 'never on first launch');
    expect(service.scheduled, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('launch tap with complete profile lands on Home exactly via normal startup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeWorkoutReminderNotificationService();
    await tester.pumpWidget(ProviderScope(
      overrides: reminderOverrides(service: service),
      child: const FitFlowApp(),
    ));
    await completeOnboardingToHome(tester);
    // Foreground tap while on another tab → back to Home, once.
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    service.taps.add('workout_reminder');
    await tester.pumpAndSettle();
    expect(find.text('View workout'), findsOneWidget);
    service.taps.add('workout_reminder');
    await tester.pumpAndSettle();
    expect(find.text('View workout'), findsOneWidget);
    expect(service.permissionRequests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resume triggers a status refresh through the controller, not a permission request', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeWorkoutReminderNotificationService();
    await tester.pumpWidget(ProviderScope(
      overrides: reminderOverrides(service: service),
      child: const FitFlowApp(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final before = service.permissionQueries;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(service.permissionQueries, greaterThan(before));
    expect(service.permissionRequests, 0);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  test('controller provider default clock is DateTime.now-like', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final clock = container.read(workoutReminderClockProvider);
    expect(clock().difference(DateTime.now()).inSeconds.abs() < 5, isTrue);
  });
}
