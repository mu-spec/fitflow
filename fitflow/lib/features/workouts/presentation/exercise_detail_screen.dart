import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
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
          title: const Text('Exercise not found'),
        ),
        body: _NotFoundBody(exerciseId: exerciseId),
      );
    }

    final progression = ExerciseProgressionResolver.resolve(exercise);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(exercise: exercise),
            const SizedBox(height: 24),
            _PrescriptionSection(exercise: exercise),
            if (progression != null) ...[
              const SizedBox(height: 24),
              ExerciseProgressionSection(progression: progression),
            ],
            const SizedBox(height: 24),
            _MusclesSection(exercise: exercise),
            const SizedBox(height: 24),
            _EquipmentSection(exercise: exercise),
            const SizedBox(height: 24),
            _HowToSection(exercise: exercise),
            const SizedBox(height: 24),
            _MistakesSection(exercise: exercise),
            const SizedBox(height: 24),
            _BreathingSection(exercise: exercise),
            const SizedBox(height: 24),
            ExerciseCharacteristicsSection(exercise: exercise),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
              'Exercise not found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This exercise is no longer available.',
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
              label: const Text('Back'),
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

  String _levelLabel() {
    final levelNumber = exercise.difficulty.name.replaceFirst('level', '');
    return 'Level $levelNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Illustration coming soon',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
              color: colorScheme.onSurfaceVariant,
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
                label: exercise.movementPattern!.label,
              ),
            _MetaChip(
              icon: Icons.signal_cellular_alt,
              label: _levelLabel(),
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
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
    );
  }
}

class _PrescriptionSection extends StatelessWidget {
  const _PrescriptionSection({required this.exercise});

  final Exercise exercise;

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    if (seconds == 1) return '1 second';
    return '$seconds seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String prescription;
    if (exercise.exerciseType == ExerciseType.reps) {
      if (exercise.defaultReps != null) {
        prescription = '${exercise.defaultReps} reps';
      } else {
        prescription = 'Reps';
      }
    } else {
      if (exercise.defaultDuration != null) {
        prescription = _formatDuration(exercise.defaultDuration!);
      } else {
        prescription = 'Timed';
      }
    }

    final rest = exercise.defaultRest != null
        ? 'Rest: ${_formatDuration(exercise.defaultRest!)}'
        : null;

    return _SectionCard(
      title: 'Default Prescription',
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
                          color: colorScheme.onSurfaceVariant,
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
      title: 'Muscles Worked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary',
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
              'Secondary',
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
                        side: BorderSide(
                            color: theme.colorScheme.outlineVariant),
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

    String label;
    List<Widget> chips;
    if (equipment.isEmpty ||
        equipment.contains(WorkoutEquipment.none)) {
      label = 'No equipment';
      chips = [
        Chip(
          label: const Text('No equipment'),
          avatar: const Icon(Icons.check_circle_outline, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ];
    } else {
      label = equipment.map((e) => e.label).join(' • ');
      chips = equipment
          .map((e) => Chip(
                label: Text(e.label),
                visualDensity: VisualDensity.compact,
              ))
          .toList();
    }

    return _SectionCard(
      title: 'Equipment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _HowToSection extends StatelessWidget {
  const _HowToSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'How to Perform',
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
                    width: 28,
                    height: 28,
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
      title: 'Common Mistakes',
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
      title: 'Breathing',
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
