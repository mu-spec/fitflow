import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/home/presentation/widgets/home_detail_row.dart';
import 'package:fitflow/features/home/presentation/widgets/home_adaptive_explanation.dart';
import 'package:fitflow/features/home/presentation/widgets/home_movement_focus.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Supporting workout and saved setup details share one native disclosure.
class HomePersonalizationCard extends StatelessWidget {
  const HomePersonalizationCard(
      {super.key, required this.userProfile, this.plan});
  final UserFitnessProfile userProfile;
  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final meaningful =
        userProfile.equipment.where((e) => e != WorkoutEquipment.none);
    final equipment = meaningful.isEmpty
        ? l.quickNoEquipment
        : meaningful.map((e) => equipmentLabel(l, e)).join(', ');
    final prefs = userProfile.preferences.isEmpty
        ? l.homeNoPreferences
        : userProfile.preferences.map((p) => preferenceLabel(l, p)).join(' · ');
    Widget fact(String label, String value) =>
        HomeDetailRow(label: label, value: value);
    Widget count(String label, int value) => Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Text('$value $label', style: text.bodyMedium));
    return ExpansionTile(
      key: const PageStorageKey('home_setup'),
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      expansionAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context)),
      title: Text(l.homeSetupHint,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan != null) ...[
          Wrap(
              spacing: FitFlowSpace.md,
              runSpacing: FitFlowSpace.xs,
              children: [
                count(l.homeWarmup, plan!.warmup.exerciseCount),
                count(l.homeMain, plan!.main.exerciseCount),
                count(l.homeCooldown, plan!.cooldown.exerciseCount),
              ]),
          const SizedBox(height: FitFlowSpace.sm),
          HomeMovementFocus(plan: plan!),
        ],
        fact(l.homeGoal, fitnessGoalLabel(l, userProfile.goal)),
        fact(l.homeEnvironment, environmentLabel(l, userProfile.environment)),
        fact(l.homeUsualTime,
            workoutDurationLabel(l, userProfile.workoutDuration)),
        fact(l.homeEquipment, equipment),
        fact(l.homePreferences, prefs),
        const SizedBox(height: FitFlowSpace.sm),
        ExpansionTile(
          key: const PageStorageKey('home_chosen_explanation'),
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(l.homeHowChosen, style: text.bodyMedium),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            HomeAdaptiveExplanation(),
            SizedBox(height: FitFlowSpace.sm),
          ],
        ),
      ],
    );
  }
}
