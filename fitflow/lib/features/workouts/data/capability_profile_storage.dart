import 'dart:convert';

import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the [CapabilityProfile].
///
/// Stores a single JSON string in SharedPreferences, similar to
/// [UserFitnessProfileStorage]. Enum values are serialized with stable `.name`.
/// Missing or malformed or incomplete data loads as `null` — never throws.
class CapabilityProfileStorage {
  CapabilityProfileStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String profileKey = 'capability_profile';

  /// Returns the saved capability profile, or `null` when none is saved
  /// or the stored data is missing/invalid/incomplete.
  ///
  /// Validity requirements:
  /// - parseable JSON
  /// - JSON object
  /// - CapabilityProfile.fromJson != null
  /// - complete (exactly 10 trainable)
  /// - valid
  CapabilityProfile? load() {
    final raw = _prefs.getString(profileKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final profile = CapabilityProfile.fromJson(decoded);
      if (profile == null) {
        return null;
      }
      if (!profile.isComplete) {
        return null;
      }
      if (!profile.isValid) {
        return null;
      }
      return profile;
    } on Object {
      return null;
    }
  }

  /// Persists [profile] as JSON.
  ///
  /// Requires complete and valid profile, otherwise throws [ArgumentError]
  /// and does not write invalid data (fail safely).
  Future<bool> save(CapabilityProfile profile) async {
    if (!profile.isComplete) {
      throw ArgumentError('CapabilityProfile must be complete (10 trainable) to save');
    }
    if (!profile.isValid) {
      throw ArgumentError('CapabilityProfile must be valid to save');
    }

    final encoded = jsonEncode(profile.toJson());
    return _prefs.setString(profileKey, encoded);
  }

  /// Removes any stored capability profile.
  Future<void> clear() async {
    await _prefs.remove(profileKey);
  }
}
