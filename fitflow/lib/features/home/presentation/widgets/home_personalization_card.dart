import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
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
    final colors = FitFlowTheme.of(context);
    final meaningful =
        userProfile.equipment.where((e) => e != WorkoutEquipment.none);
    final equipment = meaningful.isEmpty
        ? l.quickNoEquipment
        : meaningful.map((e) => equipmentLabel(l, e)).join(', ');
    final prefs = userProfile.preferences.isEmpty
        ? l.homeNoPreferences
        : userProfile.preferences.map((p) => preferenceLabel(l, p)).join(' · ');
    Widget fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
        child: LayoutBuilder(builder: (context, constraints) {
          final labelWidget = Text(label,
              style: text.bodySmall?.copyWith(color: colors.textSecondary));
          final valueWidget = Text(value, style: text.bodyMedium);
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 22) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelWidget,
                  const SizedBox(height: FitFlowSpace.xxs),
                  valueWidget,
                ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 104, child: labelWidget),
            const SizedBox(width: FitFlowSpace.sm),
            Expanded(child: valueWidget),
          ]);
        }));
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
              spacing: FitFlowSpace.lg,
              runSpacing: FitFlowSpace.xs,
              children: [
                count(l.homeWarmup, plan!.warmup.exerciseCount),
                count(l.homeMain, plan!.main.exerciseCount),
                count(l.homeCooldown, plan!.cooldown.exerciseCount),
              ]),
          const SizedBox(height: FitFlowSpace.sm),
          Text(l.homeAdaptation, style: text.bodyMedium),
          const SizedBox(height: FitFlowSpace.md),
          HomeMovementFocus(plan: plan!),
          const SizedBox(height: FitFlowSpace.md),
        ],
        Semantics(
            header: true,
            child: Text(l.homeBuiltForYou, style: text.titleMedium)),
        const SizedBox(height: FitFlowSpace.md),
        fact(l.homeGoal, fitnessGoalLabel(l, userProfile.goal)),
        fact(l.homeEnvironment, environmentLabel(l, userProfile.environment)),
        fact(l.homeUsualTime,
            workoutDurationLabel(l, userProfile.workoutDuration)),
        fact(l.homeEquipment, equipment),
        fact(l.homePreferences, prefs),
        const SizedBox(height: FitFlowSpace.sm),
        const HomeAdaptiveExplanation(),
      ],
    );
  }
}
