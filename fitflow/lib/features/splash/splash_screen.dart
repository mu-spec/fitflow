import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/splash/startup_destination.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String recoveryTitle = "We couldn't load your local data.";
  static const String recoveryBody =
      "Your data hasn't been changed. Try again.";
  static const String recoveryAction = 'Try again';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _loadFailed = false;
  bool _retryInFlight = false;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _loadAndRoute(invalidate: false);
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

  /// Re-reads both required startup values. Does not clear, overwrite, or
  /// create profile data. Overlapping taps are ignored.
  Future<void> _retry() async {
    if (_navigated || _retryInFlight) return;
    _retryInFlight = true;
    if (mounted) setState(() {});
    try {
      await _loadAndRoute(invalidate: true);
    } finally {
      if (!_navigated) {
        _retryInFlight = false;
        if (mounted) setState(() {});
      }
    }
  }

  /// Splash → load required persisted state concurrently → deterministic
  /// routing with no artificial delay:
  /// No UserFitnessProfile → Onboarding
  /// UserFitnessProfile + no CapabilityProfile → Capability Assessment
  /// Both valid → Home
  /// Either required read threw → stay here and offer Try again
  ///
  /// Only the two routing dependencies are awaited. Reminders, notification
  /// scheduling, TTS, backup, history analytics, and Programs never block
  /// this decision.
  Future<void> _loadAndRoute({required bool invalidate}) async {
    if (_navigated) return;
    if (invalidate) {
      // Drop cached Riverpod errors so the next read actually hits storage.
      // Invalidation does not remove or rewrite preference keys.
      ref.invalidate(sharedPreferencesProvider);
      ref.invalidate(userFitnessProfileProvider);
      ref.invalidate(capabilityProfileProvider);
    }

    final results = await Future.wait([
      _loadState(() => ref.read(userFitnessProfileProvider.future)),
      _loadState(() => ref.read(capabilityProfileProvider.future)),
    ]);

    if (!mounted || _navigated) return;

    final destination = decideStartupDestination(
      userProfile: results[0],
      capabilityProfile: results[1],
    );

    if (destination == StartupDestination.recovery) {
      setState(() => _loadFailed = true);
      return;
    }

    _navigated = true;
    if (!mounted) return;
    switch (destination) {
      case StartupDestination.onboarding:
        context.go(AppRoutes.onboarding);
      case StartupDestination.capabilityAssessment:
        context.go(AppRoutes.capabilityAssessment);
      case StartupDestination.home:
        context.go(AppRoutes.home);
      case StartupDestination.recovery:
        break;
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
            child: _loadFailed
                ? _RecoveryBody(
                    theme: theme,
                    inFlight: _retryInFlight,
                    onRetry: _retry,
                  )
                : Column(
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

class _RecoveryBody extends StatelessWidget {
  const _RecoveryBody({
    required this.theme,
    required this.inFlight,
    required this.onRetry,
  });

  final ThemeData theme;
  final bool inFlight;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.splashRecoveryTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.splashRecoveryBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            enabled: !inFlight,
            label: context.l10n.splashRecoveryAction,
            hint: context.l10n.splashRecoveryHint,
            child: ExcludeSemantics(
              child: FilledButton(
                onPressed: inFlight ? null : onRetry,
                child: Text(context.l10n.splashRecoveryAction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
