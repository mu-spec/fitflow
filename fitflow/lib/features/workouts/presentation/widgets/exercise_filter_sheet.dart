import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:flutter/material.dart';

class ExerciseFilterSheet extends StatelessWidget {
  const ExerciseFilterSheet({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final ExerciseLibraryFilter filter;
  final ValueChanged<ExerciseLibraryFilter> onChanged;

  void _toggleMovement(MovementPattern pattern) {
    final next = Set<MovementPattern>.from(filter.movementPatterns);
    if (next.contains(pattern)) {
      next.remove(pattern);
    } else {
      next.add(pattern);
    }
    onChanged(filter.copyWith(movementPatterns: next));
  }

  void _toggleDifficulty(ExerciseDifficulty difficulty) {
    final next = Set<ExerciseDifficulty>.from(filter.difficulties);
    if (next.contains(difficulty)) {
      next.remove(difficulty);
    } else {
      next.add(difficulty);
    }
    onChanged(filter.copyWith(difficulties: next));
  }

  void _toggleEquipment(WorkoutEquipment equipment) {
    final next = Set<WorkoutEquipment>.from(filter.equipment);
    if (next.contains(equipment)) {
      next.remove(equipment);
    } else {
      next.add(equipment);
    }
    onChanged(filter.copyWith(equipment: next));
  }

  void _togglePosition(ExercisePosition position) {
    final next = Set<ExercisePosition>.from(filter.positions);
    if (next.contains(position)) {
      next.remove(position);
    } else {
      next.add(position);
    }
    onChanged(filter.copyWith(positions: next));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TrainingHeading(context.l10n.filters),
                  if (filter.hasActiveFilters)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => onChanged(filter.clearFilters()),
                      child: Text(context.l10n.trainingClearFilters),
                    ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: context.l10n.trainingClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),
              _FilterSection(
                title: context.l10n.trainingMovement,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: MovementPattern.values.map((pattern) {
                    final selected = filter.movementPatterns.contains(pattern);
                    return FilterChip(
                      showCheckmark: true,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      chipAnimationStyle: ChipAnimationStyle(
                          selectAnimation: AnimationStyle(
                              duration: SystemMotion.micro(context),
                              reverseDuration: SystemMotion.micro(context))),
                      label: Text(movementPatternLabel(context.l10n, pattern)),
                      selected: selected,
                      onSelected: (_) => _toggleMovement(pattern),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: context.l10n.trainingDifficulty,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ExerciseDifficulty.values.map((diff) {
                    final selected = filter.difficulties.contains(diff);
                    final label = trainingDifficultyLabel(context.l10n, diff);
                    return FilterChip(
                      showCheckmark: true,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      chipAnimationStyle: ChipAnimationStyle(
                          selectAnimation: AnimationStyle(
                              duration: SystemMotion.micro(context),
                              reverseDuration: SystemMotion.micro(context))),
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => _toggleDifficulty(diff),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: context.l10n.trainingEquipment,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: WorkoutEquipment.values.map((eq) {
                    final selected = filter.equipment.contains(eq);
                    return FilterChip(
                      showCheckmark: true,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      chipAnimationStyle: ChipAnimationStyle(
                          selectAnimation: AnimationStyle(
                              duration: SystemMotion.micro(context),
                              reverseDuration: SystemMotion.micro(context))),
                      label: Text(equipmentLabel(context.l10n, eq)),
                      selected: selected,
                      onSelected: (_) => _toggleEquipment(eq),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: context.l10n.trainingPosition,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ExercisePosition.values.map((pos) {
                    final selected = filter.positions.contains(pos);
                    return FilterChip(
                      showCheckmark: true,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      chipAnimationStyle: ChipAnimationStyle(
                          selectAnimation: AnimationStyle(
                              duration: SystemMotion.micro(context),
                              reverseDuration: SystemMotion.micro(context))),
                      label: Text(pos.label),
                      selected: selected,
                      onSelected: (_) => _togglePosition(pos),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.trainingDone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
