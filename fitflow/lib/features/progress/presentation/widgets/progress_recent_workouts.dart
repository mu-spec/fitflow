import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgressRecentWorkouts extends StatelessWidget {
  const ProgressRecentWorkouts({super.key, required this.history});

  final List<CompletedWorkout> history;

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    return FitFlowLocaleFormat.formatDateTime(context, dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recentWorkouts,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...history.take(10).map((workout) {
          final movementChips = workout.main
              .where((e) => e.movementPattern != null)
              .map((e) => e.movementPattern!.label)
              .toSet()
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecentWorkoutCard(
              workout: workout,
              movementChips: movementChips,
              formattedDate: _formatDateTime(context, workout.completedAt),
              formattedDuration: _formatDuration(workout.estimatedDuration ?? workout.targetDuration),
            ),
          );
        }),
        if (history.length > 10) ...[
          const SizedBox(height: 8),
          Center(
            child: Text('${history.length - 10} more workouts in history',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
        ],
      ],
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({
    required this.workout,
    required this.movementChips,
    required this.formattedDate,
    required this.formattedDuration,
  });

  final CompletedWorkout workout;
  final List<String> movementChips;
  final String formattedDate;
  final String formattedDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(formattedDate,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text(formattedDuration,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${workout.totalExerciseCount} exercises • ${workout.totalSetCount} sets',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (movementChips.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: movementChips
                    .map((label) => Chip(
                        label: Text(label, style: theme.textTheme.labelSmall),
                        visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.progressHistoryDetail(workout.id)),
                child: const Text('View workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
