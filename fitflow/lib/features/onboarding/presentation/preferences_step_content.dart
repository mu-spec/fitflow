import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'These preferences help FitFlow adapt workouts and are not '
            'medical advice.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final preference in WorkoutPreference.values)
          OnboardingOptionCard(
            label: preference.label,
            selected: state.preferences.contains(preference),
            multiSelect: true,
            onSelected: () => controller.togglePreference(preference),
          ),
      ],
    );
  }
}
