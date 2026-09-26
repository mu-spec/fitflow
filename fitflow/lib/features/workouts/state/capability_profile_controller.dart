import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads persisted capability profile on startup and manages save/clear.
///
/// Exposes `AsyncValue<CapabilityProfile?>` where null means no valid profile.
/// Keeps UserFitnessProfile separate (preferences vs dynamic ability).
class CapabilityProfileController extends AsyncNotifier<CapabilityProfile?> {
  @override
  Future<CapabilityProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return CapabilityProfileStorage(prefs).load();
  }

  /// Persists [profile] as the active capability profile.
  ///
  /// Requires complete and valid profile. Returns false if invalid or save fails,
  /// does not write invalid data and does not update state.
  Future<bool> saveProfile(CapabilityProfile profile) async {
    if (!profile.isComplete || !profile.isValid) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await CapabilityProfileStorage(prefs).save(profile);
      if (saved) {
        state = AsyncData(profile);
      }
      return saved;
    } on ArgumentError {
      return false;
    } on Object {
      return false;
    }
  }

  /// Clears persisted capability profile.
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await CapabilityProfileStorage(prefs).clear();
    state = const AsyncData(null);
  }
}

final capabilityProfileProvider = AsyncNotifierProvider<
    CapabilityProfileController, CapabilityProfile?>(
  CapabilityProfileController.new,
);
