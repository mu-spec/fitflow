import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:flutter/material.dart';

/// Read-only Exercise Library showing all 80 active exercises from [ExerciseCatalog].
class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key, this.exercisesForTest});

  /// Optional override for testing empty-state handling.
  /// When null, uses [ExerciseCatalog.all] filtered to active exercises.
  final List<Exercise>? exercisesForTest;

  @override
  Widget build(BuildContext context) {
    final exercises =
        exercisesForTest ?? ExerciseCatalog.all.where((e) => e.active).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        centerTitle: false,
      ),
      body: exercises.isEmpty
          ? _EmptyState(theme: theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '${exercises.length} exercises',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ExerciseListTile(exercise: exercise);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises available',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The exercise catalog is currently empty. Please check back later.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
