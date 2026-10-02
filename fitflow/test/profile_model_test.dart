import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserFitnessProfile base() => UserFitnessProfile(
        goal: FitnessGoal.buildStrength,
        experience: ExperienceLevel.someExperience,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: const {WorkoutEquipment.chair, WorkoutEquipment.dumbbells},
        preferences: const {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
        },
      );

  group('UserFitnessProfile.copyWith', () {
    test('changes only the requested field (goal)', () {
      final updated = base().copyWith(goal: FitnessGoal.improveMobility);

      expect(updated.goal, FitnessGoal.improveMobility);
    });

    test('changes only the requested field (experience)', () {
      final updated = base().copyWith(experience: ExperienceLevel.experienced);

      expect(updated.experience, ExperienceLevel.experienced);
    });

    test('changes only the requested field (workout duration)', () {
      final updated = base().copyWith(workoutDuration: WorkoutDuration.fiveMinutes);

      expect(updated.workoutDuration, WorkoutDuration.fiveMinutes);
    });

    test('changes only the requested field (environment)', () {
      final updated = base().copyWith(environment: TrainingEnvironment.outdoor);

      expect(updated.environment, TrainingEnvironment.outdoor);
    });

    test('changes only the requested field (equipment)', () {
      final updated = base().copyWith(
        equipment: const {WorkoutEquipment.resistanceBands},
      );

      expect(updated.equipment, {WorkoutEquipment.resistanceBands});
    });

    test('changes only the requested field (preferences)', () {
      final updated = base().copyWith(
        preferences: const {WorkoutPreference.standingOnly},
      );

      expect(updated.preferences, {WorkoutPreference.standingOnly});
    });

    test('preserves every untouched field', () {
      final original = base();
      final updated = original.copyWith(goal: FitnessGoal.stayActive);

      expect(updated.experience, original.experience);
      expect(updated.workoutDuration, original.workoutDuration);
      expect(updated.environment, original.environment);
      expect(updated.equipment, original.equipment);
      expect(updated.preferences, original.preferences);
    });

    test('returns an equal profile when nothing is requested', () {
      expect(base().copyWith(), base());
    });
  });

  group('Defensive immutability', () {
    test('mutating the equipment input set does not mutate the profile', () {
      final equipment = <WorkoutEquipment>{WorkoutEquipment.chair};
      final preferences = <WorkoutPreference>{WorkoutPreference.noJumping};
      final profile = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.tenMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: equipment,
        preferences: preferences,
      );

      equipment.add(WorkoutEquipment.bench);
      preferences.add(WorkoutPreference.standingOnly);

      expect(profile.equipment, {WorkoutEquipment.chair});
      expect(profile.preferences, {WorkoutPreference.noJumping});
    });

    test('the stored equipment set is unmodifiable', () {
      final profile = base();

      expect(
        () => profile.equipment.add(WorkoutEquipment.bench),
        throwsUnsupportedError,
      );
      expect(
        () => profile.equipment.remove(WorkoutEquipment.chair),
        throwsUnsupportedError,
      );
    });

    test('the stored preferences set is unmodifiable', () {
      final profile = base();

      expect(
        () => profile.preferences.add(WorkoutPreference.standingOnly),
        throwsUnsupportedError,
      );
      expect(
        () => profile.preferences.remove(WorkoutPreference.noJumping),
        throwsUnsupportedError,
      );
    });

    test('copyWith equipment input is defensively copied too', () {
      final equipment = <WorkoutEquipment>{WorkoutEquipment.kettlebell};
      final updated = base().copyWith(equipment: equipment);

      equipment.add(WorkoutEquipment.towel);

      expect(updated.equipment, {WorkoutEquipment.kettlebell});
    });
  });

  group('Equality and hashCode', () {
    test('identical field values are equal', () {
      expect(base(), base());
      expect(base().hashCode, base().hashCode);
    });

    test('set contents compare by value, not identity', () {
      final a = base();
      final b = UserFitnessProfile(
        goal: FitnessGoal.buildStrength,
        experience: ExperienceLevel.someExperience,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: const {WorkoutEquipment.dumbbells, WorkoutEquipment.chair},
        preferences: const {
          WorkoutPreference.lowImpact,
          WorkoutPreference.noJumping,
        },
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing fields are not equal', () {
      expect(base() == base().copyWith(goal: FitnessGoal.loseWeight), isFalse);
      expect(
        base() == base().copyWith(experience: ExperienceLevel.experienced),
        isFalse,
      );
      expect(
        base() ==
            base().copyWith(workoutDuration: WorkoutDuration.fortyFiveMinutes),
        isFalse,
      );
      expect(
        base() == base().copyWith(environment: TrainingEnvironment.hotel),
        isFalse,
      );
      expect(
        base() ==
            base().copyWith(equipment: const {WorkoutEquipment.exerciseMat}),
        isFalse,
      );
      expect(
        base() == base().copyWith(preferences: const {}),
        isFalse,
      );
    });
  });

  group('Storage format stability (M18 compatibility)', () {
    test('encode produces the exact historical JSON shape', () {
      final profile = UserFitnessProfile(
        goal: FitnessGoal.buildStrength,
        experience: ExperienceLevel.someExperience,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: const {WorkoutEquipment.dumbbells, WorkoutEquipment.exerciseMat},
        preferences: const {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
        },
      );

      // Same keys, same key order, same enum `name` serialization the app
      // has used since the profile was first persisted. No schema bump.
      expect(
        UserFitnessProfileStorage.encode(profile),
        '{"goal":"buildStrength","experience":"someExperience",'
        '"workoutDuration":"twentyMinutes","environment":"normalHome",'
        '"equipment":["dumbbells","exerciseMat"],'
        '"preferences":["noJumping","lowImpact"]}',
      );
    });

    test('a previously persisted profile still loads unchanged', () async {
      const legacyJson =
          '{"goal":"loseWeight","experience":"regularTraining",'
          '"workoutDuration":"thirtyMinutes","environment":"outdoor",'
          '"equipment":["exerciseMat","resistanceBands","kettlebell"],'
          '"preferences":["lowImpact","noFloorExercises"]}';
      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey: legacyJson,
      });
      final prefs = await SharedPreferences.getInstance();

      final loaded = UserFitnessProfileStorage(prefs).load();

      expect(loaded, isNotNull);
      expect(loaded!.goal, FitnessGoal.loseWeight);
      expect(loaded.experience, ExperienceLevel.regularTraining);
      expect(loaded.workoutDuration, WorkoutDuration.thirtyMinutes);
      expect(loaded.environment, TrainingEnvironment.outdoor);
      expect(
        loaded.equipment,
        {
          WorkoutEquipment.exerciseMat,
          WorkoutEquipment.resistanceBands,
          WorkoutEquipment.kettlebell,
        },
      );
      expect(
        loaded.preferences,
        {WorkoutPreference.lowImpact, WorkoutPreference.noFloorExercises},
      );
    });

    test('save/load round-trip keeps the exact stored bytes stable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = UserFitnessProfileStorage(prefs);
      final profile = base();

      expect(await storage.save(profile), isTrue);
      final stored =
          prefs.getString(UserFitnessProfileStorage.profileKey)!;
      expect(stored, UserFitnessProfileStorage.encode(profile));

      final restored = storage.load();
      expect(restored, profile);
    });
  });
}
