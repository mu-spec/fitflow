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
    _load();
  }

  final CustomWorkoutStorage _storage;

  Future<void> _load() async {
    try {
      final all = await _storage.loadAll();
      state = AsyncValue.data(all);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<bool> create(CustomWorkoutTemplate template) async {
    try {
      final result = await _storage.create(template);
      state = AsyncValue.data(result);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> update(CustomWorkoutTemplate template) async {
    try {
      final result = await _storage.update(template);
      state = AsyncValue.data(result);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final result = await _storage.delete(id);
      state = AsyncValue.data(result);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
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
