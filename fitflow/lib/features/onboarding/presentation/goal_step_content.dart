import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Goal step: single-select list of training goals.
class GoalStepContent extends ConsumerWidget {
  const GoalStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      children: [
        for (final goal in FitnessGoal.values)
          OnboardingOptionCard(
            label: goal.label,
            selected: state.goal == goal,
            onSelected: () => controller.selectGoal(goal),
          ),
      ],
    );
  }
}
