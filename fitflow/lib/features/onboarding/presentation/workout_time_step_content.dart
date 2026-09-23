import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workout time step: single-select list of typical durations.
class WorkoutTimeStepContent extends ConsumerWidget {
  const WorkoutTimeStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      children: [
        for (final duration in WorkoutDuration.values)
          OnboardingOptionCard(
            label: duration.label,
            selected: state.workoutDuration == duration,
            onSelected: () => controller.selectWorkoutDuration(duration),
          ),
      ],
    );
  }
}
