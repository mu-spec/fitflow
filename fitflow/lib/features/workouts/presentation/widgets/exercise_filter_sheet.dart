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
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    TextButton(
                      onPressed: () => onChanged(filter.clearFilters()),
                      child: const Text('Clear filters'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),
              _FilterSection(
                title: 'Movement Pattern',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: MovementPattern.values.map((pattern) {
                    final selected = filter.movementPatterns.contains(pattern);
                    return FilterChip(
                      label: Text(pattern.label),
                      selected: selected,
                      onSelected: (_) => _toggleMovement(pattern),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: 'Difficulty',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ExerciseDifficulty.values.map((diff) {
                    final selected = filter.difficulties.contains(diff);
                    final label = 'Level ${diff.name.replaceFirst('level', '')}';
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => _toggleDifficulty(diff),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: 'Equipment',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: WorkoutEquipment.values.map((eq) {
                    final selected = filter.equipment.contains(eq);
                    return FilterChip(
                      label: Text(eq.label),
                      selected: selected,
                      onSelected: (_) => _toggleEquipment(eq),
                    );
                  }).toList(),
                ),
              ),
              _FilterSection(
                title: 'Body Position',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ExercisePosition.values.map((pos) {
                    final selected = filter.positions.contains(pos);
                    return FilterChip(
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
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
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
