import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads persisted capability profile on startup and manages save/clear.
///
/// Exposes `AsyncValue<CapabilityProfile?>` where null means no valid profile.
/// Keeps UserFitnessProfile separate (preferences vs dynamic ability).
///
/// Preferences acquisition goes through the canonical
/// [sharedPreferencesProvider] seam (M21 Part 1).
class CapabilityProfileController extends AsyncNotifier<CapabilityProfile?> {
  @override
  Future<CapabilityProfile?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
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
      final prefs = await ref.read(sharedPreferencesProvider.future);
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

  /// Re-reads the persisted capability profile (used after a backup restore).
  Future<void> reload() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncData(CapabilityProfileStorage(prefs).load());
  }

  /// Clears persisted capability profile.
  Future<void> clearProfile() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await CapabilityProfileStorage(prefs).clear();
    state = const AsyncData(null);
  }
}

final capabilityProfileProvider = AsyncNotifierProvider<
    CapabilityProfileController, CapabilityProfile?>(
  CapabilityProfileController.new,
);
