import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Equipment step: multi-select list of available equipment. Selecting
/// "None" clears everything else; selecting any item removes "None".
class EquipmentStepContent extends ConsumerWidget {
  const EquipmentStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      children: [
        for (final equipment in WorkoutEquipment.values)
          OnboardingOptionCard(
            label: equipmentLabel(context.l10n, equipment),
            selected: state.equipment.contains(equipment),
            multiSelect: true,
            onSelected: () => controller.toggleEquipment(equipment),
          ),
      ],
    );
  }
}
