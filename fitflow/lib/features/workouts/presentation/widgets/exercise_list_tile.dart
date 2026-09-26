import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:flutter/material.dart';

/// Compact, read-only row for an exercise in the library list.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({super.key, required this.exercise});

  final Exercise exercise;

  String _primaryMusclesLabel() {
    if (exercise.primaryMuscles.isEmpty) return '—';
    return exercise.primaryMuscles.map((m) => m.label).join(' • ');
  }

  String _movementAndDifficultyLabel() {
    final movement = exercise.movementPattern?.label ?? '—';
    final levelNumber = exercise.difficulty.name.replaceFirst('level', '');
    return '$movement • Level $levelNumber';
  }

  String _equipmentLabel() {
    final equipment = exercise.requiredEquipment;
    if (equipment.contains(WorkoutEquipment.none) ||
        equipment.isEmpty) {
      return 'No equipment';
    }
    return equipment.map((e) => e.label).join(' • ');
  }

  String _repsOrTimedLabel() {
    if (exercise.exerciseType == ExerciseType.reps) {
      final reps = exercise.defaultReps;
      if (reps != null) return '$reps reps';
      return 'Reps';
    } else {
      final duration = exercise.defaultDuration;
      if (duration != null) {
        final seconds = duration.inSeconds;
        // Keep compact: e.g., "30s"
        return '${seconds}s';
      }
      return 'Timed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _primaryMusclesLabel(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            _movementAndDifficultyLabel(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${_equipmentLabel()} • ${_repsOrTimedLabel()}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
