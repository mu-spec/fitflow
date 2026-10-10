import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/l10n/enum_labels.dart';
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
  static String routeName(String sessionId) =>
      'progress-history-detail-$sessionId';

  String _formatDuration(BuildContext context, Duration? d) =>
      d == null ? '—' : FitFlowLocaleFormat.formatDuration(context.l10n, d);

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
        loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FitFlowLoading(label: context.l10n.trainingHistoryLoading)),
        error: (e, _) => Center(
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l10n.trainingHistoryError),
          TextButton(
              onPressed: () =>
                  ref.read(workoutHistoryProvider.notifier).refresh(),
              child: Text(context.l10n.trainingRetry)),
        ]))),
        data: (history) {
          final workout = history.where((w) => w.id == sessionId).firstOrNull;
          if (workout == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(context.l10n.trainingHistoryMissing,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(context.l10n.trainingHistoryMissingHelp,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: FitFlowMaxWidth(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.trainingHistoryCompleted,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_formatDateTime(context, workout.completedAt),
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(
                              label: context.l10n.trainingPlannedDuration,
                              value: _formatDuration(
                                  context, workout.targetDuration)),
                          const Divider(),
                          _DetailRow(
                              label: context.l10n.trainingEstimatedDuration,
                              value: _formatDuration(
                                  context, workout.estimatedDuration)),
                          const Divider(),
                          _DetailRow(
                              label: context.l10n.trainingTotalExercises,
                              value: '${workout.totalExerciseCount}'),
                          const Divider(),
                          _DetailRow(
                              label: context.l10n.trainingTotalSets,
                              value: '${workout.totalSetCount}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionBlock(
                      title: context.l10n.flowWarmup,
                      exercises: workout.warmup),
                  const SizedBox(height: 16),
                  _SectionBlock(
                      title: context.l10n.flowMain, exercises: workout.main),
                  const SizedBox(height: 16),
                  _SectionBlock(
                      title: context.l10n.flowCooldown,
                      exercises: workout.cooldown),
                ],
              ),
            )),
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
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
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (exercises.isEmpty)
          Text(context.l10n.trainingNoExercises,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          ...exercises.map((ex) {
            final workload = ex.repsPerSet != null
                ? context.l10n.trainingWorkloadReps(ex.sets, ex.repsPerSet!)
                : context.l10n.trainingWorkloadTimed(
                    ex.sets,
                    ex.workDuration == null
                        ? '—'
                        : FitFlowLocaleFormat.formatDuration(
                            context.l10n, ex.workDuration!));
            final movementLabel = ex.movementPattern == null
                ? context.l10n.trainingUnclassified
                : movementPatternLabel(context.l10n, ex.movementPattern!);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.exerciseName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        '$movementLabel • ${trainingDifficultyLabel(context.l10n, ex.difficulty)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(workload, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                        context.l10n.trainingRest(
                            FitFlowLocaleFormat.formatDuration(
                                context.l10n, ex.restBetweenSets)),
                        style: theme.textTheme.bodySmall),
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
