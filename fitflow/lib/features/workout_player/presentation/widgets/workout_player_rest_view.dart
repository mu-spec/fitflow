import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:flutter/material.dart';

/// Rest UI: Rest, countdown, exercise name, upcoming set number, Skip rest.
class WorkoutPlayerRestView extends StatelessWidget {
  const WorkoutPlayerRestView({super.key, required this.state});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Rest',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        PlayerTimerSemantics(
          label: 'Rest remaining ${state.remaining.inSeconds} seconds',
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
          'sec rest',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          state.currentPrescription.exercise.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Next: Set ${state.setNumber + 1} of ${state.totalSetsForCurrentExercise}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
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
