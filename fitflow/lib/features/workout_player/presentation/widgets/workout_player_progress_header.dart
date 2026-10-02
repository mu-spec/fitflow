import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:flutter/material.dart';

/// Top header showing section, exercise position, set progress, overall progress.
class WorkoutPlayerProgressHeader extends StatelessWidget {
  const WorkoutPlayerProgressHeader({super.key, required this.state});

  final WorkoutPlayerState state;

  String _sectionLabel() {
    switch (state.sectionType.name) {
      case 'warmup':
        return 'WARM-UP';
      case 'main':
        return 'MAIN WORKOUT';
      case 'cooldown':
        return 'COOLDOWN';
      default:
        return state.sectionType.name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section + progress row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sectionLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    semanticsLabel: 'Section ${_sectionLabel()}',
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Exercise ${state.exercisePositionInSection} of ${state.exerciseCountInCurrentSection}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.progressLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  semanticsLabel: 'Overall progress ${state.completedSets} of ${state.totalSets} sets',
                ),
                const SizedBox(height: 2),
                Text(
                  'Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: state.progressFraction,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: colorScheme.primary,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          semanticsLabel:
              'Workout progress, ${state.completedSets} of ${state.totalSets} sets',
        ),
      ],
    );
  }
}
