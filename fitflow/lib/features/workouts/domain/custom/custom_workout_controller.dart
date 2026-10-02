import 'package:fitflow/core/persistence/mutation_queue.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customWorkoutStorageProvider = Provider<CustomWorkoutStorage>((ref) {
  return const CustomWorkoutStorage();
});

final customWorkoutControllerProvider =
    StateNotifierProvider<CustomWorkoutController, AsyncValue<List<CustomWorkoutTemplate>>>((ref) {
  final storage = ref.watch(customWorkoutStorageProvider);
  return CustomWorkoutController(storage);
});

class CustomWorkoutController extends StateNotifier<AsyncValue<List<CustomWorkoutTemplate>>> {
  CustomWorkoutController(this._storage) : super(const AsyncValue.loading()) {
    _loaded = _load();
  }

  final CustomWorkoutStorage _storage;
  final MutationQueue _mutations = MutationQueue();
  late final Future<void> _loaded;

  Future<void> _load() async {
    try {
      final all = await _storage.loadAll();
      if (!mounted) return;
      state = AsyncValue.data(all);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() {
    return _mutations.enqueue(() async {
      await _loaded;
      if (mounted) state = const AsyncValue.loading();
      await _load();
    });
  }

  /// Serializes [action] so each mutation reads the latest persisted list.
  /// A thrown action returns false and does not block the next one.
  Future<bool> _enqueue(Future<bool> Function() action) {
    return _mutations.enqueue(() async {
      try {
        await _loaded;
        return await action();
      } catch (_) {
        return false;
      }
    });
  }

  void _publish(List<CustomWorkoutTemplate> templates) {
    if (!mounted) return;
    state = AsyncValue.data(templates);
  }

  Future<bool> create(CustomWorkoutTemplate template) {
    return _enqueue(() async {
      final result = await _storage.create(template);
      if (result == null) return false;
      _publish(result);
      return true;
    });
  }

  Future<bool> update(CustomWorkoutTemplate template) {
    return _enqueue(() async {
      final result = await _storage.update(template);
      if (result == null) return false;
      _publish(result);
      return true;
    });
  }

  Future<bool> delete(String id) {
    return _enqueue(() async {
      final result = await _storage.delete(id);
      if (result == null) return false;
      _publish(result);
      return true;
    });
  }

  CustomWorkoutTemplate? findByIdSync(String id) {
    final current = state;
    if (current is AsyncData<List<CustomWorkoutTemplate>>) {
      for (final t in current.value) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  Future<CustomWorkoutTemplate?> findById(String id) async {
    final sync = findByIdSync(id);
    if (sync != null) return sync;
    return await _storage.findById(id);
  }
}

// Helper for stable ID generation: custom_<timestamp>_<counter>
class CustomWorkoutIdGenerator {
  CustomWorkoutIdGenerator._();
  static int _counter = 0;

  static String generate() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final c = _counter++;
    return 'custom_${ts}_$c';
  }

  static void resetForTest() {
    _counter = 0;
  }
}
