import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_choice.dart';
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
          OnboardingChoice(
            label: environmentLabel(context.l10n, environment),
            icon: switch (environment) {
              TrainingEnvironment.apartment => Icons.volume_down_outlined,
              TrainingEnvironment.normalHome => Icons.home_outlined,
              TrainingEnvironment.smallRoom => Icons.crop_square_rounded,
              TrainingEnvironment.largeRoom => Icons.aspect_ratio_rounded,
              TrainingEnvironment.hotel => Icons.luggage_outlined,
              TrainingEnvironment.outdoor => Icons.park_outlined,
            },
            selected: state.environment == environment,
            onSelected: () => controller.selectEnvironment(environment),
          ),
      ],
    );
  }
}
