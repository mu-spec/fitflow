import 'dart:convert';

import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local SharedPreferences storage for completed workouts, versioned key, bounded to 100.
class WorkoutHistoryStorage {
  WorkoutHistoryStorage(this._prefs);

  final SharedPreferences _prefs;

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
  Future<bool> add(CompletedWorkout workout) async {
    try {
      final existing = load();
      // If session ID exists → success/no-op
      if (existing.any((e) => e.id == workout.id)) {
        return true;
      }

      final newList = <CompletedWorkout>[workout, ...existing];
      // Trim to max 100, drop oldest
      final trimmed = newList.length > maxEntries ? newList.take(maxEntries).toList() : newList;

      final jsonList = trimmed.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      final result = await _prefs.setString(key, encoded);
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Replace entire history (used for testing or clear).
  Future<bool> saveAll(List<CompletedWorkout> workouts) async {
    try {
      // Deduplicate and sort newest first, trim
      final seen = <String>{};
      final deduped = <CompletedWorkout>[];
      for (final cw in workouts) {
        if (seen.contains(cw.id)) continue;
        seen.add(cw.id);
        deduped.add(cw);
      }
      deduped.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      final trimmed = deduped.length > maxEntries ? deduped.take(maxEntries).toList() : deduped;
      final jsonList = trimmed.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      return await _prefs.setString(key, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await _prefs.remove(key);
    } catch (_) {
      return false;
    }
  }
}
