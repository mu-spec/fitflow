import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:flutter/services.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_characteristics_section.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_progression_section.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final exercise = ExerciseCatalog.byId(exerciseId);
    final visual = FitFlowVisualV2.of(context);

    if (exercise == null) {
      return Scaffold(
        backgroundColor: visual.page,
        appBar: AppBar(
          title: Text(context.l10n.trainingNotFound),
          centerTitle: false,
          toolbarHeight: 56 +
              (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 3) * 48,
          backgroundColor: visual.page,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: FitFlowMaxWidth(
            child: _NotFoundBody(exerciseId: exerciseId),
          ),
        ),
      );
    }

    final progression = ExerciseProgressionResolver.resolve(exercise);
    final skillTreeFamilyId = _skillTreeFamilyIdFor(exercise);

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        title: Text(context.l10n.trainingDetails,
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: false,
        toolbarHeight: 56 +
            (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 3) * 48,
        backgroundColor: visual.page,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: FitFlowMaxWidth(
          maxWidth: FitFlowLayout.maxContentWidth,
          child: SingleChildScrollView(
            key: const ValueKey('exercise_detail_scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              FitFlowSpace.md,
              FitFlowSpace.sm,
              FitFlowSpace.md,
              FitFlowSpace.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(exercise: exercise),
                const SizedBox(height: FitFlowSpace.sm),
                _EquipmentSection(exercise: exercise),
                const SizedBox(height: FitFlowSpace.sm),
                if (exercise.instructions.isNotEmpty)
                  _HowToSection(exercise: exercise),
                const SizedBox(height: FitFlowSpace.md),
                _MusclesSection(exercise: exercise),
                if (exercise.commonMistakes.isNotEmpty) ...[
                  const SizedBox(height: FitFlowSpace.md),
                  _MistakesSection(exercise: exercise),
                ],
                if (exercise.breathingGuidance != null) ...[
                  const SizedBox(height: FitFlowSpace.md),
                  _BreathingSection(exercise: exercise),
                ],
                if (progression != null) ...[
                  const SizedBox(height: FitFlowSpace.md),
                  ExerciseProgressionSection(
                    progression: progression,
                    skillTreeFamilyId: skillTreeFamilyId,
                  ),
                ],
                const SizedBox(height: FitFlowSpace.md),
                TrainingDisclosure(
                  title: context.l10n.trainingDefaults,
                  children: [_PrescriptionSection(exercise: exercise)],
                ),
                TrainingDisclosure(
                  title: context.l10n.trainingCatalogDetails,
                  children: [
                    ExerciseCharacteristicsSection(exercise: exercise)
                  ],
                ),
                const SizedBox(height: FitFlowSpace.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _skillTreeFamilyIdFor(Exercise exercise) {
  final familyId = exercise.progressionFamilyId?.trim();
  if (familyId == null || familyId.isEmpty) return null;

  final catalog = ExerciseSkillTreeResolver.resolve(
    exercises: ExerciseCatalog.all,
    userProfile: null,
    capabilityProfile: null,
  );
  final tree = catalog.treeForFamilyId(familyId);
  if (tree == null ||
      !tree.nodes.any((node) => node.exercise.id == exercise.id)) {
    return null;
  }
  return tree.familyId;
}

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.trainingNotFound,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.trainingNotFoundHelp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              onPressed: () {
                try {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go(AppRoutes.exerciseLibrary);
                  }
                  return;
                } catch (_) {
                  // No GoRouter in context, fallback to Navigator
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(context.l10n.trainingBack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolve bundled availability once per asset bundle, never by display name.
/// Missing photography keeps the detail text-first; decoding/error handling
/// for supplied media stays in the existing production renderer.
class _HeroSection extends StatefulWidget {
  const _HeroSection({required this.exercise});
  final Exercise exercise;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  AssetBundle? _bundle;
  late Future<AssetManifest> _manifest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _manifest = AssetManifest.loadFromAssetBundle(bundle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final path = ExerciseMediaRegistry.lookup(exercise.id)?.hero.path;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            exercise.name,
            key: const ValueKey('exercise_detail_title'),
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        Wrap(
          spacing: FitFlowSpace.md,
          runSpacing: FitFlowSpace.xs,
          children: [
            if (exercise.movementPattern != null)
              _MetaChip(
                icon: Icons.category_outlined,
                label: movementPatternLabel(
                    context.l10n, exercise.movementPattern!),
              ),
            _MetaChip(
              icon: Icons.signal_cellular_alt_rounded,
              label: trainingDifficultyLabel(context.l10n, exercise.difficulty),
            ),
            _MetaChip(
              icon: exercise.exerciseType == ExerciseType.reps
                  ? Icons.repeat_rounded
                  : Icons.timer_outlined,
              label: exercise.exerciseType.label,
            ),
          ],
        ),
        if (exercise.shortDescription != null) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            exercise.shortDescription!,
            key: const ValueKey('exercise_detail_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );

    return FutureBuilder<AssetManifest>(
      future: _manifest,
      builder: (context, snapshot) {
        final available = path != null &&
            (snapshot.data?.listAssets().contains(path) ?? false);
        if (!available) return identity;
        return LayoutBuilder(builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= 600 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.6;
          final width = sideBySide
              ? (constraints.maxWidth - FitFlowSpace.xl) / 2
              : constraints.maxWidth;
          final media = FitFlowExerciseImage.hero(
            key: const ValueKey('exercise_detail_media'),
            exerciseId: exercise.id,
            width: width,
            height: width * 3 / 4,
          );
          return sideBySide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    media,
                    const SizedBox(width: FitFlowSpace.xl),
                    Expanded(child: identity),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    media,
                    const SizedBox(height: FitFlowSpace.sm),
                    identity,
                  ],
                );
        });
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FitFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: 16, color: colors.brand),
        ),
        const SizedBox(width: FitFlowSpace.xxs),
        Flexible(
          child: Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  )),
        ),
      ],
    );
  }
}

class _PrescriptionSection extends StatelessWidget {
  const _PrescriptionSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);

    String prescription;
    if (exercise.exerciseType == ExerciseType.reps) {
      if (exercise.defaultReps != null) {
        prescription = context.l10n.flowReps(exercise.defaultReps!);
      } else {
        prescription = 'Reps';
      }
    } else {
      if (exercise.defaultDuration != null) {
        prescription = FitFlowLocaleFormat.formatDuration(
            context.l10n, exercise.defaultDuration!);
      } else {
        prescription = 'Timed';
      }
    }

    final rest = exercise.defaultRest != null
        ? context.l10n.trainingRest(FitFlowLocaleFormat.formatDuration(
            context.l10n, exercise.defaultRest!))
        : null;

    return FitFlowV2InfoSurface(
      tonal: true,
      padding: const EdgeInsets.all(FitFlowSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: visual.onTint.withValues(alpha: .08),
                borderRadius: FitFlowRadius.mediumBorder,
              ),
              child: Icon(
                exercise.exerciseType == ExerciseType.reps
                    ? Icons.repeat_rounded
                    : Icons.timer_outlined,
                color: FitFlowTheme.of(context).brand,
              ),
            ),
          ),
          const SizedBox(width: FitFlowSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: visual.onTint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rest != null) ...[
                  const SizedBox(height: FitFlowSpace.xxs),
                  Text(
                    rest,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: FitFlowTheme.of(context).textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MusclesSection extends StatelessWidget {
  const _MusclesSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);

    return _SectionCard(
      title: context.l10n.trainingMuscles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.trainingPrimary,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (exercise.primaryMuscles.isEmpty)
            Text(
              '—',
              style: theme.textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.primaryMuscles
                  .map((m) => Chip(
                        label: Text(m.label),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: visual.tint,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 16),
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            Text(
              context.l10n.trainingSecondary,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.secondaryMuscles
                  .map((m) => Chip(
                        label: Text(m.label),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: visual.support,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final equipment = exercise.requiredEquipment;
    final label = equipment.isEmpty || equipment.contains(WorkoutEquipment.none)
        ? context.l10n.trainingNoEquipment
        : equipment.map((e) => equipmentLabel(context.l10n, e)).join(' · ');
    return Row(
      key: const ValueKey('exercise_detail_equipment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.fitness_center_outlined,
              size: 20, color: colors.brand),
        ),
        const SizedBox(width: FitFlowSpace.xs),
        Expanded(
          child: Wrap(
            spacing: FitFlowSpace.xs,
            runSpacing: FitFlowSpace.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.l10n.trainingEquipment,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary)),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowToSection extends StatelessWidget {
  const _HowToSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);

    return _SectionCard(
      title: context.l10n.trainingHowTo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < exercise.instructions.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == exercise.instructions.length - 1 ? 0 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: visual.tint,
                      borderRadius: FitFlowRadius.smallBorder,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: FitFlowTheme.of(context).brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.instructions[i],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MistakesSection extends StatelessWidget {
  const _MistakesSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = FitFlowTheme.of(context).error;

    return _SectionCard(
      title: context.l10n.trainingMistakes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < exercise.commonMistakes.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == exercise.commonMistakes.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exercise.commonMistakes[i],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BreathingSection extends StatelessWidget {
  const _BreathingSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: context.l10n.trainingBreathing,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.air,
              size: 20,
              color: FitFlowTheme.of(context).textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.breathingGuidance ?? '—',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: FitFlowTheme.of(context).divider),
        const SizedBox(height: FitFlowSpace.sm),
        if (title.isNotEmpty) ...[
          TrainingHeading(title),
          const SizedBox(height: FitFlowSpace.xs),
        ],
        child,
      ],
    );
  }
}
