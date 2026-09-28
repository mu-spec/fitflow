import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:flutter/material.dart';

/// Exercise row showing name, movement, prescription, rest, equipment.
class WorkoutPreviewExerciseRow extends StatelessWidget {
  const WorkoutPreviewExerciseRow({super.key, required this.prescription});

  final WorkoutExercisePrescription prescription;

  String _prescriptionText() {
    final sets = prescription.sets;
    if (prescription.repsPerSet != null) {
      final reps = prescription.repsPerSet!;
      if (sets == 1) {
        return '1 set × $reps reps';
      }
      return '$sets sets × $reps reps';
    } else if (prescription.workDuration != null) {
      final dur = prescription.workDuration!;
      final seconds = dur.inSeconds;
      String durLabel;
      if (seconds % 60 == 0) {
        durLabel = '${seconds ~/ 60} min';
        // For short durations, show sec
        if (seconds < 60) {
          durLabel = '$seconds sec';
        } else if (seconds < 120) {
          // e.g., 90 sec -> keep sec for clarity
          durLabel = '$seconds sec';
        }
      } else {
        durLabel = '$seconds sec';
      }
      // Normalize: if duration <60 show sec, else if exact minutes show min, else sec
      if (seconds < 60) {
        durLabel = '$seconds sec';
      } else if (seconds % 60 == 0) {
        durLabel = '${seconds ~/ 60} min';
        // But for exercise rows, prefer sec for timed exercises up to 2 min
        if (seconds <= 120) {
          durLabel = '$seconds sec';
        }
      } else {
        durLabel = '$seconds sec';
      }

      if (sets == 1) {
        return '1 set × $durLabel';
      }
      return '$sets sets × $durLabel';
    }
    return '$sets sets';
  }

  String _restText() {
    final rest = prescription.restBetweenSets;
    if (prescription.sets <= 1) {
      return '';
    }
    if (rest == Duration.zero) {
      return 'No rest';
    }
    final seconds = rest.inSeconds;
    if (seconds < 60) {
      return '$seconds sec rest';
    }
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (remaining == 0) {
      return '$minutes min rest';
    }
    return '${minutes}m ${remaining}s rest';
  }

  String _equipmentText() {
    final required = prescription.exercise.requiredEquipment;
    final meaningful = required.where((e) => e != WorkoutEquipment.none).toList();
    if (meaningful.isEmpty) {
      return 'No equipment';
    }
    return meaningful.map((e) => e.label).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercise = prescription.exercise;

    final movementLabel = exercise.movementPattern?.label;
    final difficultyLabel = exercise.difficulty.name;
    final bodyPositionLabel = exercise.bodyPosition?.name ?? 'Unknown';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconForMovement(exercise.movementPattern?.name),
                size: 20,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (movementLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      movementLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _prescriptionText(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_restText().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _restText(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetaChip(context, _equipmentText()),
                      _buildMetaChip(context, bodyPositionLabel),
                      _buildMetaChip(context, difficultyLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }

  IconData _iconForMovement(String? movementName) {
    switch (movementName) {
      case 'push':
        return Icons.push_pin_outlined;
      case 'pull':
        return Icons.rowing_outlined;
      case 'squat':
        return Icons.airline_seat_legroom_normal_outlined;
      case 'lunge':
        return Icons.directions_walk_outlined;
      case 'hinge':
        return Icons.accessibility_new_outlined;
      case 'core':
        return Icons.self_improvement_outlined;
      case 'glute':
        return Icons.fitness_center_outlined;
      case 'cardio':
        return Icons.favorite_outline;
      case 'mobility':
        return Icons.open_with_outlined;
      case 'balance':
        return Icons.balance_outlined;
      case 'warmup':
        return Icons.local_fire_department_outlined;
      case 'cooldown':
        return Icons.spa_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }
}
