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
/// - Write failure handling: setString bool checked, null means failure
class CustomWorkoutStorage {
  const CustomWorkoutStorage({
    Future<SharedPreferences> Function()? getPrefs,
    Future<bool> Function(SharedPreferences prefs, String key, String value)? writeString,
  })  : _getPrefs = getPrefs,
        _writeString = writeString;

  static const String key = 'custom_workouts_v1';

  final Future<SharedPreferences> Function()? _getPrefs;
  final Future<bool> Function(SharedPreferences prefs, String key, String value)? _writeString;

  Future<SharedPreferences> _prefs() {
    if (_getPrefs != null) {
      return _getPrefs!();
    }
    return SharedPreferences.getInstance();
  }

  Future<bool> _write(SharedPreferences prefs, String k, String v) {
    if (_writeString != null) {
      return _writeString!(prefs, k, v);
    }
    return prefs.setString(k, v);
  }

  Future<List<CustomWorkoutTemplate>> loadAll() async {
    try {
      final prefs = await _prefs();
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

  /// Returns persisted list on success, null on write failure.
  Future<List<CustomWorkoutTemplate>?> saveAll(List<CustomWorkoutTemplate> templates) async {
    try {
      // Deduplicate by id, keep most recently updated per id.
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

      final prefs = await _prefs();
      final success = await _write(prefs, key, encoded);
      if (!success) {
        return null;
      }

      return List.unmodifiable(deduped);
    } catch (_) {
      return null;
    }
  }

  Future<CustomWorkoutTemplate?> findById(String id) async {
    final all = await loadAll();
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<List<CustomWorkoutTemplate>?> create(CustomWorkoutTemplate template) async {
    try {
      final all = await loadAll();
      final mutable = List<CustomWorkoutTemplate>.from(all);
      mutable.removeWhere((t) => t.id == template.id);
      mutable.add(template);
      return await saveAll(mutable);
    } catch (_) {
      return null;
    }
  }

  Future<List<CustomWorkoutTemplate>?> update(CustomWorkoutTemplate template) async {
    try {
      final all = await loadAll();
      final mutable = List<CustomWorkoutTemplate>.from(all);
      final idx = mutable.indexWhere((t) => t.id == template.id);
      if (idx == -1) {
        mutable.add(template);
      } else {
        mutable[idx] = template;
      }
      return await saveAll(mutable);
    } catch (_) {
      return null;
    }
  }

  Future<List<CustomWorkoutTemplate>?> delete(String id) async {
    try {
      final all = await loadAll();
      final mutable = all.where((t) => t.id != id).toList();
      return await saveAll(mutable);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearForTest() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(key);
    } catch (_) {}
  }
}
