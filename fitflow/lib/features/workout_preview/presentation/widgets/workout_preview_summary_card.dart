import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_workout_media.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Real generated-session context, not a new workout identity or estimate.
class WorkoutPreviewSummaryCard extends StatelessWidget {
  const WorkoutPreviewSummaryCard(
      {super.key,
      required this.plan,
      required this.userProfile,
      this.effectiveDuration,
      this.sessionMode = WorkoutSessionMode.standard});
  final WorkoutPlan plan;
  final UserFitnessProfile userProfile;
  final WorkoutDuration? effectiveDuration;
  final WorkoutSessionMode sessionMode;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final v = FitFlowVisualV2.of(context);
    final equipment = plan.allPrescriptions
        .expand((p) => p.exercise.requiredEquipment)
        .where((e) => e != WorkoutEquipment.none)
        .toSet();
    return FitFlowV2HeroSurface(
      key: const ValueKey('v2_preview_summary'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('FITFLOW',
            style: text.labelSmall
                ?.copyWith(color: v.heroSecondary, letterSpacing: 1.5)),
        const SizedBox(height: FitFlowSpace.xs),
        Text(fitnessGoalLabel(l, userProfile.goal),
            style: text.labelLarge?.copyWith(color: v.heroSecondary)),
        const SizedBox(height: FitFlowSpace.xs),
        Semantics(
          header: true,
          child: Text(l.homeSession,
              style: text.headlineMedium?.copyWith(color: v.onHero)),
        ),
        const SizedBox(height: FitFlowSpace.md),
        FitFlowV2WorkoutMedia(
            key: const ValueKey('v2_preview_media'),
            height: WorkoutV2Layout.mediaHeight(context),
            onHero: true),
        const SizedBox(height: FitFlowSpace.md),
        Text(
            l.flowTarget(
                (effectiveDuration ?? userProfile.workoutDuration).minutes),
            style: text.titleLarge?.copyWith(color: v.onHero)),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
            '${l.flowCount(plan.totalExerciseCount)} · ${l.flowEstimate(plannedDuration(l, plan.estimatedDuration))}',
            style: text.bodyMedium?.copyWith(color: v.onHero)),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
            equipment.isEmpty
                ? l.flowNoEquipment
                : equipment.map((e) => equipmentLabel(l, e)).join(', '),
            style: text.bodySmall?.copyWith(color: v.heroSecondary)),
        const SizedBox(height: FitFlowSpace.sm),
        Text(
            sessionMode == WorkoutSessionMode.standard
                ? sessionModeLabel(l, sessionMode)
                : l.flowModeTemporary(sessionModeLabel(l, sessionMode)),
            style: text.labelMedium?.copyWith(color: v.heroSecondary)),
      ]),
    );
  }
}
