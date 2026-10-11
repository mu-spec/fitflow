import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/home/presentation/widgets/home_adaptive_explanation.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Real goal and environment are visible; remaining saved setup stays disclosed.
class HomePersonalizationCard extends StatelessWidget {
  const HomePersonalizationCard({super.key, required this.userProfile});
  final UserFitnessProfile userProfile;

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
    Widget fact(String label, String value, {IconData? icon}) =>
        FitFlowV2InfoSurface(
            tonal: true,
            padding: const EdgeInsets.all(FitFlowSpace.sm),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                      child: Icon(icon, size: 18, color: colors.brand)),
                  const SizedBox(width: FitFlowSpace.xs),
                ],
                Expanded(
                    child: Text(label,
                        style: text.labelMedium
                            ?.copyWith(color: colors.textSecondary))),
              ]),
              const SizedBox(height: FitFlowSpace.xs),
              Text(value, style: text.titleSmall),
            ]));
    return FitFlowV2InfoSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
          header: true,
          child: Text(l.homeBuiltForYou, style: text.titleMedium)),
      const SizedBox(height: FitFlowSpace.md),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 &&
            MediaQuery.textScalerOf(context).scale(16) <= 22;
        final width = columns
            ? (constraints.maxWidth - FitFlowSpace.sm) / 2
            : constraints.maxWidth;
        return Wrap(
            spacing: FitFlowSpace.sm,
            runSpacing: FitFlowSpace.sm,
            children: [
              SizedBox(
                  width: width,
                  child: fact(l.homeGoal, fitnessGoalLabel(l, userProfile.goal),
                      icon: Icons.flag_outlined)),
              SizedBox(
                  width: width,
                  child: fact(l.homeEnvironment,
                      environmentLabel(l, userProfile.environment),
                      icon: Icons.home_outlined)),
            ]);
      }),
      const SizedBox(height: FitFlowSpace.xs),
      ExpansionTile(
        key: const PageStorageKey('home_setup'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
        expansionAnimationStyle: AnimationStyle(
            duration: SystemMotion.standard(context),
            reverseDuration: SystemMotion.standard(context)),
        title: Text(l.homeSetupHint, style: text.labelLarge),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fact(l.homeUsualTime,
              workoutDurationLabel(l, userProfile.workoutDuration)),
          const SizedBox(height: FitFlowSpace.xs),
          fact(l.homeEquipment, equipment),
          const SizedBox(height: FitFlowSpace.xs),
          fact(l.homePreferences, prefs),
          const SizedBox(height: FitFlowSpace.md),
          const HomeAdaptiveExplanation(),
        ],
      ),
    ]));
  }
}
