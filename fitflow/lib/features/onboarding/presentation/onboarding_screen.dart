import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:fitflow/features/onboarding/presentation/environment_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/experience_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/goal_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_shell.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_placeholder.dart';
import 'package:fitflow/features/onboarding/presentation/workout_time_step_content.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onboarding flow: walks through the steps, then opens Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const String _getStartedLabel = 'Get Started';
  static const String _continueLabel = 'Continue';

  int _index = 0;

  bool get _isLastPage => _index == OnboardingPages.all.length - 1;

  void _showPreviousPage() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  void _showNextPage() {
    if (_isLastPage) {
      context.go(AppRoutes.home);
      return;
    }
    setState(() => _index++);
  }

  bool _canContinue(OnboardingState state) {
    return switch (OnboardingPages.all[_index].id) {
      'goal' => state.goal != null,
      'experience' => state.experience != null,
      'workout_time' => state.workoutDuration != null,
      'environment' => state.environment != null,
      _ => true,
    };
  }

  Widget _buildContent(OnboardingPage page) {
    final body = page.body;
    return switch (page.id) {
      'goal' => const GoalStepContent(),
      'experience' => const ExperienceStepContent(),
      'workout_time' => const WorkoutTimeStepContent(),
      'environment' => const EnvironmentStepContent(),
      _ => body != null ? Text(body) : const OnboardingPlaceholder(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final pages = OnboardingPages.all;
    final page = pages[_index];

    return OnboardingShell(
      step: _index + 1,
      totalSteps: pages.length,
      title: page.title,
      content: _buildContent(page),
      canGoBack: _index > 0,
      canContinue: _canContinue(state),
      trailingLabel: _isLastPage ? _getStartedLabel : _continueLabel,
      onBack: _showPreviousPage,
      onContinue: _showNextPage,
    );
  }
}
