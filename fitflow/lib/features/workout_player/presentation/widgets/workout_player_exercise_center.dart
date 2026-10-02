import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:flutter/material.dart';

/// Center area showing exercise icon, name, movement, set, large reps or countdown.
class WorkoutPlayerExerciseCenter extends StatelessWidget {
  const WorkoutPlayerExerciseCenter({super.key, required this.state});

  final WorkoutPlayerState state;

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

  String _formatRemaining(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds < 0) return '0';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prescription = state.currentPrescription;
    final exercise = prescription.exercise;
    final isTimed = state.isTimedExercise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Neutral movement icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ExcludeSemantics(
            child: Icon(
              _iconForMovement(exercise.movementPattern?.name),
              size: 40,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Exercise name
        Text(
          exercise.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        if (state.isCurrentReplaced) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state.originalExerciseName != null ? 'Replaced ${state.originalExerciseName}' : 'Replaced',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (exercise.movementPattern != null) ...[
          const SizedBox(height: 4),
          Text(
            exercise.movementPattern!.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        // Set info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Text(
            'Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Large reps OR countdown
        if (isTimed)
          Column(
            children: [
              PlayerTimerSemantics(
                label: 'Remaining ${state.remaining.inSeconds} seconds',
                child: Text(
                  _formatRemaining(state.remaining),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: state.isPaused ? colorScheme.onSurfaceVariant : colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'sec',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (state.isPaused) ...[
                const SizedBox(height: 8),
                Text(
                  'Paused',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            children: [
              Text(
                '${prescription.repsPerSet} reps',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
                semanticsLabel: '${prescription.repsPerSet} reps',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (state.isPaused) ...[
                const SizedBox(height: 8),
                Text(
                  'Paused',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 16),
        if (state.isPaused)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Workout paused',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
      ],
    );
  }
}
