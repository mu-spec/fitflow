import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';

/// Completed phase view - truthful data only, no calories/XP/streaks/history.
class WorkoutPlayerCompletedView extends StatelessWidget {
  const WorkoutPlayerCompletedView({
    super.key,
    required this.plan,
    required this.state,
  });

  final WorkoutPlan plan;
  final WorkoutPlayerState state;

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalExercises = plan.totalExerciseCount;
    final completedSets = state.completedSets;
    final totalSets = state.totalSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 56,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Workout complete',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Great job! You finished all sets.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(label: 'Exercises', value: '$totalExercises'),
                const Divider(),
                _StatRow(label: 'Sets', value: '$completedSets / $totalSets'),
                const Divider(),
                _StatRow(label: 'Target duration', value: _formatDuration(plan.targetDuration)),
                const SizedBox(height: 8),
                _StatRow(label: 'Estimated duration', value: _formatDuration(plan.estimatedDuration)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Session progress is not saved in this version.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
