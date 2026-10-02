import 'dart:convert';

import 'package:fitflow/core/persistence/mutation_queue.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SharedPreferences storage for completed workouts, versioned key, bounded to 100.
class WorkoutHistoryStorage {
  WorkoutHistoryStorage(
    this._prefs, {
    Future<bool> Function(String key, String value)? writeString,
    Future<bool> Function(String key)? remove,
  })  : _writeString = writeString,
        _remove = remove;

  final SharedPreferences _prefs;
  final Future<bool> Function(String key, String value)? _writeString;
  final Future<bool> Function(String key)? _remove;

  /// Serializes read-modify-write so concurrent adds cannot drop a workout.
  final MutationQueue _writes = MutationQueue();

  static const String key = 'workout_history_v1';
  static const int maxEntries = 100;

  /// Load history, newest first, safe parsing, deduplicate by session ID.
  List<CompletedWorkout> load() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final List<CompletedWorkout> parsed = [];
      for (final entry in decoded) {
        try {
          if (entry is Map<String, dynamic>) {
            final cw = CompletedWorkout.fromJson(entry);
            if (cw != null) parsed.add(cw);
          } else if (entry is Map) {
            final cw = CompletedWorkout.fromJson(Map<String, dynamic>.from(entry));
            if (cw != null) parsed.add(cw);
          }
        } catch (_) {
          // Ignore malformed individual entry safely
          continue;
        }
      }

      // Deduplicate by id, keep first occurrence (newest first preserved)
      final seen = <String>{};
      final deduped = <CompletedWorkout>[];
      for (final cw in parsed) {
        if (seen.contains(cw.id)) continue;
        seen.add(cw.id);
        deduped.add(cw);
      }

      // Ensure newest first by completedAt descending
      deduped.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      // Trim to max (should already be trimmed on save, but defensive)
      if (deduped.length > maxEntries) {
        return List.unmodifiable(deduped.take(maxEntries).toList());
      }

      return List.unmodifiable(deduped);
    } catch (_) {
      // Malformed root safe
      return const [];
    }
  }

  /// Save a single completed workout, deduplicate by id, newest first, cap 100.
  /// Returns true if saved or already exists, false on failure.
  Future<bool> add(CompletedWorkout workout) {
    return _writes.enqueue(() => _addNow(workout));
  }

  Future<bool> _addNow(CompletedWorkout workout) async {
    try {
      final existing = load();
      // If session ID exists → success/no-op
      if (existing.any((e) => e.id == workout.id)) {
        return true;
      }

      final newList = <CompletedWorkout>[workout, ...existing];
      // Trim to max 100, drop oldest
      final trimmed = newList.length > maxEntries ? newList.take(maxEntries).toList() : newList;

      final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
      return await _setString(key, encoded);
    } catch (_) {
      return false;
    }
  }

  /// Replace entire history (used for testing or clear).
  Future<bool> saveAll(List<CompletedWorkout> workouts) {
    return _writes.enqueue(() => _saveAllNow(workouts));
  }

  Future<bool> _saveAllNow(List<CompletedWorkout> workouts) async {
    try {
      return await _setString(key, encode(workouts));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _setString(String storageKey, String value) {
    final write = _writeString;
    if (write != null) return write(storageKey, value);
    return _prefs.setString(storageKey, value);
  }

  /// The exact stored representation of [workouts]: de-duplicated by id,
  /// newest first, trimmed to [maxEntries] (shared with M18 restore).
  static String encode(List<CompletedWorkout> workouts) {
    final seen = <String>{};
    final deduped = <CompletedWorkout>[];
    for (final cw in workouts) {
      if (seen.contains(cw.id)) continue;
      seen.add(cw.id);
      deduped.add(cw);
    }
    deduped.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final trimmed =
        deduped.length > maxEntries ? deduped.take(maxEntries).toList() : deduped;
    return jsonEncode(trimmed.map((e) => e.toJson()).toList());
  }

  Future<bool> clear() {
    return _writes.enqueue(() async {
      try {
        final remove = _remove;
        if (remove != null) return await remove(key);
        return await _prefs.remove(key);
      } catch (_) {
        return false;
      }
    });
  }
}
