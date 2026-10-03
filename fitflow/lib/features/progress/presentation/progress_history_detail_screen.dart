import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressHistoryDetailScreen extends ConsumerWidget {
  const ProgressHistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  static String routePath(String sessionId) => '/progress/history/$sessionId';
  static String routeName(String sessionId) => 'progress-history-detail-$sessionId';

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    return FitFlowLocaleFormat.formatDateTime(context, dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.workoutDetail)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (history) {
          final workout = history.where((w) => w.id == sessionId).firstOrNull;
          if (workout == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Workout not found', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('This workout may have been cleared.', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Completed workout', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_formatDateTime(context, workout.completedAt), style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Planned duration', value: _formatDuration(workout.targetDuration)),
                          const Divider(),
                          _DetailRow(label: 'Estimated duration', value: _formatDuration(workout.estimatedDuration)),
                          const Divider(),
                          _DetailRow(label: 'Total exercises', value: '${workout.totalExerciseCount}'),
                          const Divider(),
                          _DetailRow(label: 'Total sets', value: '${workout.totalSetCount}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionBlock(title: 'Warm-up', exercises: workout.warmup),
                  const SizedBox(height: 16),
                  _SectionBlock(title: 'Main', exercises: workout.main),
                  const SizedBox(height: 16),
                  _SectionBlock(title: 'Cooldown', exercises: workout.cooldown),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
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

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.exercises});
  final String title;
  final List<CompletedWorkoutExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (exercises.isEmpty)
          Text('No exercises', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          ...exercises.map((ex) {
            final workload = ex.repsPerSet != null ? '${ex.sets} × ${ex.repsPerSet} reps' : '${ex.sets} × ${ex.workDuration?.inSeconds}s';
            final movementLabel = ex.movementPattern?.label ?? 'Unclassified movement';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.exerciseName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$movementLabel • Level ${ex.difficulty.name.replaceAll('level', '')} • ${ex.sectionType.label}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(workload, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text('Rest ${ex.restBetweenSets.inSeconds}s', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}
