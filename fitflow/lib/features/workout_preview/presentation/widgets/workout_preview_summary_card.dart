import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/core/design/widgets/fitflow_surfaces.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

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
    final equipment = plan.allPrescriptions
        .expand((p) => p.exercise.requiredEquipment)
        .where((e) => e != WorkoutEquipment.none)
        .toSet();
    return FitFlowSurface(
        tone: FitFlowSurfaceTone.subtle,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fitnessGoalLabel(l, userProfile.goal), style: text.labelLarge),
          const SizedBox(height: FitFlowSpace.xs),
          Semantics(
              header: true,
              child: Text(l.homeSession, style: text.headlineMedium)),
          const SizedBox(height: FitFlowSpace.md),
          Text(
              l.flowTarget(
                  (effectiveDuration ?? userProfile.workoutDuration).minutes),
              style: text.headlineSmall),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(
              '${l.flowCount(plan.totalExerciseCount)} · ${l.flowEstimate(plannedDuration(l, plan.estimatedDuration))}',
              style: text.bodyMedium),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
              equipment.isEmpty
                  ? l.flowNoEquipment
                  : equipment.map((e) => equipmentLabel(l, e)).join(', '),
              style: text.bodySmall),
          const SizedBox(height: FitFlowSpace.sm),
          Text(
              sessionMode == WorkoutSessionMode.standard
                  ? sessionModeLabel(l, sessionMode)
                  : l.flowModeTemporary(sessionModeLabel(l, sessionMode)),
              style: text.labelMedium),
        ]));
  }
}
