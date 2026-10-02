import 'dart:async';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/reminders/application/workout_reminder_navigation.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FitFlowApp extends ConsumerStatefulWidget {
  const FitFlowApp({super.key});

  @override
  ConsumerState<FitFlowApp> createState() => _FitFlowAppState();
}

class _FitFlowAppState extends ConsumerState<FitFlowApp> {
  AppLifecycleListener? _lifecycle;
  StreamSubscription<String?>? _tapSubscription;
  WorkoutReminderNavigationCoordinator? _reminderNavigation;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // Notification infrastructure is initialised after the first frame and
    // is never awaited by startup; failures are non-fatal.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startReminders());
  }

  void _startReminders() {
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    _router = router;
    final coordinator = WorkoutReminderNavigationCoordinator(
      isRouterReady: () => WorkoutReminderNavigationCoordinator.isShellLocation(
          router.state.uri.path),
      currentLocation: () => router.state.uri.path,
      navigate: router.go,
    );
    _reminderNavigation = coordinator;
    router.routerDelegate.addListener(_onRouteChanged);

    final controller = ref.read(workoutRemindersControllerProvider.notifier);
    final service = ref.read(workoutReminderNotificationServiceProvider);
    _tapSubscription = service.tapPayloads.listen(coordinator.handlePayload);
    // ignore: discarded_futures
    controller.initialize().then((_) async {
      final launchPayload = await service.takeLaunchPayload();
      if (mounted) coordinator.handlePayload(launchPayload);
    }).catchError((_) {});
  }

  void _onRouteChanged() => _reminderNavigation?.processPending();

  void _onResume() {
    if (!mounted) return;
    // ignore: discarded_futures
    ref.read(workoutRemindersControllerProvider.notifier).onAppResumed();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _tapSubscription?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearanceMode = ref.watch(appearanceControllerProvider).value ??
        AppearanceMode.system;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appearanceMode.toThemeMode(),
      builder: (context, child) => SystemMotionTheme(
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
