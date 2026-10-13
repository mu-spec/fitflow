import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scannable prescription; the native row opens the existing detail route.
class WorkoutPreviewExerciseRow extends StatelessWidget {
  const WorkoutPreviewExerciseRow(
      {super.key,
      required this.prescription,
      this.originalExerciseName,
      this.visualV2 = false,
      this.sequenceNumber});
  final WorkoutExercisePrescription prescription;
  final String? originalExerciseName;

  // Explicit opt-in: Program Session Preview retains its existing row.
  final bool visualV2;
  final int? sequenceNumber;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final equipment = equipmentSummary(l, prescription);
    if (visualV2) {
      final v = FitFlowVisualV2.of(context);
      final t = FitFlowTheme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
        child: Material(
          color: v.support,
          shape: RoundedRectangleBorder(
            borderRadius: FitFlowRadius.mediumBorder,
            side: BorderSide(color: v.subtleBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: FitFlowSpace.sm, vertical: FitFlowSpace.xs),
            minVerticalPadding: FitFlowSpace.xs,
            minTileHeight: 64,
            leading: sequenceNumber == null
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                        color: v.tint, borderRadius: FitFlowRadius.smallBorder),
                    child: Padding(
                      padding: const EdgeInsets.all(FitFlowSpace.xs),
                      child: Text('$sequenceNumber',
                          style: text.labelLarge?.copyWith(color: t.brand)),
                    ),
                  ),
            title: Text(prescription.exercise.name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: FitFlowSpace.xxs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workloadLabel(l, prescription),
                      style: text.bodyMedium?.copyWith(color: t.textSecondary)),
                  if (prescription.sets > 1)
                    Text(
                        l.flowRestBetween(
                            prescription.restBetweenSets.inSeconds),
                        style:
                            text.bodySmall?.copyWith(color: t.textSecondary)),
                  if (equipment != l.flowNoEquipment)
                    Text(equipment,
                        style:
                            text.bodySmall?.copyWith(color: t.textSecondary)),
                  if (originalExerciseName != null)
                    Text(l.flowReplaced(originalExerciseName!),
                        style:
                            text.bodySmall?.copyWith(color: t.textSecondary)),
                ],
              ),
            ),
            trailing: const ExcludeSemantics(
                child: Icon(Icons.chevron_right_rounded)),
            onTap: () => context
                .push(AppRoutes.exerciseDetail(prescription.exercise.id)),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
        minVerticalPadding: FitFlowSpace.sm,
        title: Text(prescription.exercise.name, style: text.titleMedium),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: FitFlowSpace.xs),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(workloadLabel(l, prescription), style: text.bodyMedium),
              if (prescription.sets > 1)
                Text(l.flowRestBetween(prescription.restBetweenSets.inSeconds),
                    style: text.bodySmall),
              if (equipment != l.flowNoEquipment)
                Text(equipment, style: text.bodySmall),
              if (originalExerciseName != null)
                Text(l.flowReplaced(originalExerciseName!),
                    style: text.bodySmall),
            ])),
        trailing:
            const ExcludeSemantics(child: Icon(Icons.chevron_right_rounded)),
        onTap: () =>
            context.push(AppRoutes.exerciseDetail(prescription.exercise.id)),
      ),
      const Divider(height: 1),
    ]);
  }
}
