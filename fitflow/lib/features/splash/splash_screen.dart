import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
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
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  /// Splash → load persisted profiles → deterministic routing:
  /// No UserFitnessProfile → Onboarding
  /// UserFitnessProfile + no CapabilityProfile → Capability Assessment
  /// Both valid → Home
  /// Corrupt capability JSON is treated as null by storage, so goes to assessment.
  Future<void> _decideNextRoute() async {
    await Future<void>.delayed(AppConstants.splashDelay);

    bool hasUserProfile = false;
    bool hasCapabilityProfile = false;

    try {
      // Wait for both required persisted states before deciding route
      final results = await Future.wait([
        ref.read(userFitnessProfileProvider.future),
        ref.read(capabilityProfileProvider.future),
      ]);
      final userProfile = results[0];
      final capabilityProfile = results[1];
      hasUserProfile = userProfile != null;
      hasCapabilityProfile = capabilityProfile != null;
    } on Object {
      // If anything throws, treat as missing and fallback safely
      // hasUserProfile stays false if user load fails
      // For safety, try to load user profile individually
      try {
        hasUserProfile =
            await ref.read(userFitnessProfileProvider.future) != null;
      } on Object {
        hasUserProfile = false;
      }
      try {
        hasCapabilityProfile =
            await ref.read(capabilityProfileProvider.future) != null;
      } on Object {
        hasCapabilityProfile = false;
      }
    }

    if (!mounted) {
      return;
    }

    if (!hasUserProfile) {
      context.go(AppRoutes.onboarding);
    } else if (!hasCapabilityProfile) {
      context.go(AppRoutes.capabilityAssessment);
    } else {
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
