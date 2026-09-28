import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimate.dart';
import 'package:flutter/material.dart';

/// Section header showing name, count, planned time, budget.
class WorkoutPreviewSectionHeader extends StatelessWidget {
  const WorkoutPreviewSectionHeader({
    super.key,
    required this.title,
    required this.exerciseCount,
    required this.planned,
    required this.budget,
  });

  final String title;
  final int exerciseCount;
  final WorkoutTimeEstimate? planned;
  final Duration budget;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) return '< 1 min';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes min';
    }
    // Show minutes with seconds for section detail, but keep simple
    return '${minutes}m ${seconds}s';
  }

  String _formatBudget(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) return '< 1 min';
    final minutes = totalSeconds ~/ 60;
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final plannedFormatted = _formatDuration(planned?.total);
    final budgetFormatted = _formatBudget(budget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Text(
                '$exerciseCount exercises',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$plannedFormatted planned · $budgetFormatted budget',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
