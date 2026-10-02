import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:flutter/material.dart';

/// Transition UI: Next exercise, next exercise name, countdown, Skip transition.
class WorkoutPlayerTransitionView extends StatelessWidget {
  const WorkoutPlayerTransitionView({super.key, required this.state});

  final WorkoutPlayerState state;

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
    final next = state.nextPrescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Next exercise',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        PlayerTimerSemantics(
          label: 'Transition remaining ${state.remaining.inSeconds} seconds',
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
        const SizedBox(height: 24),
        if (next != null) ...[
          ExcludeSemantics(
            child: Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            next.exercise.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (next.exercise.movementPattern != null) ...[
            const SizedBox(height: 4),
            Text(
              next.exercise.movementPattern!.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            next.repsPerSet != null
                ? '${next.sets} sets × ${next.repsPerSet} reps'
                : '${next.sets} sets × ${next.workDuration!.inSeconds} sec',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (state.isPaused) ...[
          const SizedBox(height: 16),
          Text(
            'Paused',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
