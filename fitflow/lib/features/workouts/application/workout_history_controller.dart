import 'package:fitflow/core/persistence/mutation_queue.dart';
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

  final MutationQueue _mutations = MutationQueue();
  bool _alive = true;

  @override
  Future<List<CompletedWorkout>> build() async {
    _alive = true;
    ref.onDispose(() => _alive = false);
    final storage = await _storage();
    return storage.load();
  }

  void _publish(List<CompletedWorkout> value) {
    if (!_alive) return;
    try {
      state = AsyncData(value);
    } on Object {
      // Disposed between the check and the write.
    }
  }

  Future<void> refresh() {
    return _mutations.enqueue(() async {
      if (!_alive) return;
      try {
        state = const AsyncLoading();
      } on Object {
        return;
      }
      try {
        final storage = await _storage();
        _publish(storage.load());
      } catch (e, st) {
        if (!_alive) return;
        try {
          state = AsyncError(e, st);
        } on Object {
          // Disposed.
        }
      }
    });
  }

  /// Add a completed workout, deduplicate by id, newest first, cap 100.
  /// Returns true if saved or already exists.
  ///
  /// Concurrent adds are serialized and then re-read, so neither workout is
  /// lost and controller state matches what was persisted.
  Future<bool> addWorkout(CompletedWorkout workout) {
    return _mutations.enqueue(() async {
      try {
        // Wait until the initial load has published so its return value cannot
        // clobber a newer list written by this add.
        try {
          await future;
        } on Object {
          // Initial load failed. Still attempt the write.
        }
        final storage = await _storage();
        final result = await storage.add(workout);
        if (!result) return false;
        _publish(storage.load());
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  Future<bool> clear() {
    return _mutations.enqueue(() async {
      try {
        final storage = await _storage();
        final result = await storage.clear();
        if (!result) return false;
        _publish(const []);
        return true;
      } catch (_) {
        return false;
      }
    });
  }
}
