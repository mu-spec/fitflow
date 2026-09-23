import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Environment step: single-select list of training environments.
class EnvironmentStepContent extends ConsumerWidget {
  const EnvironmentStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      children: [
        for (final environment in TrainingEnvironment.values)
          OnboardingOptionCard(
            label: environment.label,
            selected: state.environment == environment,
            onSelected: () => controller.selectEnvironment(environment),
          ),
      ],
    );
  }
}
