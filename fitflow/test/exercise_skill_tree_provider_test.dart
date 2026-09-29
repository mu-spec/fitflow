import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/features/workouts/state/exercise_skill_tree_provider.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

class _FakeUserProfileController extends UserFitnessProfileController {
  _FakeUserProfileController(this.profile);

  final UserFitnessProfile profile;

  @override
  Future<UserFitnessProfile?> build() async => profile;
}

class _FakeCapabilityController extends CapabilityProfileController {
  _FakeCapabilityController(this.profile);

  final CapabilityProfile profile;

  @override
  Future<CapabilityProfile?> build() async => profile;

  void setProfile(CapabilityProfile next) {
    state = AsyncData(next);
  }
}

void main() {
  test('skill-tree provider updates from persisted/current M10 capability',
      () async {
    final userController = _FakeUserProfileController(skillTreeUserProfile());
    final capabilityController = _FakeCapabilityController(
      skillTreeCapabilityProfile(
        defaultLevel: CapabilityLevel.level1,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        userFitnessProfileProvider.overrideWith(() => userController),
        capabilityProfileProvider.overrideWith(() => capabilityController),
      ],
    );
    addTearDown(container.dispose);

    await container.read(userFitnessProfileProvider.future);
    await container.read(capabilityProfileProvider.future);
    final before = container
        .read(exerciseSkillTreeCatalogProvider)
        .treeForFamilyId('pushup')!;
    expect(before.currentMovementLevel, CapabilityLevel.level1);
    expect(before.fitsCurrentLevelCount, 1);

    final next = skillTreeCapabilityProfile(
      defaultLevel: CapabilityLevel.level1,
      levels: const {MovementPattern.push: CapabilityLevel.level2},
    );
    capabilityController.setProfile(next);
    final after = container
        .read(exerciseSkillTreeCatalogProvider)
        .treeForFamilyId('pushup')!;

    expect(after.currentMovementLevel, CapabilityLevel.level2);
    expect(after.fitsCurrentLevelCount, 3);
    expect(before.fitsCurrentLevelCount, 1);
  });

  test('temporary M12 session modes do not change movement-level skill trees',
      () async {
    final container = ProviderContainer(
      overrides: [
        userFitnessProfileProvider.overrideWith(
          () => _FakeUserProfileController(skillTreeUserProfile()),
        ),
        capabilityProfileProvider.overrideWith(
          () => _FakeCapabilityController(
            skillTreeCapabilityProfile(
              levels: const {MovementPattern.push: CapabilityLevel.level3},
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(userFitnessProfileProvider.future);
    await container.read(capabilityProfileProvider.future);
    final before = container
        .read(exerciseSkillTreeCatalogProvider)
        .treeForFamilyId('pushup')!;

    container
        .read(workoutSessionModeProvider.notifier)
        .selectMode(WorkoutSessionMode.lowEnergy);
    final lowEnergy = container
        .read(exerciseSkillTreeCatalogProvider)
        .treeForFamilyId('pushup')!;
    container
        .read(workoutSessionModeProvider.notifier)
        .selectMode(WorkoutSessionMode.comeback);
    final comeback = container
        .read(exerciseSkillTreeCatalogProvider)
        .treeForFamilyId('pushup')!;

    expect(lowEnergy.currentMovementLevel, CapabilityLevel.level3);
    expect(comeback.currentMovementLevel, CapabilityLevel.level3);
    expect(lowEnergy.fitsCurrentLevelCount, before.fitsCurrentLevelCount);
    expect(comeback.fitsCurrentLevelCount, before.fitsCurrentLevelCount);
  });
}
