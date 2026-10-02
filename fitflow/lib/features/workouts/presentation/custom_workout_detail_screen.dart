import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomWorkoutDetailScreen extends ConsumerWidget {
  const CustomWorkoutDetailScreen({super.key, required this.workoutId});

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
    final customAsync = ref.watch(customWorkoutControllerProvider);
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityAsync = ref.watch(capabilityProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom workout'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.push(AppRoutes.customWorkoutEdit(workoutId)),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete custom workout?'),
                  content: const Text('This removes the saved workout. Completed workout history is not deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final success = await ref.read(customWorkoutControllerProvider.notifier).delete(workoutId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Couldn't delete this workout. Try again.")),
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
          final template = templates.where((t) => t.id == workoutId).firstOrNull;
          if (template == null) {
            return const Center(child: Text('Workout not found.'));
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
          final totalSets = template.allEntries.fold<int>(0, (sum, e) => sum + e.sets);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${template.targetDuration.label} • $totalExercises exercises • $totalSets sets'
                      '${resolvedPlan?.estimatedDuration != null ? ' • Est: ${_formatDuration(resolvedPlan!.estimatedDuration!)}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    if (issues.isNotEmpty) ...[
                      Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This workout needs updates for your current setup.',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600, color: theme.colorScheme.onErrorContainer)),
                              const SizedBox(height: 8),
                              ...issues.map((i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ',
                                            style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                                        Expanded(
                                            child: Text(i.message,
                                                style: TextStyle(color: theme.colorScheme.onErrorContainer))),
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
                        title: 'Warm-up', entries: template.warmup, catalogById: catalogById, planSection: resolvedPlan?.warmup),
                    const SizedBox(height: 12),
                    _SectionPreview(
                        title: 'Main', entries: template.main, catalogById: catalogById, planSection: resolvedPlan?.main),
                    const SizedBox(height: 12),
                    _SectionPreview(
                        title: 'Cool-down',
                        entries: template.cooldown,
                        catalogById: catalogById,
                        planSection: resolvedPlan?.cooldown),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.customWorkoutEdit(workoutId)),
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: resolvedPlan != null
                                ? () => context.push(AppRoutes.customWorkoutPlayer(workoutId))
                                : null,
                            child: const Text('Start'),
                          ),
                        ),
                      ],
                    ),
                    if (resolvedPlan == null) ...[
                      const SizedBox(height: 8),
                      Text('Fix the issues above to start this workout.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionPreview extends StatelessWidget {
  const _SectionPreview({required this.title, required this.entries, required this.catalogById, this.planSection});

  final String title;
  final List entries;
  final Map<String, Exercise> catalogById;
  final dynamic planSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Divider(),
            if (entries.isEmpty)
              Text('No exercises',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              for (final entry in entries) ...[
                Builder(
                  builder: (context) {
                    final Exercise? ex = catalogById[entry.exerciseId];
                    final isMissing = ex == null;
                    final workload = entry.isTimed
                        ? '${entry.sets} × ${entry.workDuration!.inSeconds}s'
                        : '${entry.sets} × ${entry.repsPerSet} reps';
                    final rest = '${entry.restBetweenSets.inSeconds}s rest';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isMissing)
                                  Text('Missing: ${entry.exerciseId}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600, color: theme.colorScheme.error))
                                else
                                  Text(ex.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                if (!isMissing)
                                  Text(
                                      '${ex.movementPattern?.label ?? ''} • ${ex.difficulty.name} • $workload • $rest',
                                      style: theme.textTheme.bodySmall),
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
        ),
      ),
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
