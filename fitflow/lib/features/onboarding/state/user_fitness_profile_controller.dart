import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the persisted profile on app startup and saves a new profile when
/// onboarding completes. `null` means no valid profile exists yet.
///
/// Preferences acquisition goes through the canonical
/// [sharedPreferencesProvider] seam so startup and save paths reuse one
/// acquisition (M21 Part 1).
class UserFitnessProfileController
    extends AsyncNotifier<UserFitnessProfile?> {
  @override
  Future<UserFitnessProfile?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return UserFitnessProfileStorage(prefs).load();
  }

  /// Persists [profile] as the active profile. Returns whether it succeeded.
  Future<bool> saveProfile(UserFitnessProfile profile) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final saved = await UserFitnessProfileStorage(prefs).save(profile);
    if (saved) {
      state = AsyncData(profile);
    }
    return saved;
  }

  /// Re-reads the persisted profile (used after a backup restore).
  Future<void> reload() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncData(UserFitnessProfileStorage(prefs).load());
  }
}

final userFitnessProfileProvider = AsyncNotifierProvider<
    UserFitnessProfileController, UserFitnessProfile?>(
  UserFitnessProfileController.new,
);
