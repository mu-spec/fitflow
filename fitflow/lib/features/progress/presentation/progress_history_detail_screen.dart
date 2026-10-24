import 'widgets/progress_presentation.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressHistoryDetailScreen extends ConsumerWidget {
  const ProgressHistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  static String routePath(String sessionId) => '/progress/history/$sessionId';
  static String routeName(String sessionId) =>
      'progress-history-detail-$sessionId';

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ProgressTheme(child: _HistoryDetailContent(sessionId: sessionId));
}

class _HistoryDetailContent extends ConsumerWidget {
  const _HistoryDetailContent({required this.sessionId});
  final String sessionId;

  String _formatDuration(BuildContext context, Duration? d) =>
      d == null ? '—' : progressDuration(context, d);

  String _formatDateTime(BuildContext context, DateTime dt) {
    return FitFlowLocaleFormat.formatDateTime(context, dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final visual = FitFlowVisualV2.of(context);

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        title: Text(context.l10n.workoutDetail,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        scrolledUnderElevation: 0,
        backgroundColor: visual.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FitFlowLoading(
            label: context.l10n.trainingHistoryLoading,
          ),
        ),
        error: (e, _) => Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.trainingHistoryError),
                TextButton(
                  onPressed: () =>
                      ref.read(workoutHistoryProvider.notifier).refresh(),
                  child: Text(context.l10n.trainingRetry),
                ),
              ],
            ),
          ),
        ),
        data: (history) {
          final workout = history.where((w) => w.id == sessionId).firstOrNull;
          if (workout == null) {
            return _missingHistoryState(context);
          }

          return SafeArea(
            child: FitFlowMaxWidth(
              maxWidth: FitFlowLayout.maxReadableWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  FitFlowSpace.screenHorizontal,
                  FitFlowSpace.lg,
                  FitFlowSpace.screenHorizontal,
                  FitFlowSpace.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                            child: Icon(Icons.check_circle_outline_rounded,
                                color: FitFlowTheme.of(context).brand,
                                size: 28)),
                        const SizedBox(width: FitFlowSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  context.l10n.trainingHistoryCompleted,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: FitFlowSpace.xs),
                              Text(
                                _formatDateTime(context, workout.completedAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    Column(
                      children: [
                        _DetailRow(
                          label: context.l10n.trainingPlannedDuration,
                          value: _formatDuration(
                            context,
                            workout.targetDuration,
                          ),
                        ),
                        const Divider(height: FitFlowSpace.md),
                        _DetailRow(
                          label: context.l10n.trainingEstimatedDuration,
                          value: _formatDuration(
                            context,
                            workout.estimatedDuration,
                          ),
                        ),
                        const Divider(height: FitFlowSpace.md),
                        _DetailRow(
                          label: context.l10n.trainingTotalExercises,
                          value: '${workout.totalExerciseCount}',
                        ),
                        const Divider(height: FitFlowSpace.md),
                        _DetailRow(
                          label: context.l10n.trainingTotalSets,
                          value: '${workout.totalSetCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    Text(context.l10n.progressTimeHelp,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: FitFlowSpace.md),
                    _SectionBlock(
                      title: context.l10n.flowWarmup,
                      exercises: workout.warmup,
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    _SectionBlock(
                      title: context.l10n.flowMain,
                      exercises: workout.main,
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    _SectionBlock(
                      title: context.l10n.flowCooldown,
                      exercises: workout.cooldown,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _missingHistoryState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          child: FitFlowMaxWidth(
            maxWidth: FitFlowLayout.maxReadableWidth,
            child: FitFlowV2InfoSurface(
              tonal: true,
              padding: const EdgeInsets.all(FitFlowSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  Semantics(
                    header: true,
                    child: Text(
                      context.l10n.trainingHistoryMissing,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.xs),
                  Text(
                    context.l10n.trainingHistoryMissingHelp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final colors = FitFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: FitFlowSpace.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
    final colors = FitFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: FitFlowSpace.sm),
        exercises.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(FitFlowSpace.md),
                child: Text(
                  context.l10n.trainingNoExercises,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < exercises.length; i++) ...[
                    _ExerciseRecord(exercise: exercises[i]),
                    if (i < exercises.length - 1)
                      const Divider(
                        height: 1,
                        indent: FitFlowSpace.md,
                        endIndent: FitFlowSpace.md,
                      ),
                  ],
                ],
              ),
      ],
    );
  }
}

class _ExerciseRecord extends StatelessWidget {
  const _ExerciseRecord({required this.exercise});

  final CompletedWorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final workload = exercise.repsPerSet != null
        ? l.trainingWorkloadReps(exercise.sets, exercise.repsPerSet!)
        : l.trainingWorkloadTimed(
            exercise.sets,
            exercise.workDuration == null
                ? '—'
                : FitFlowLocaleFormat.formatDuration(
                    l,
                    exercise.workDuration!,
                  ),
          );
    final movementLabel = exercise.movementPattern == null
        ? l.trainingUnclassified
        : movementPatternLabel(l, exercise.movementPattern!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (ExerciseMediaRegistry.lookup(exercise.exerciseId) != null)
          FitFlowExerciseImage.thumbnail(
              exerciseId: exercise.exerciseId, width: 64, height: 64)
        else
          ExcludeSemantics(
              child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.fitness_center_outlined,
                      color: colors.textSecondary, size: 24))),
        const SizedBox(width: FitFlowSpace.sm),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: FitFlowSpace.xxs),
            Text(
              '$movementLabel • ${trainingDifficultyLabel(l, exercise.difficulty)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: FitFlowSpace.xs),
            Text(
              workload,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: FitFlowSpace.xxs),
            Text(
              l.trainingRest(
                FitFlowLocaleFormat.formatDuration(l, exercise.restBetweenSets),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        )),
      ]),
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
