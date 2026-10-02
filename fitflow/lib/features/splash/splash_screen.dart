import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/splash/startup_destination.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  /// Loads one persisted startup value independently, converting thrown
  /// errors into [StartupLoadState.failed] so a transient read failure is
  /// distinguishable from a genuinely missing value.
  Future<StartupLoadState> _loadState(Future<Object?> Function() load) async {
    try {
      final value = await load();
      return value != null
          ? StartupLoadState.present
          : StartupLoadState.missing;
    } on Object {
      return StartupLoadState.failed;
    }
  }

  /// Splash → load required persisted state concurrently → deterministic
  /// routing with no artificial delay:
  /// No UserFitnessProfile → Onboarding
  /// UserFitnessProfile + no CapabilityProfile → Capability Assessment
  /// Both valid → Home
  ///
  /// Only the two routing dependencies are awaited. Reminders, notification
  /// scheduling, TTS, backup, history analytics, and Programs never block
  /// this decision.
  Future<void> _decideNextRoute() async {
    final results = await Future.wait([
      _loadState(() => ref.read(userFitnessProfileProvider.future)),
      _loadState(() => ref.read(capabilityProfileProvider.future)),
    ]);

    final destination = decideStartupDestination(
      userProfile: results[0],
      capabilityProfile: results[1],
    );

    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;

    switch (destination) {
      case StartupDestination.onboarding:
        context.go(AppRoutes.onboarding);
      case StartupDestination.capabilityAssessment:
        context.go(AppRoutes.capabilityAssessment);
      case StartupDestination.home:
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
