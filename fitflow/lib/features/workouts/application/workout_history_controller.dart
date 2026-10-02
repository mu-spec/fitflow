import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canonical history storage seam (M21 Part 1).
///
/// Built once from the shared SharedPreferences provider and reused by every
/// controller operation instead of re-acquiring preferences and
/// re-constructing storage on each add/refresh/clear. Tests may override it
/// to inject a fake storage.
final workoutHistoryStorageProvider =
    FutureProvider<WorkoutHistoryStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return WorkoutHistoryStorage(prefs);
});

final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryController, List<CompletedWorkout>>(
  WorkoutHistoryController.new,
);

class WorkoutHistoryController extends AsyncNotifier<List<CompletedWorkout>> {
  /// One canonical storage instance per container, resolved lazily.
  Future<WorkoutHistoryStorage> _storage() =>
      ref.read(workoutHistoryStorageProvider.future);

  @override
  Future<List<CompletedWorkout>> build() async {
    final storage = await _storage();
    return storage.load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final storage = await _storage();
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
      final storage = await _storage();
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
      final storage = await _storage();
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
