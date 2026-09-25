import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the persisted profile on app startup and saves a new profile when
/// onboarding completes. `null` means no valid profile exists yet.
class UserFitnessProfileController
    extends AsyncNotifier<UserFitnessProfile?> {
  @override
  Future<UserFitnessProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return UserFitnessProfileStorage(prefs).load();
  }

  /// Persists [profile] as the active profile. Returns whether it succeeded.
  Future<bool> saveProfile(UserFitnessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await UserFitnessProfileStorage(prefs).save(profile);
    if (saved) {
      state = AsyncData(profile);
    }
    return saved;
  }
}

final userFitnessProfileProvider = AsyncNotifierProvider<
    UserFitnessProfileController, UserFitnessProfile?>(
  UserFitnessProfileController.new,
);
