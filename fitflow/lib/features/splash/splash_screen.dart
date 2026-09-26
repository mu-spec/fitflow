import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> _decideNextRoute() async {
    if (kDebugMode) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    } else {
      await Future<void>.delayed(AppConstants.splashDelay);
    }
    bool hasProfile;
    try {
      hasProfile = await ref.read(userFitnessProfileProvider.future) != null;
    } on Object {
      hasProfile = false;
    }
    if (!mounted) return;
    context.go(hasProfile ? AppRoutes.home : AppRoutes.onboarding);
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
                Text(AppConstants.appName, textAlign: TextAlign.center, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                Text(AppConstants.tagline, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
