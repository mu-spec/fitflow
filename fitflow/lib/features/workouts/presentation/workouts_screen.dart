import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/core/design/media/program_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/presentation/widgets/workouts_program_cards.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'workouts_theme.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Visual V2 Workouts hub. Routes, destinations, active-program logic,
/// custom-workout CRUD and persisted state are unchanged — presentation only.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const WorkoutsTheme(child: _WorkoutsContent());
}

class _WorkoutsContent extends ConsumerWidget {
  const _WorkoutsContent();

  /// Restrained entrance for leading sections. Reduced motion is immediate.
  static Widget _entrance(BuildContext context, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: SystemMotion.standard(context),
      curve: FitFlowMotion.standardCurve,
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final v = FitFlowVisualV2.of(context);
    final customAsync = ref.watch(customWorkoutControllerProvider);

    // Root sizing reads MediaQuery directly, not a root LayoutBuilder: a
    // root-level LayoutBuilder on an offstage route-stack page can disturb
    // modal route presentation on the leaf page (builder screens push modals;
    // caught by the Part 6 cross-app tests).
    final width = MediaQuery.sizeOf(context).width;
    final inset = width < 360 ? FitFlowSpace.md : FitFlowSpace.screenHorizontal;
    return Scaffold(
      backgroundColor: v.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FitFlowMaxWidth(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: inset, vertical: FitFlowSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Page header — same header rhythm the product's
                  // canonical V2 Home established.
                  const _WorkoutsHeader(),
                  const SizedBox(height: FitFlowSpace.lg),

                  // B. Active program continuation (renders nothing when no
                  // real program is active). Behavior and texts unchanged.
                  const ActiveProgramCard(),

                  // Collection navigation, not an active/recommended program.
                  _entrance(context, const _ProgramsEntry()),
                  const SizedBox(height: FitFlowSpace.lg),

                  // D. Custom Workouts — clearly user-authored content.
                  _entrance(
                    context,
                    _CustomWorkoutsSection(customAsync: customAsync),
                  ),
                  const SizedBox(height: FitFlowSpace.lg),

                  // E. Explore — compact secondary tools, never rivaling
                  // the primary features.
                  _HubHeading(l.trainingExplore),
                  const SizedBox(height: FitFlowSpace.sm),
                  _entrance(context, const _ExploreTiles()),
                  const Divider(height: 1),
                  _HubNavigationRow(
                    title: l.trainingAdaptiveHome,
                    subtitle: l.trainingAdaptiveAction,
                    icon: Icons.home_outlined,
                    onTap: () => context.go(AppRoutes.home),
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

/// Local typography keeps the shared theme and other screens unchanged.
class _WorkoutsHeader extends StatelessWidget {
  const _WorkoutsHeader();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.homeBrand,
            style: text.labelMedium?.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: .8)),
        const SizedBox(height: FitFlowSpace.xs),
        Semantics(
          header: true,
          child: Text(l.trainingWorkoutsTitle,
              style: text.titleLarge
                  ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

/// Custom Workouts section: designed empty state and the existing authored
/// list, split from the screen so the section can enter as one unit.
class _CustomWorkoutsSection extends ConsumerWidget {
  const _CustomWorkoutsSection({required this.customAsync});

  final AsyncValue<List<CustomWorkoutTemplate>> customAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubHeading(l.trainingCustom),
        const SizedBox(height: FitFlowSpace.sm),
        customAsync.when(
          data: (templates) => templates.isEmpty
              ? Column(
                  key: const Key('v2_custom_empty'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.trainingCustomHelp,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: FitFlowSpace.sm),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.customWorkoutNew),
                      child: Text(l.trainingCreate),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.customWorkoutNew),
                        icon: const Icon(Icons.add),
                        label: Text(l.trainingCreateCustom),
                      ),
                    ),
                    for (var index = 0; index < templates.length; index++) ...[
                      if (index > 0) const Divider(),
                      _CustomWorkoutCard(template: templates[index]),
                    ],
                  ],
                ),
          loading: () => Padding(
              padding: const EdgeInsets.all(FitFlowSpace.lg),
              child: FitFlowLoading(label: context.l10n.trainingCustomLoading)),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.trainingCustomError),
              TextButton(
                onPressed: () => ref
                    .read(customWorkoutControllerProvider.notifier)
                    .refresh(),
                child: Text(l.trainingRetry),
              ),
            ],
          ),
        ),
      ],
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

    // Same resolve as before – diagnostic only, no fabricated stats if it fails.
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

    final firstMainEntry = template.main.isEmpty ? null : template.main.first;
    final firstMainExercise =
        firstMainEntry == null ? null : catalogById[firstMainEntry.exerciseId];

    return Padding(
      key: ValueKey('workouts_custom_${template.id}'),
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstMainExercise != null) ...[
                FitFlowExerciseImage.thumbnail(
                  exerciseId: firstMainExercise.id,
                  width: 52,
                  height: 52,
                ),
                const SizedBox(width: FitFlowSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        template.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: FitFlowSpace.xxs),
                    Text(
                      context.l10n.trainingCustomSummary(
                        workoutDurationLabel(
                          context.l10n,
                          template.targetDuration,
                        ),
                        totalExercises,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (estimated != null)
                      Text(
                        context.l10n.trainingEstimated(
                          FitFlowLocaleFormat.formatDuration(
                            context.l10n,
                            estimated,
                          ),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                popUpAnimationStyle: SystemMotion.overlay(context),
                tooltip: context.l10n.trainingMoreActions,
                onSelected: (value) async {
                  if (value == 'view') {
                    context.push(AppRoutes.customWorkoutDetail(template.id));
                  } else if (value == 'edit') {
                    context.push(AppRoutes.customWorkoutEdit(template.id));
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      animationStyle: SystemMotion.overlay(context),
                      builder: (ctx) => AlertDialog(
                        scrollable: true,
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
                            content: Text(context.l10n.trainingDeleteError),
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Text(context.l10n.trainingView),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.l10n.trainingEdit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.trainingDelete),
                  ),
                ],
              ),
            ],
          ),
          if (movementChips.isNotEmpty) ...[
            const SizedBox(height: FitFlowSpace.sm),
            Text(
              movementChips.join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: FitFlowSpace.sm),
          Wrap(
            spacing: FitFlowSpace.xs,
            runSpacing: FitFlowSpace.xs,
            children: [
              OutlinedButton(
                onPressed: () =>
                    context.push(AppRoutes.customWorkoutDetail(template.id)),
                child: Text(context.l10n.trainingView),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, SystemMotion.minTouchTarget),
                ),
                onPressed: () =>
                    context.push(AppRoutes.customWorkoutEdit(template.id)),
                child: Text(context.l10n.trainingEdit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Secondary destinations use the same compact native navigation rows.
class _ExploreTiles extends StatelessWidget {
  const _ExploreTiles();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final exerciseCount = ExerciseCatalog.all.where((e) => e.active).length;
    return Column(children: [
      _HubNavigationRow(
        title: l.trainingLibrary,
        subtitle: l.trainingBrowse(exerciseCount),
        icon: Icons.fitness_center_outlined,
        onTap: () => context.push(AppRoutes.exerciseLibrary),
      ),
      const Divider(height: 1),
      _HubNavigationRow(
        title: l.trainingSkills,
        icon: Icons.account_tree_outlined,
        onTap: () => context.push(AppRoutes.skillTrees),
      ),
    ]);
  }
}

class _ProgramsEntry extends StatelessWidget {
  const _ProgramsEntry();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
        final width = compact ? 80.0 : 104.0;
        return _HubNavigationRow(
          key: const Key('v2_programs_feature'),
          // A representative collection cover is decoration, never a recommendation.
          leading: FitFlowProgramImage(
            programId: ProgramMediaRegistry.entries.first.programId,
            width: width,
            height: width * 3 / 4,
          ),
          title: context.l10n.trainingPrograms,
          subtitle: context.l10n.trainingProgramsHelp,
          onTap: () => context.push(AppRoutes.programs),
        );
      });
}

class _HubHeading extends StatelessWidget {
  const _HubHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w500)),
      );
}

/// Native focus, press feedback and tap semantics without another enclosing card.
class _HubNavigationRow extends StatelessWidget {
  const _HubNavigationRow(
      {super.key,
      required this.title,
      required this.onTap,
      this.subtitle,
      this.icon,
      this.leading});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 64),
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
        foregroundColor: colors.brand,
      ),
      child: Row(children: [
        if (leading != null || icon != null) ...[
          leading ?? ExcludeSemantics(child: Icon(icon, size: 22)),
          const SizedBox(width: FitFlowSpace.sm),
        ],
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: text.titleMedium?.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: FitFlowSpace.xxs),
              Text(subtitle!,
                  style:
                      text.bodyMedium?.copyWith(color: colors.textSecondary)),
            ],
          ],
        )),
        const SizedBox(width: FitFlowSpace.xs),
        const ExcludeSemantics(child: Icon(Icons.chevron_right, size: 22)),
      ]),
    );
  }
}
