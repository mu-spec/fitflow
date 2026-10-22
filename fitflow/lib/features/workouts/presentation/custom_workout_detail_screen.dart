import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomWorkoutDetailScreen extends ConsumerWidget {
  const CustomWorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      WorkoutsTheme(child: _CustomWorkoutDetailContent(workoutId: workoutId));
}

class _CustomWorkoutDetailContent extends ConsumerWidget {
  const _CustomWorkoutDetailContent({required this.workoutId});

  final String workoutId;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s > 0 ? '${s}s' : ''}'.trim();
    return '${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);
    final customAsync = ref.watch(customWorkoutControllerProvider);
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityAsync = ref.watch(capabilityProfileProvider);

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        title: Text(context.l10n.flowCustom),
        actions: [
          IconButton(
            tooltip: context.l10n.trainingEdit,
            onPressed: () =>
                context.push(AppRoutes.customWorkoutEdit(workoutId)),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: context.l10n.trainingDelete,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                animationStyle: SystemMotion.overlay(context),
                builder: (ctx) => AlertDialog(
                  title: Text(context.l10n.trainingDeleteTitle),
                  content: Text(context.l10n.trainingDeleteBody),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(context.l10n.trainingCancel)),
                    FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(context.l10n.trainingDelete)),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final success = await ref
                    .read(customWorkoutControllerProvider.notifier)
                    .delete(workoutId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.trainingDeleteError)),
                  );
                } else if (context.mounted) {
                  context.go(AppRoutes.workouts);
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: customAsync.when(
        data: (templates) {
          final template =
              templates.where((t) => t.id == workoutId).firstOrNull;
          if (template == null) {
            return Center(child: Text(context.l10n.trainingHistoryMissing));
          }

          final catalogById = ExerciseCatalog.byIdMap;

          WorkoutPlan? resolvedPlan;
          List<CustomWorkoutResolverIssue> issues = const [];

          if (userProfileAsync.hasValue && capabilityAsync.hasValue) {
            final userProfile = userProfileAsync.value;
            final capabilityProfile = capabilityAsync.value;
            if (userProfile != null && capabilityProfile != null) {
              final resolution = CustomWorkoutPlanResolver.resolve(
                template: template,
                catalogById: catalogById,
                userFitnessProfile: userProfile,
                capabilityProfile: capabilityProfile,
              );
              resolvedPlan = resolution.plan;
              issues = resolution.issues;
            }
          }

          final totalExercises = template.totalExerciseCount;
          final totalSets =
              template.allEntries.fold<int>(0, (sum, e) => sum + e.sets);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        template.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: FitFlowSpace.xs),
                    FitFlowV2InfoSurface(
                      tonal: true,
                      child: Text(
                        'Target: ${template.targetDuration.label} • $totalExercises exercises • $totalSets sets'
                        '${resolvedPlan?.estimatedDuration != null ? ' • Est: ${_formatDuration(resolvedPlan!.estimatedDuration!)}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    if (issues.isNotEmpty) ...[
                      Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.trainingCustomNeedsUpdate,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onErrorContainer)),
                              const SizedBox(height: 8),
                              ...issues.map((i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('• ',
                                            style: TextStyle(
                                                color: theme.colorScheme
                                                    .onErrorContainer)),
                                        Expanded(
                                            child: Text(
                                                i.message.startsWith(
                                                        'Unable to build eligibility context:')
                                                    ? context.l10n
                                                        .trainingCustomReview
                                                    : template.allEntries.fold<String>(
                                                        i.message,
                                                        (message, entry) => message.replaceAll(
                                                            entry.exerciseId,
                                                            catalogById[entry.exerciseId]
                                                                    ?.name ??
                                                                context.l10n
                                                                    .trainingMissingExercise)),
                                                style: TextStyle(
                                                    color: theme.colorScheme
                                                        .onErrorContainer))),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionPreview(
                      title: 'Warm-up',
                      entries: template.warmup,
                      catalogById: catalogById,
                      planSection: resolvedPlan?.warmup,
                    ),
                    const Divider(height: FitFlowSpace.xl),
                    _SectionPreview(
                      title: 'Main',
                      entries: template.main,
                      catalogById: catalogById,
                      planSection: resolvedPlan?.main,
                    ),
                    const Divider(height: FitFlowSpace.xl),
                    _SectionPreview(
                      title: 'Cool-down',
                      entries: template.cooldown,
                      catalogById: catalogById,
                      planSection: resolvedPlan?.cooldown,
                    ),
                    const SizedBox(height: FitFlowSpace.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stackActions = constraints.maxWidth < 420 ||
                            MediaQuery.textScalerOf(context).scale(16) > 20;
                        final editButton = OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              SystemMotion.minTouchTarget,
                            ),
                          ),
                          onPressed: () => context
                              .push(AppRoutes.customWorkoutEdit(workoutId)),
                          child: Text(context.l10n.trainingEdit),
                        );
                        final startButton = FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              SystemMotion.minTouchTarget,
                            ),
                          ),
                          onPressed: resolvedPlan != null
                              ? () => context.push(
                                  AppRoutes.customWorkoutPlayer(workoutId))
                              : null,
                          child: Text(context.l10n.trainingCustomStart),
                        );
                        if (stackActions) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              editButton,
                              const SizedBox(height: FitFlowSpace.xs),
                              startButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: editButton),
                            const SizedBox(width: FitFlowSpace.sm),
                            Expanded(child: startButton),
                          ],
                        );
                      },
                    ),
                    if (resolvedPlan == null) ...[
                      const SizedBox(height: 8),
                      Text(context.l10n.trainingCustomFix,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FitFlowLoading(label: context.l10n.trainingCustomLoading)),
        error: (e, _) => Center(
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l10n.trainingCustomError),
          TextButton(
              onPressed: () =>
                  ref.read(customWorkoutControllerProvider.notifier).refresh(),
              child: Text(context.l10n.trainingRetry)),
        ]))),
      ),
    );
  }
}

class _SectionPreview extends StatelessWidget {
  const _SectionPreview(
      {required this.title,
      required this.entries,
      required this.catalogById,
      this.planSection});

  final String title;
  final List entries;
  final Map<String, Exercise> catalogById;
  final dynamic planSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        if (entries.isEmpty)
          Text(
            context.l10n.trainingNoExercises,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const Divider(height: FitFlowSpace.lg),
            Builder(
              builder: (context) {
                final entry = entries[index];
                final Exercise? ex = catalogById[entry.exerciseId];
                final workload = entry.isTimed
                    ? '${entry.sets} × ${entry.workDuration!.inSeconds}s'
                    : '${entry.sets} × ${entry.repsPerSet} reps';
                final rest = '${entry.restBetweenSets.inSeconds}s rest';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: FitFlowSpace.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ex != null) ...[
                        FitFlowV2ExerciseMedia.forExercise(
                          exercise: ex,
                          width: 52,
                          height: 52,
                        ),
                        const SizedBox(width: FitFlowSpace.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ex == null)
                              Text(
                                context.l10n.trainingMissingExercise,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error,
                                ),
                              )
                            else
                              Text(
                                ex.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (ex != null)
                              Text(
                                '${ex.movementPattern == null ? '' : movementPatternLabel(context.l10n, ex.movementPattern!)} • ${trainingDifficultyLabel(context.l10n, ex.difficulty)} • $workload • $rest',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final e in this) {
      return e;
    }
    return null;
  }
}
