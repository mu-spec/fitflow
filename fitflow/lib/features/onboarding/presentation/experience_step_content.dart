import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Experience step: single-select list of experience levels.
class ExperienceStepContent extends ConsumerWidget {
  const ExperienceStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      children: [
        for (final level in ExperienceLevel.values)
          OnboardingOptionCard(
            label: level.label,
            helperText: level.helperText,
            selected: state.experience == level,
            onSelected: () => controller.selectExperience(level),
          ),
      ],
    );
  }
}
