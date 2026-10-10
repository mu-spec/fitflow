import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_characteristics_section.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_progression_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final exercise = ExerciseCatalog.byId(exerciseId);

    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.trainingNotFound),
        ),
        body: _NotFoundBody(exerciseId: exerciseId),
      );
    }

    final progression = ExerciseProgressionResolver.resolve(exercise);
    final skillTreeFamilyId = _skillTreeFamilyIdFor(exercise);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        centerTitle: false,
      ),
      body: FitFlowMaxWidth(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(exercise: exercise),
            const SizedBox(height: 24),
            _EquipmentSection(exercise: exercise),
            const SizedBox(height: 24),
            if (exercise.instructions.isNotEmpty)
              _HowToSection(exercise: exercise),
            const SizedBox(height: 24),
            _MusclesSection(exercise: exercise),
            if (exercise.commonMistakes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _MistakesSection(exercise: exercise),
            ],
            if (exercise.breathingGuidance != null) ...[
              const SizedBox(height: 24),
              _BreathingSection(exercise: exercise),
            ],
            if (progression != null) ...[
              const SizedBox(height: 24),
              ExerciseProgressionSection(
                  progression: progression,
                  skillTreeFamilyId: skillTreeFamilyId),
            ],
            const SizedBox(height: 24),
            TrainingDisclosure(
                title: context.l10n.trainingDefaults,
                children: [_PrescriptionSection(exercise: exercise)]),
            TrainingDisclosure(
                title: context.l10n.trainingCatalogDetails,
                children: [ExerciseCharacteristicsSection(exercise: exercise)]),
            const SizedBox(height: 32),
          ],
        ),
      )),
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.exercise});

  final Exercise exercise;

  String _levelLabel(BuildContext context) {
    return trainingDifficultyLabel(context.l10n, exercise.difficulty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExerciseArtwork(),
        const SizedBox(height: 16),
        Text(
          exercise.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (exercise.shortDescription != null) ...[
          const SizedBox(height: 8),
          Text(
            exercise.shortDescription!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (exercise.movementPattern != null)
              _MetaChip(
                icon: Icons.category_outlined,
                label: movementPatternLabel(
                    context.l10n, exercise.movementPattern!),
              ),
            _MetaChip(
              icon: Icons.signal_cellular_alt,
              label: _levelLabel(context),
            ),
            _MetaChip(
              icon: exercise.exerciseType == ExerciseType.reps
                  ? Icons.repeat
                  : Icons.timer_outlined,
              label: exercise.exerciseType.label,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TrainingFact(label, icon: icon);
  }
}

class _PrescriptionSection extends StatelessWidget {
  const _PrescriptionSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    return _SectionCard(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  exercise.exerciseType == ExerciseType.reps
                      ? Icons.repeat
                      : Icons.timer_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (rest != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        rest,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
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
    final equipment = exercise.requiredEquipment;

    final label = equipment.isEmpty || equipment.contains(WorkoutEquipment.none)
        ? context.l10n.trainingNoEquipment
        : equipment.map((e) => equipmentLabel(context.l10n, e)).join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TrainingHeading(context.l10n.trainingEquipment),
      const SizedBox(height: 8),
      Text(label, style: theme.textTheme.bodyMedium),
    ]);
  }
}

class _HowToSection extends StatelessWidget {
  const _HowToSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
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
                        color: theme.colorScheme.error,
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
          Icon(
            Icons.air,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              TrainingHeading(title),
              const SizedBox(height: 12)
            ],
            child,
          ],
        ),
      ),
    );
  }
}
