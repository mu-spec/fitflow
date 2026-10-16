import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_card.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
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

/// Visual V2 Workouts hub. Routes, destinations, active-program logic,
/// custom-workout CRUD and persisted state are unchanged — presentation only.
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  /// Artwork always yields before text; the user's text never shrinks.
  static double _featureArtHeight(BuildContext context, double width) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    if (largeText) return 76;
    if (width < 360) return 96;
    return 116;
  }

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
    final artHeight = _featureArtHeight(context, width);
    return Scaffold(
      backgroundColor: v.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FitFlowMaxWidth(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: inset, vertical: FitFlowSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Page header — same header rhythm the product's
                  // canonical V2 Home established.
                  const _WorkoutsHeader(),
                  const SizedBox(height: FitFlowSpace.xl),

                  // B. Active program continuation (renders nothing when no
                  // real program is active). Behavior and texts unchanged.
                  const ActiveProgramCard(),

                  // C. Programs — the primary discovery feature, carrying
                  // the strongest visual weight with original art.
                  _entrance(
                    context,
                    FitFlowV2FeatureCard(
                      key: const Key('v2_programs_feature'),
                      art: FitFlowV2FeatureArtKind.programs,
                      title: l.trainingPrograms,
                      subtitle: l.trainingProgramsHelp,
                      artHeight: artHeight,
                      onTap: () => context.push(AppRoutes.programs),
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.xl),

                  // D. Custom Workouts — clearly user-authored content.
                  _entrance(
                    context,
                    _CustomWorkoutsSection(
                        customAsync: customAsync, artHeight: artHeight),
                  ),
                  const SizedBox(height: FitFlowSpace.xl),

                  // E. Explore — compact secondary tools, never rivaling
                  // the primary features.
                  TrainingHeading(l.trainingExplore),
                  const SizedBox(height: FitFlowSpace.sm),
                  _entrance(context, const _ExploreTiles()),
                  const SizedBox(height: FitFlowSpace.xl),

                  // F. Adaptive note — preserved verbatim.
                  FitFlowV2InfoSurface(
                    tonal: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.trainingAdaptiveHome,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: v.onTint)),
                        const SizedBox(height: FitFlowSpace.xxs),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.home),
                          style: TextButton.styleFrom(
                              minimumSize: const Size(64, 48)),
                          child: Text(l.trainingAdaptiveAction),
                        ),
                      ],
                    ),
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

/// Workouts page header: brand kicker, page title, one-line intro.
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
            style:
                text.labelMedium?.copyWith(color: t.brand, letterSpacing: 1.2)),
        const SizedBox(height: FitFlowSpace.xs),
        Semantics(
          header: true,
          child: Text(l.trainingWorkoutsTitle, style: text.headlineMedium),
        ),
        const SizedBox(height: FitFlowSpace.sm),
        Text(l.trainingWorkoutsIntro,
            style: text.bodyLarge?.copyWith(color: t.textSecondary)),
      ],
    );
  }
}

/// Custom Workouts section: designed empty state and the existing authored
/// list, split from the screen so the section can enter as one unit.
class _CustomWorkoutsSection extends ConsumerWidget {
  const _CustomWorkoutsSection(
      {required this.customAsync, required this.artHeight});

  final AsyncValue<List<CustomWorkoutTemplate>> customAsync;
  final double artHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingHeading(l.trainingCustom),
        const SizedBox(height: FitFlowSpace.sm),
        customAsync.when(
          data: (templates) => templates.isEmpty
              ? FitFlowV2FeatureCard(
                  key: const Key('v2_custom_empty'),
                  art: FitFlowV2FeatureArtKind.customWorkout,
                  title: l.trainingCustomEmpty,
                  subtitle: l.trainingCustomHelp,
                  emphasis: FitFlowV2FeatureCardEmphasis.secondary,
                  artHeight: artHeight - 20,
                  primaryAction: FilledButton(
                    onPressed: () => context.push(AppRoutes.customWorkoutNew),
                    child: Text(l.trainingCreate),
                  ),
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
                    for (final template in templates)
                      _CustomWorkoutCard(template: template),
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
      padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
      child: FitFlowV2InfoSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (firstMainExercise != null) ...[
                  FitFlowV2ExerciseMedia.forExercise(
                    exercise: firstMainExercise,
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
                              ?.copyWith(fontWeight: FontWeight.w600),
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
              Wrap(
                spacing: FitFlowSpace.xs,
                runSpacing: FitFlowSpace.xs,
                children:
                    movementChips.map((label) => FitFlowV2Tag(label)).toList(),
              ),
            ],
            const SizedBox(height: FitFlowSpace.sm),
            Wrap(
              spacing: FitFlowSpace.xs,
              runSpacing: FitFlowSpace.xs,
              children: [
                FilledButton(
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
      ),
    );
  }
}

/// Secondary Explore destinations in a two-column grid only when labels stay
/// readable; otherwise a single readable column. Same two real routes.
class _ExploreTiles extends StatelessWidget {
  const _ExploreTiles();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final exerciseCount = ExerciseCatalog.all.where((e) => e.active).length;
    final library = FitFlowV2ExploreTile(
      art: FitFlowV2FeatureArtKind.exerciseLibrary,
      title: l.trainingLibrary,
      subtitle: l.trainingBrowse(exerciseCount),
      onTap: () => context.push(AppRoutes.exerciseLibrary),
    );
    final skills = FitFlowV2ExploreTile(
      art: FitFlowV2FeatureArtKind.skillTree,
      title: l.trainingSkills,
      subtitle: l.trainingSkillsHelp,
      onTap: () => context.push(AppRoutes.skillTrees),
    );
    return LayoutBuilder(builder: (context, c) {
      final two =
          c.maxWidth >= 520 && MediaQuery.textScalerOf(context).scale(16) <= 22;
      if (!two) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            library,
            const SizedBox(height: FitFlowSpace.sm),
            skills,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: library),
          const SizedBox(width: FitFlowSpace.sm),
          Expanded(child: skills),
        ],
      );
    });
  }
}
