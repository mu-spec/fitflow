import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_adaptive_note.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
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
    final t = FitFlowTheme.of(context);
    final equipment = plan.allPrescriptions
        .expand((p) => p.exercise.requiredEquipment)
        .where((e) => e != WorkoutEquipment.none)
        .toSet();
    return Column(
      key: const ValueKey('v2_preview_summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l.homeSession,
              style: text.titleLarge?.copyWith(
                  color: t.textPrimary, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
            '${l.flowEstimate(plannedDuration(l, plan.estimatedDuration))} · ${l.flowCount(plan.totalExerciseCount)}',
            style: text.bodyMedium?.copyWith(color: t.textPrimary)),
        const SizedBox(height: FitFlowSpace.xs),
        Wrap(spacing: FitFlowSpace.sm, runSpacing: FitFlowSpace.xxs, children: [
          Text(
              equipment.isEmpty
                  ? l.flowNoEquipment
                  : equipment.map((e) => equipmentLabel(l, e)).join(', '),
              style: text.bodySmall?.copyWith(color: t.textSecondary)),
          Text(sessionModeLabel(l, sessionMode),
              style: text.bodySmall?.copyWith(color: t.textSecondary)),
        ]),
        ExpansionTile(
          key: const Key('preview_details'),
          initiallyExpanded: false,
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          title: Text(l.flowPreviewDetails,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          children: [
            Text(fitnessGoalLabel(l, userProfile.goal), style: text.bodyMedium),
            const SizedBox(height: FitFlowSpace.xs),
            Text(
                l.flowTarget(
                    (effectiveDuration ?? userProfile.workoutDuration).minutes),
                style: text.bodyMedium),
            if (sessionMode != WorkoutSessionMode.standard) ...[
              const SizedBox(height: FitFlowSpace.xs),
              Text(l.flowModeTemporary(sessionModeLabel(l, sessionMode)),
                  style: text.bodySmall),
            ],
            const SizedBox(height: FitFlowSpace.sm),
            Text(l.flowPreviewHelp,
                style: text.bodyMedium?.copyWith(color: t.textSecondary)),
            const SizedBox(height: FitFlowSpace.xs),
            const WorkoutPreviewAdaptiveNote(),
            const SizedBox(height: FitFlowSpace.sm),
          ],
        ),
      ],
    );
  }
}
