import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Lazy library row: name, movement/focus, equipment. Defaults live in detail.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({super.key, required this.exercise, this.onTap});
  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final equipment = exercise.requiredEquipment;
    final equipmentText =
        equipment.isEmpty || equipment.contains(WorkoutEquipment.none)
            ? l.trainingNoEquipment
            : equipment.map((e) => equipmentLabel(l, e)).join(' · ');
    final focus = exercise.movementPattern == null
        ? exercise.primaryMuscles.map((m) => m.label).join(' · ')
        : movementPatternLabel(l, exercise.movementPattern!);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title:
          Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child:
              Text([if (focus.isNotEmpty) focus, equipmentText].join(' · '))),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
