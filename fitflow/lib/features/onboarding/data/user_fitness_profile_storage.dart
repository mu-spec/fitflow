import 'dart:convert';

import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the [UserFitnessProfile].
///
/// Stores a single JSON string in SharedPreferences. Enum values are
/// serialized with their stable `name` property, never display labels.
/// Missing or malformed data loads as `null` — it never throws.
class UserFitnessProfileStorage {
  UserFitnessProfileStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String profileKey = 'user_fitness_profile';

  /// Returns the saved profile, or `null` when none is saved or the stored
  /// data is missing/invalid.
  UserFitnessProfile? load() {
    final raw = _prefs.getString(profileKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final equipment = _decodeEquipment(decoded['equipment']);
      // Equipment is required for a valid profile.
      if (equipment.isEmpty) {
        return null;
      }

      return UserFitnessProfile(
        goal: FitnessGoal.values.byName(decoded['goal'] as String),
        experience:
            ExperienceLevel.values.byName(decoded['experience'] as String),
        workoutDuration:
            WorkoutDuration.values.byName(decoded['workoutDuration'] as String),
        environment:
            TrainingEnvironment.values.byName(decoded['environment'] as String),
        equipment: equipment,
        preferences: _decodePreferences(decoded['preferences']),
      );
    } on Object {
      return null;
    }
  }

  /// Persists [profile] as JSON. Returns whether the write succeeded.
  Future<bool> save(UserFitnessProfile profile) async {
    final encoded = jsonEncode({
      'goal': profile.goal.name,
      'experience': profile.experience.name,
      'workoutDuration': profile.workoutDuration.name,
      'environment': profile.environment.name,
      'equipment': [for (final e in profile.equipment) e.name],
      'preferences': [for (final p in profile.preferences) p.name],
    });
    return _prefs.setString(profileKey, encoded);
  }

  /// Removes any stored profile.
  Future<void> clear() async {
    await _prefs.remove(profileKey);
  }

  Set<WorkoutEquipment> _decodeEquipment(Object? raw) {
    if (raw is! List) {
      return const <WorkoutEquipment>{};
    }
    final byName = WorkoutEquipment.values.asNameMap();
    final result = <WorkoutEquipment>{};
    for (final item in raw) {
      final value = item is String ? byName[item] : null;
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }

  Set<WorkoutPreference> _decodePreferences(Object? raw) {
    if (raw is! List) {
      return const <WorkoutPreference>{};
    }
    final byName = WorkoutPreference.values.asNameMap();
    final result = <WorkoutPreference>{};
    for (final item in raw) {
      final value = item is String ? byName[item] : null;
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }
}
