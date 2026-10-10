import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_choice.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferences step: optional multi-select of workout preferences. The user
/// may continue with no selections.
class PreferencesStepContent extends ConsumerWidget {
  const PreferencesStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
          child: Text(
            context.l10n.onboardingPreferencesNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final preference in WorkoutPreference.values)
          OnboardingChoice(
            label: preferenceLabel(context.l10n, preference),
            selected: state.preferences.contains(preference),
            multiSelect: true,
            onSelected: () => controller.togglePreference(preference),
          ),
      ],
    );
  }
}
