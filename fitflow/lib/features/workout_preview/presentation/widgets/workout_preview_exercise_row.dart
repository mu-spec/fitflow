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
      {super.key, required this.prescription, this.originalExerciseName});
  final WorkoutExercisePrescription prescription;
  final String? originalExerciseName;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final equipment = equipmentSummary(l, prescription);
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
