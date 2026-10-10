import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/home/presentation/widgets/home_adaptive_explanation.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Progressive disclosure keeps the real setup available without duplicating it
/// at the same visual priority as today's effective workout.
class HomePersonalizationCard extends StatelessWidget {
  const HomePersonalizationCard({super.key, required this.userProfile});
  final UserFitnessProfile userProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meaningful =
        userProfile.equipment.where((e) => e != WorkoutEquipment.none);
    final equipment = meaningful.isEmpty
        ? l10n.quickNoEquipment
        : meaningful.map((e) => equipmentLabel(l10n, e)).join(', ');
    final prefs = userProfile.preferences.isEmpty
        ? l10n.homeNoPreferences
        : userProfile.preferences
            .map((p) => preferenceLabel(l10n, p))
            .join(' · ');
    Widget fact(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: FitFlowTheme.of(context).textSecondary)),
            const SizedBox(height: FitFlowSpace.xxs),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ]),
        );
    return ExpansionTile(
      key: const PageStorageKey('home_setup'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: FitFlowSpace.md),
      title: Text(l10n.homeBuiltForYou,
          style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(l10n.homeSetupHint),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fact(l10n.homeGoal, fitnessGoalLabel(l10n, userProfile.goal)),
        fact(l10n.homeUsualTime,
            workoutDurationLabel(l10n, userProfile.workoutDuration)),
        fact(l10n.homeEnvironment,
            environmentLabel(l10n, userProfile.environment)),
        fact(l10n.homeEquipment, equipment),
        fact(l10n.homePreferences, prefs),
        const HomeAdaptiveExplanation(),
      ],
    );
  }
}
