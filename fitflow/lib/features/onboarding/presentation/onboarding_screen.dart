import 'setup_photo_background.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:fitflow/features/onboarding/presentation/environment_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/equipment_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/experience_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/goal_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_shell.dart';
import 'package:fitflow/features/onboarding/presentation/preferences_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:fitflow/features/onboarding/presentation/workout_time_step_content.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
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
  int _index = 0;
  bool _saving = false;
  String? _saveError;

  bool get _isLastPage => _index == OnboardingPages.all.length - 1;

  void _showPreviousPage() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  void _showNextPage() {
    if (_isLastPage) {
      _finishOnboarding();
      return;
    }
    setState(() => _index++);
  }

  /// Builds and persists the [UserFitnessProfile] from the completed
  /// selections, then opens Movement Check. Only navigates when the profile
  /// was saved. Capability profile is created in the dedicated assessment screen.
  Future<void> _finishOnboarding() async {
    final profile =
        ref.read(onboardingControllerProvider).toUserFitnessProfile();
    if (profile == null) {
      return;
    }

    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    bool saved;
    try {
      saved = await ref
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(profile);
    } on Object {
      saved = false;
    }
    if (!mounted) return;
    if (!saved) {
      setState(() {
        _saving = false;
        _saveError = context.l10n.onboardingSaveError;
      });
      return;
    }
    context.go(AppRoutes.capabilityAssessment);
  }

  bool _canContinue(OnboardingState state) {
    return switch (OnboardingPages.all[_index].id) {
      'goal' => state.goal != null,
      'experience' => state.experience != null,
      'workout_time' => state.workoutDuration != null,
      'environment' => state.environment != null,
      'equipment' => state.equipment.isNotEmpty,
      _ => true,
    };
  }

  Widget _buildContent(OnboardingPage page) {
    final body = onboardingBody(context.l10n, page.id);
    return switch (page.id) {
      'welcome' => const OnboardingIntro(),
      'goal' => const GoalStepContent(),
      'experience' => const ExperienceStepContent(),
      'workout_time' => const WorkoutTimeStepContent(),
      'environment' => const EnvironmentStepContent(),
      'equipment' => const EquipmentStepContent(),
      'preferences' => const PreferencesStepContent(),
      'ready' => SetupPhotoPanel(child: Text(body ?? '')),
      _ => const SizedBox.shrink(),
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
      title: onboardingTitle(context.l10n, page.id),
      content: _buildContent(page),
      description: switch (page.id) {
        'welcome' => context.l10n.onboardingWelcomeBody,
        'goal' => context.l10n.onboardingGoalHelp,
        'experience' => context.l10n.onboardingExperienceHelp,
        'workout_time' => context.l10n.onboardingTimeHelp,
        'environment' => context.l10n.onboardingEnvironmentHelp,
        'equipment' => context.l10n.onboardingEquipmentHelp,
        'preferences' => context.l10n.onboardingPreferencesHelp,
        'ready' => context.l10n.onboardingReadyHelp,
        _ => null,
      },
      instruction: {'goal', 'experience', 'workout_time', 'environment'}
              .contains(page.id)
          ? context.l10n.onboardingSingleChoice
          : null,
      saving: _saving,
      error: _saveError,
      canGoBack: _index > 0,
      canContinue: _canContinue(state),
      trailingLabel:
          _isLastPage ? context.l10n.getStarted : context.l10n.continueLabel,
      onBack: _showPreviousPage,
      onContinue: _showNextPage,
    );
  }
}
