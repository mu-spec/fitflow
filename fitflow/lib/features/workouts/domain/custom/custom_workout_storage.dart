import 'dart:convert';

import 'package:fitflow/features/workouts/domain/custom/custom_workout_limits.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline storage for custom workout templates.
///
/// Key: custom_workouts_v1
/// - Safe parsing: malformed root -> empty, malformed entry -> skip
/// - Immutable results
/// - Max 50 retain most recently updated
class CustomWorkoutStorage {
  const CustomWorkoutStorage();

  static const String key = 'custom_workouts_v1';

  Future<List<CustomWorkoutTemplate>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        // malformed root -> empty
        return const [];
      }

      final templates = <CustomWorkoutTemplate>[];
      final seenIds = <String>{};

      for (final item in decoded) {
        try {
          if (item is! Map<String, dynamic>) {
            if (item is Map) {
              final mapped = Map<String, dynamic>.from(item);
              final t = CustomWorkoutTemplate.fromJson(mapped);
              if (t != null && seenIds.add(t.id)) {
                templates.add(t);
              }
            }
            continue;
          }
          final t = CustomWorkoutTemplate.fromJson(item);
          if (t != null && seenIds.add(t.id)) {
            templates.add(t);
          }
        } catch (_) {
          // skip malformed entry
          continue;
        }
      }

      // Sort newest/updated-first (most recently updated first)
      templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Immutable result
      return List.unmodifiable(templates);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CustomWorkoutTemplate>> saveAll(List<CustomWorkoutTemplate> templates) async {
    // Deduplicate by id, keep last occurrence? But we want deterministic most recent updated retained.
    // First deduplicate: keep most recently updated per id.
    final map = <String, CustomWorkoutTemplate>{};
    for (final t in templates) {
      final existing = map[t.id];
      if (existing == null || t.updatedAt.isAfter(existing.updatedAt)) {
        map[t.id] = t;
      }
    }
    var deduped = map.values.toList();
    // Sort by updatedAt descending
    deduped.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    // Retain max 50 most recently updated
    if (deduped.length > CustomWorkoutLimits.maxTemplates) {
      deduped = deduped.sublist(0, CustomWorkoutLimits.maxTemplates);
    }

    final jsonList = deduped.map((e) => e.toJson()).toList();
    final encoded = jsonEncode(jsonList);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encoded);

    return List.unmodifiable(deduped);
  }

  Future<CustomWorkoutTemplate?> findById(String id) async {
    final all = await loadAll();
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<List<CustomWorkoutTemplate>> create(CustomWorkoutTemplate template) async {
    final all = await loadAll();
    final mutable = List<CustomWorkoutTemplate>.from(all);
    // Ensure no duplicate id – if duplicate, replace
    mutable.removeWhere((t) => t.id == template.id);
    mutable.add(template);
    return saveAll(mutable);
  }

  Future<List<CustomWorkoutTemplate>> update(CustomWorkoutTemplate template) async {
    final all = await loadAll();
    final mutable = List<CustomWorkoutTemplate>.from(all);
    final idx = mutable.indexWhere((t) => t.id == template.id);
    if (idx == -1) {
      // If not found, treat as create
      mutable.add(template);
    } else {
      mutable[idx] = template;
    }
    return saveAll(mutable);
  }

  Future<List<CustomWorkoutTemplate>> delete(String id) async {
    final all = await loadAll();
    final mutable = all.where((t) => t.id != id).toList();
    return saveAll(mutable);
  }

  Future<void> clearForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
