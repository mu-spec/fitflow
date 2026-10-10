import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/presentation/widgets/workouts_program_cards.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
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

    final l = context.l10n;
    return Material(
        type: MaterialType.transparency,
        child: SafeArea(
            child: FitFlowMaxWidth(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TrainingHeading(l.trainingWorkoutsTitle, large: true),
            const SizedBox(height: 8),
            Text(l.trainingWorkoutsIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Card(
                child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title:
                  Text(l.trainingPrograms, style: theme.textTheme.titleLarge),
              subtitle: Text(l.trainingProgramsHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.programs),
            )),
            const ActiveProgramCard(),
            const SizedBox(height: 24),
            TrainingHeading(l.trainingCustom),
            const SizedBox(height: 8),
            customAsync.when(
              data: (templates) => templates.isEmpty
                  ? _EmptyCustomState(
                      onCreate: () => context.push(AppRoutes.customWorkoutNew))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    context.push(AppRoutes.customWorkoutNew),
                                icon: const Icon(Icons.add),
                                label: Text(l.trainingCreateCustom),
                              )),
                          for (final template in templates)
                            _CustomWorkoutCard(template: template),
                        ]),
              loading: () => Padding(
                  padding: const EdgeInsets.all(24),
                  child: FitFlowLoading(
                      label: context.l10n.trainingCustomLoading)),
              error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.trainingCustomError),
                    TextButton(
                        onPressed: () => ref
                            .read(customWorkoutControllerProvider.notifier)
                            .refresh(),
                        child: Text(l.trainingRetry)),
                  ]),
            ),
            const SizedBox(height: 24),
            TrainingHeading(l.trainingExplore),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.trainingLibrary),
              subtitle: Text(l.trainingBrowse(exerciseCount)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.exerciseLibrary),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.trainingSkills),
              subtitle: Text(l.trainingSkillsHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.skillTrees),
            ),
            const SizedBox(height: 24),
            Text(l.trainingAdaptiveHome, style: theme.textTheme.bodyMedium),
            TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l.trainingAdaptiveAction)),
          ]),
        ))));
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
            Text(context.l10n.trainingCustomEmpty,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(context.l10n.trainingCustomHelp,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onCreate,
              child: Text(context.l10n.trainingCreate),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogById = ExerciseCatalog.byIdMap;

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
        movementChips
            .add(movementPatternLabel(context.l10n, ex!.movementPattern!));
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
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.trainingCustomSummary(
                            workoutDurationLabel(
                                context.l10n, template.targetDuration),
                            totalExercises),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (estimated != null)
                        Text(
                            context.l10n.trainingEstimated(
                                FitFlowLocaleFormat.formatDuration(
                                    context.l10n, estimated)),
                            style: theme.textTheme.bodySmall),
                      if (movementChips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(movementChips.take(4).join(' · '),
                            style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: context.l10n.trainingMoreActions,
                  onSelected: (value) async {
                    if (value == 'view') {
                      context.push(AppRoutes.customWorkoutDetail(template.id));
                    } else if (value == 'edit') {
                      context.push(AppRoutes.customWorkoutEdit(template.id));
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(context.l10n.trainingDeleteTitle),
                          content: Text(context.l10n.trainingDeleteBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(context.l10n.trainingCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(context.l10n.trainingDelete),
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
                            SnackBar(
                                content:
                                    Text(context.l10n.trainingDeleteError)),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'view', child: Text(context.l10n.trainingView)),
                    PopupMenuItem(
                        value: 'edit', child: Text(context.l10n.trainingEdit)),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.trainingDelete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.customWorkoutDetail(template.id)),
                  child: Text(context.l10n.trainingView),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.customWorkoutEdit(template.id)),
                  child: Text(context.l10n.trainingEdit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
