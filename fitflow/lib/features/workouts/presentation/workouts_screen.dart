import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/widgets/placeholder_row.dart';
import 'package:fitflow/core/widgets/placeholder_section.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/presentation/widgets/workouts_program_cards.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exerciseCount = ExerciseCatalog.all.where((e) => e.active).length;
    final customAsync = ref.watch(customWorkoutControllerProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your workouts', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            PlaceholderRow(
              icon: Icons.fitness_center,
              title: 'Exercise Library',
              subtitle: 'Browse $exerciseCount exercises',
              onTap: () => context.push(AppRoutes.exerciseLibrary),
            ),
            const PlaceholderSection(
                title: 'Recommended', subtitle: 'Workouts picked for your level and history.'),
            // M16 Part 1 – real Programs entry replaces the old placeholder.
            const ProgramsEntryRow(),
            const ActiveProgramCard(),
            const RecommendedProgramCard(),
            const SizedBox(height: 8),
            _CreateCustomRow(onTap: () => context.push(AppRoutes.customWorkoutNew)),
            PlaceholderRow(
              icon: Icons.account_tree_outlined,
              title: 'Exercise skill trees',
              subtitle:
                  'Explore exercise progressions from easier to harder variations.',
              onTap: () => context.push(AppRoutes.skillTrees),
            ),
            const SizedBox(height: 16),
            Text('Custom workouts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            customAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return _EmptyCustomState(onCreate: () => context.push(AppRoutes.customWorkoutNew));
                }
                return Column(
                  children: [
                    for (final t in templates) _CustomWorkoutCard(template: t),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Could not load custom workouts.'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => ref.read(customWorkoutControllerProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCustomRow extends StatelessWidget {
  const _CreateCustomRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          onTap: onTap,
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Create custom workout'),
          subtitle: Text(
            'Build your own workout with exercises from your library.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _EmptyCustomState extends StatelessWidget {
  const _EmptyCustomState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No custom workouts yet',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Build your own workout with exercises from your library.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomWorkoutCard extends ConsumerWidget {
  const _CustomWorkoutCard({required this.template});
  final CustomWorkoutTemplate template;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s > 0 ? '${s}s' : ''}'.trim();
    return '${s}s';
  }

  String _targetLabel(WorkoutDuration dur) {
    return dur.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogById = {for (final Exercise e in ExerciseCatalog.all) e.id: e};

    // Try to resolve for estimated and movement focus chips – diagnostic only, no fabricated stats if fails
    WorkoutPlan? resolvedPlan;
    try {
      final userProfile = ref.watch(userFitnessProfileProvider).value;
      final capabilityProfile = ref.watch(capabilityProfileProvider).value;
      if (userProfile != null && capabilityProfile != null) {
        final resolution = CustomWorkoutPlanResolver.resolve(
          template: template,
          catalogById: catalogById,
          userFitnessProfile: userProfile,
          capabilityProfile: capabilityProfile,
        );
        resolvedPlan = resolution.plan;
      }
    } catch (_) {}

    final totalExercises = template.totalExerciseCount;
    final estimated = resolvedPlan?.estimatedDuration;

    // Movement focus chips from Main
    final movementChips = <String>{};
    for (final entry in template.main) {
      final ex = catalogById[entry.exerciseId];
      if (ex?.movementPattern != null) {
        movementChips.add(ex!.movementPattern!.label);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${_targetLabel(template.targetDuration)} • $totalExercises exercises'
                        '${estimated != null ? ' • Est: ${_formatDuration(estimated)}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (movementChips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final chip in movementChips.take(4))
                              Chip(
                                label: Text(chip),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'view') {
                      context.push(AppRoutes.customWorkoutDetail(template.id));
                    } else if (value == 'edit') {
                      context.push(AppRoutes.customWorkoutEdit(template.id));
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete custom workout?'),
                          content: const Text(
                              'This removes the saved workout. Completed workout history is not deleted.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        final success = await ref
                            .read(customWorkoutControllerProvider.notifier)
                            .delete(template.id);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Couldn't delete this workout. Try again.")),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'view', child: Text('View')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.customWorkoutDetail(template.id)),
                  child: const Text('View'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.customWorkoutEdit(template.id)),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
