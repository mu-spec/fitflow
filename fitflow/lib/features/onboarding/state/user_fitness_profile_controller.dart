import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the in-memory [UserFitnessProfile] built when onboarding completes.
///
/// Null until the user taps Get Started. Not persisted yet.
class UserFitnessProfileController extends Notifier<UserFitnessProfile?> {
  @override
  UserFitnessProfile? build() => null;

  /// Stores the profile created at the end of onboarding.
  void setProfile(UserFitnessProfile profile) {
    state = profile;
  }
}

final userFitnessProfileProvider =
    NotifierProvider<UserFitnessProfileController, UserFitnessProfile?>(
  UserFitnessProfileController.new,
);
