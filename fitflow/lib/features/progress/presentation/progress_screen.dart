import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/recovery/movement_recovery_status.dart';
import 'package:fitflow/features/workouts/domain/recovery/training_recovery_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Real Progress screen for Milestone 11 – history + training recovery.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _friendlyLastTrained(DateTime? last, DateTime now) {
    if (last == null) return 'Never trained';
    final diff = now.difference(last);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      if (mins <= 1) return 'Last trained just now';
      return 'Last trained $mins minutes ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      if (hours == 1) return 'Last trained 1 hour ago';
      return 'Last trained $hours hours ago';
    }
    if (diff.inDays == 0) return 'Last trained today';
    if (diff.inDays == 1) return 'Last trained yesterday';
    if (diff.inDays < 7) return 'Last trained ${diff.inDays} days ago';
    return 'Last trained ${_formatDateTime(last)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
        data: (history) {
          final now = DateTime.now().toUtc();
          final totalWorkouts = history.length;
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          final last7Days = history.where((w) => !w.completedAt.isBefore(sevenDaysAgo) && !w.completedAt.isAfter(now)).length;

          // Sum planned training time from estimated durations
          Duration plannedTotal = Duration.zero;
          int plannedCount = 0;
          for (final w in history) {
            if (w.estimatedDuration != null) {
              plannedTotal += w.estimatedDuration!;
              plannedCount++;
            } else if (w.targetDuration != null) {
              plannedTotal += w.targetDuration!;
              plannedCount++;
            }
          }

          final recoveryStatuses = TrainingRecoveryEngine.calculate(history: history, now: now);

          if (totalWorkouts == 0) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your progress', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Your recent FitFlow training, stored on this device.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No completed workouts yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Finish a workout and it will appear here.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: const Text('Start a workout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your progress', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Your recent FitFlow training, stored on this device.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                // Overview cards – responsive for 320px
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;
                    if (isNarrow) {
                      return Column(
                        children: [
                          _OverviewCard(title: 'Total workouts', value: '$totalWorkouts'),
                          const SizedBox(height: 12),
                          _OverviewCard(title: 'Last 7 days', value: '$last7Days'),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _OverviewCard(title: 'Total workouts', value: '$totalWorkouts')),
                        const SizedBox(width: 12),
                        Expanded(child: _OverviewCard(title: 'Last 7 days', value: '$last7Days')),
                      ],
                    );
                  },
                ),
                if (plannedCount > 0) ...[
                  const SizedBox(height: 12),
                  _OverviewCard(title: 'Planned training time', value: _formatDuration(plannedTotal), subtitle: 'Sum of planned durations'),
                ],
                const SizedBox(height: 32),

                // Recovery overview
                Text('Training recovery', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Based on your recent FitFlow training history, not a medical recovery measure.', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Based only on time since this movement appeared in your FitFlow workouts.', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),

                // Movement recovery cards
                if (recoveryStatuses.where((s) => s.lastTrained != null).isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No recent training data. Complete workouts with different movements to see recovery.', style: theme.textTheme.bodyMedium),
                    ),
                  )
                else
                  ...recoveryStatuses.where((s) => s.lastTrained != null).map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecoveryCard(
                        status: status,
                        friendlyLastTrained: _friendlyLastTrained(status.lastTrained, now),
                      ),
                    );
                  }),

                const SizedBox(height: 32),

                // Recent workouts
                Text('Recent workouts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                ...history.take(10).map((workout) {
                  final movementChips = workout.main.map((e) => e.movementPattern.label).toSet().toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentWorkoutCard(
                      workout: workout,
                      movementChips: movementChips,
                      formattedDate: _formatDateTime(workout.completedAt),
                      formattedDuration: _formatDuration(workout.estimatedDuration ?? workout.targetDuration),
                    ),
                  );
                }),

                if (history.length > 10) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text('${history.length - 10} more workouts in history', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                ],

                const SizedBox(height: 24),
                // Debug: show never-trained movements count
                if (recoveryStatuses.any((s) => s.lastTrained == null)) ...[
                  Text('Not yet trained', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recoveryStatuses.where((s) => s.lastTrained == null).map((s) {
                      return Chip(label: Text(s.movementPattern.label));
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.title, required this.value, this.subtitle});
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.status, required this.friendlyLastTrained});
  final MovementRecoveryStatus status;
  final String friendlyLastTrained;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color categoryColor;
    switch (status.category) {
      case RecoveryCategory.trainedRecently:
        categoryColor = colorScheme.primary;
        break;
      case RecoveryCategory.resting:
        categoryColor = colorScheme.secondary;
        break;
      case RecoveryCategory.wellRested:
        categoryColor = colorScheme.tertiary;
        break;
      case RecoveryCategory.notTrainedRecently:
        categoryColor = colorScheme.onSurfaceVariant;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(status.movementPattern.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status.category.label, style: theme.textTheme.labelSmall?.copyWith(color: categoryColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(friendlyLastTrained, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('${status.sessionsLast7Days} sessions • ${status.setsLast7Days} sets this week', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
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
                Expanded(child: Text(formattedDate, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text(formattedDuration, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${workout.totalExerciseCount} exercises • ${workout.totalSetCount} sets', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (movementChips.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: movementChips.map((label) => Chip(label: Text(label, style: theme.textTheme.labelSmall), visualDensity: VisualDensity.compact)).toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/progress/history/${workout.id}'),
                child: const Text('View workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
