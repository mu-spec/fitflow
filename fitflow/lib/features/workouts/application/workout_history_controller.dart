import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final workoutHistoryStorageProvider = Provider<WorkoutHistoryStorage>((ref) {
  throw UnimplementedError('workoutHistoryStorageProvider must be overridden with SharedPreferences');
});

final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryController, List<CompletedWorkout>>(
  WorkoutHistoryController.new,
);

class WorkoutHistoryController extends AsyncNotifier<List<CompletedWorkout>> {
  @override
  Future<List<CompletedWorkout>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = WorkoutHistoryStorage(prefs);
    return storage.load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final loaded = storage.load();
      state = AsyncData(loaded);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Add a completed workout, deduplicate by id, newest first, cap 100.
  /// Returns true if saved or already exists.
  Future<bool> addWorkout(CompletedWorkout workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final result = await storage.add(workout);
      if (result) {
        // Update state optimistically, reload to ensure consistency
        final current = state.valueOrNull ?? [];
        if (!current.any((e) => e.id == workout.id)) {
          final newList = <CompletedWorkout>[workout, ...current];
          final trimmed = newList.length > WorkoutHistoryStorage.maxEntries ? newList.take(WorkoutHistoryStorage.maxEntries).toList() : newList;
          trimmed.sort((a, b) => b.completedAt.compareTo(a.completedAt));
          state = AsyncData(trimmed);
        }
      }
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final result = await storage.clear();
      if (result) {
        state = const AsyncData([]);
      }
      return result;
    } catch (_) {
      return false;
    }
  }
}
