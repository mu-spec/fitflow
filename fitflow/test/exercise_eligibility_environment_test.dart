import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTestExercise({
    required String id,
    MovementPattern? movementPattern = MovementPattern.push,
    ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
    SpaceRequirement space = SpaceRequirement.small,
    NoiseLevel noise = NoiseLevel.quiet,
    ImpactLevel impact = ImpactLevel.low,
    ExercisePosition? position = ExercisePosition.standing,
    JointLoad wrist = JointLoad.none,
    JointLoad knee = JointLoad.none,
    Set<WorkoutEquipment> equipment = const {},
    bool active = true,
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
      difficulty: difficulty,
      spaceRequirement: space,
      noiseLevel: noise,
      impactLevel: impact,
      bodyPosition: position,
      wristLoad: wrist,
      kneeLoad: knee,
      requiredEquipment: equipment,
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: const Duration(seconds: 30),
      active: active,
    );
  }

  CapabilityProfile createFullProfile() {
    return CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
  }

  ExerciseEligibilityContext createContext({
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutPreference> preferences = const {},
    Set<WorkoutEquipment> equipment = const {},
  }) {
    return ExerciseEligibilityContext(
      capabilityProfile: createFullProfile(),
      availableEquipment: equipment,
      environment: environment,
      preferences: preferences,
    );
  }

  group('Environment - Apartment', () {
    test('quiet + tiny/small does not get environment reason', () {
      final context = createContext(environment: TrainingEnvironment.apartment);
      final tinyQuiet = createTestExercise(
        id: 'tiny_quiet',
        space: SpaceRequirement.tiny,
        noise: NoiseLevel.quiet,
      );
      final smallQuiet = createTestExercise(
        id: 'small_quiet',
        space: SpaceRequirement.small,
        noise: NoiseLevel.quiet,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(tinyQuiet, context).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(tinyQuiet, context).reasons,
        isNot(contains(ExerciseExclusionReason.tooNoisy)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(smallQuiet, context).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(smallQuiet, context).reasons,
        isNot(contains(ExerciseExclusionReason.tooNoisy)),
      );
    });

    test('moderate/loud gets tooNoisy', () {
      final context = createContext(environment: TrainingEnvironment.apartment);
      final moderate = createTestExercise(
        id: 'moderate_noise',
        noise: NoiseLevel.moderate,
      );
      final loud = createTestExercise(
        id: 'loud_noise',
        noise: NoiseLevel.loud,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(moderate, context).reasons,
        contains(ExerciseExclusionReason.tooNoisy),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(loud, context).reasons,
        contains(ExerciseExclusionReason.tooNoisy),
      );
    });

    test('medium/large gets insufficientSpace', () {
      final context = createContext(environment: TrainingEnvironment.apartment);
      final medium = createTestExercise(
        id: 'medium_space',
        space: SpaceRequirement.medium,
      );
      final large = createTestExercise(
        id: 'large_space',
        space: SpaceRequirement.large,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(medium, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(large, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
    });
  });

  group('Environment - Hotel', () {
    test('same quiet + small maximum behavior as apartment', () {
      final context = createContext(environment: TrainingEnvironment.hotel);
      final smallQuiet = createTestExercise(
        id: 'small_quiet_hotel',
        space: SpaceRequirement.small,
        noise: NoiseLevel.quiet,
      );
      final moderate = createTestExercise(
        id: 'moderate_hotel',
        noise: NoiseLevel.moderate,
      );
      final medium = createTestExercise(
        id: 'medium_hotel',
        space: SpaceRequirement.medium,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(smallQuiet, context).eligible,
        true,
      );
      expect(
        ExerciseEligibilityEngine.evaluate(moderate, context).reasons,
        contains(ExerciseExclusionReason.tooNoisy),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(medium, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
    });
  });

  group('Environment - Small Room', () {
    test('small passes space, medium/large fails', () {
      final context = createContext(environment: TrainingEnvironment.smallRoom);
      final small = createTestExercise(id: 'small', space: SpaceRequirement.small);
      final medium = createTestExercise(id: 'medium', space: SpaceRequirement.medium);
      final large = createTestExercise(id: 'large', space: SpaceRequirement.large);

      expect(
        ExerciseEligibilityEngine.evaluate(small, context).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(medium, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(large, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
    });

    test('do not reject solely for moderate noise', () {
      final context = createContext(environment: TrainingEnvironment.smallRoom);
      final moderateNoise = createTestExercise(
        id: 'moderate_noise_small',
        noise: NoiseLevel.moderate,
        space: SpaceRequirement.small,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(moderateNoise, context).reasons,
        isNot(contains(ExerciseExclusionReason.tooNoisy)),
      );
    });
  });

  group('Environment - Normal Home', () {
    test('medium passes, large fails space', () {
      final context = createContext(environment: TrainingEnvironment.normalHome);
      final medium = createTestExercise(id: 'medium_home', space: SpaceRequirement.medium);
      final large = createTestExercise(id: 'large_home', space: SpaceRequirement.large);
      final small = createTestExercise(id: 'small_home', space: SpaceRequirement.small);

      expect(
        ExerciseEligibilityEngine.evaluate(small, context).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(medium, context).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(large, context).reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
    });
  });

  group('Environment - Large Room / Outdoor', () {
    test('large passes space', () {
      final largeRoomContext = createContext(environment: TrainingEnvironment.largeRoom);
      final outdoorContext = createContext(environment: TrainingEnvironment.outdoor);
      final large = createTestExercise(id: 'large', space: SpaceRequirement.large);

      expect(
        ExerciseEligibilityEngine.evaluate(large, largeRoomContext).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(large, outdoorContext).reasons,
        isNot(contains(ExerciseExclusionReason.insufficientSpace)),
      );
    });

    test('loud is not rejected purely by environment', () {
      final largeRoomContext = createContext(environment: TrainingEnvironment.largeRoom);
      final outdoorContext = createContext(environment: TrainingEnvironment.outdoor);
      final loud = createTestExercise(
        id: 'loud',
        noise: NoiseLevel.loud,
        space: SpaceRequirement.small,
      );

      expect(
        ExerciseEligibilityEngine.evaluate(loud, largeRoomContext).reasons,
        isNot(contains(ExerciseExclusionReason.tooNoisy)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(loud, outdoorContext).reasons,
        isNot(contains(ExerciseExclusionReason.tooNoisy)),
      );
    });
  });

  group('Low Impact', () {
    test('with lowImpact: low passes, moderate/high gets lowImpactRequired', () {
      final context = createContext(preferences: {WorkoutPreference.lowImpact});
      final low = createTestExercise(id: 'low', impact: ImpactLevel.low);
      final moderate = createTestExercise(id: 'moderate', impact: ImpactLevel.moderate);
      final high = createTestExercise(id: 'high', impact: ImpactLevel.high);

      expect(
        ExerciseEligibilityEngine.evaluate(low, context).reasons,
        isNot(contains(ExerciseExclusionReason.lowImpactRequired)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(moderate, context).reasons,
        contains(ExerciseExclusionReason.lowImpactRequired),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(high, context).reasons,
        contains(ExerciseExclusionReason.lowImpactRequired),
      );
    });

    test('without lowImpact preference, moderate/high passes', () {
      final context = createContext();
      final moderate = createTestExercise(id: 'moderate', impact: ImpactLevel.moderate);
      expect(
        ExerciseEligibilityEngine.evaluate(moderate, context).reasons,
        isNot(contains(ExerciseExclusionReason.lowImpactRequired)),
      );
    });
  });

  group('No Floor', () {
    test('with noFloorExercises: floor, kneeling get floorRestricted', () {
      final context = createContext(preferences: {WorkoutPreference.noFloorExercises});
      final floorEx = createTestExercise(id: 'floor', position: ExercisePosition.floor);
      final kneelingEx = createTestExercise(id: 'kneeling', position: ExercisePosition.kneeling);
      final standingEx = createTestExercise(id: 'standing', position: ExercisePosition.standing);

      // Use real exercises as well
      final pushUpStandard = ExerciseCatalog.byId('pushup_standard')!;
      final forearmPlank = ExerciseCatalog.byId('plank_forearm')!;

      expect(
        ExerciseEligibilityEngine.evaluate(floorEx, context).reasons,
        contains(ExerciseExclusionReason.floorRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(kneelingEx, context).reasons,
        contains(ExerciseExclusionReason.floorRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(standingEx, context).reasons,
        isNot(contains(ExerciseExclusionReason.floorRestricted)),
      );

      expect(
        ExerciseEligibilityEngine.evaluate(pushUpStandard, context).reasons,
        contains(ExerciseExclusionReason.floorRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(forearmPlank, context).reasons,
        contains(ExerciseExclusionReason.floorRestricted),
      );
    });
  });

  group('Standing Only', () {
    test('with standingOnly: only standing passes', () {
      final context = createContext(preferences: {WorkoutPreference.standingOnly});
      final standing = createTestExercise(id: 'standing', position: ExercisePosition.standing);
      final floor = createTestExercise(id: 'floor', position: ExercisePosition.floor);
      final seated = createTestExercise(id: 'seated', position: ExercisePosition.seated);
      final kneeling = createTestExercise(id: 'kneeling', position: ExercisePosition.kneeling);
      final hanging = createTestExercise(id: 'hanging', position: ExercisePosition.hanging);

      expect(
        ExerciseEligibilityEngine.evaluate(standing, context).reasons,
        isNot(contains(ExerciseExclusionReason.standingOnlyRequired)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(floor, context).reasons,
        contains(ExerciseExclusionReason.standingOnlyRequired),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(seated, context).reasons,
        contains(ExerciseExclusionReason.standingOnlyRequired),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(kneeling, context).reasons,
        contains(ExerciseExclusionReason.standingOnlyRequired),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(hanging, context).reasons,
        contains(ExerciseExclusionReason.standingOnlyRequired),
      );
    });

    test('both noFloor and standingOnly may produce both reasons', () {
      final context = createContext(preferences: {
        WorkoutPreference.noFloorExercises,
        WorkoutPreference.standingOnly,
      });
      final floor = createTestExercise(id: 'floor', position: ExercisePosition.floor);

      final result = ExerciseEligibilityEngine.evaluate(floor, context);
      // Floor should be rejected by both rules
      expect(result.reasons, contains(ExerciseExclusionReason.floorRestricted));
      expect(result.reasons, contains(ExerciseExclusionReason.standingOnlyRequired));
    });
  });

  group('Wrist', () {
    test('with avoidWristHeavy: high wrist load gets wristLoadRestricted', () {
      final context = createContext(preferences: {WorkoutPreference.avoidWristHeavy});
      final highWrist = createTestExercise(id: 'high_wrist', wrist: JointLoad.high);
      final lowWrist = createTestExercise(id: 'low_wrist', wrist: JointLoad.low);
      final noneWrist = createTestExercise(id: 'none_wrist', wrist: JointLoad.none);
      final moderateWrist = createTestExercise(id: 'moderate_wrist', wrist: JointLoad.moderate);

      // Real exercise
      final pushUpStandard = ExerciseCatalog.byId('pushup_standard')!;

      expect(
        ExerciseEligibilityEngine.evaluate(highWrist, context).reasons,
        contains(ExerciseExclusionReason.wristLoadRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(pushUpStandard, context).reasons,
        contains(ExerciseExclusionReason.wristLoadRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(lowWrist, context).reasons,
        isNot(contains(ExerciseExclusionReason.wristLoadRestricted)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(noneWrist, context).reasons,
        isNot(contains(ExerciseExclusionReason.wristLoadRestricted)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(moderateWrist, context).reasons,
        isNot(contains(ExerciseExclusionReason.wristLoadRestricted)),
      );
    });
  });

  group('Knee', () {
    test('with avoidDeepKneeBending: high knee load gets kneeLoadRestricted', () {
      final context = createContext(preferences: {
        WorkoutPreference.avoidDeepKneeBending,
      });
      final highKnee = createTestExercise(id: 'high_knee', knee: JointLoad.high);
      final lowKnee = createTestExercise(id: 'low_knee', knee: JointLoad.low);
      final moderateKnee = createTestExercise(id: 'moderate_knee', knee: JointLoad.moderate);

      final bulgarian = ExerciseCatalog.byId('squat_split_bulgarian')!;

      expect(
        ExerciseEligibilityEngine.evaluate(highKnee, context).reasons,
        contains(ExerciseExclusionReason.kneeLoadRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(bulgarian, context).reasons,
        contains(ExerciseExclusionReason.kneeLoadRestricted),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(lowKnee, context).reasons,
        isNot(contains(ExerciseExclusionReason.kneeLoadRestricted)),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(moderateKnee, context).reasons,
        isNot(contains(ExerciseExclusionReason.kneeLoadRestricted)),
      );
    });
  });

  group('Multiple reasons extended', () {
    test('one exercise can accumulate old + new reasons', () {
      final context = ExerciseEligibilityContext(
        capabilityProfile: CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1)),
        availableEquipment: {}, // missing chair
        environment: TrainingEnvironment.apartment, // small max, quiet max
        preferences: {
          WorkoutPreference.lowImpact,
          WorkoutPreference.avoidWristHeavy,
        },
      );

      final exercise = createTestExercise(
        id: 'multi_reason_extended',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level5, // above L1
        equipment: {WorkoutEquipment.chair}, // missing
        space: SpaceRequirement.large, // insufficient for apartment
        noise: NoiseLevel.loud, // too noisy for apartment
        impact: ImpactLevel.high, // lowImpactRequired
        wrist: JointLoad.high, // wristLoadRestricted
        active: true,
      );

      final result = ExerciseEligibilityEngine.evaluate(exercise, context);
      expect(result.reasons, contains(ExerciseExclusionReason.aboveCapability));
      expect(result.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(result.reasons, contains(ExerciseExclusionReason.insufficientSpace));
      expect(result.reasons, contains(ExerciseExclusionReason.tooNoisy));
      expect(result.reasons, contains(ExerciseExclusionReason.lowImpactRequired));
      expect(result.reasons, contains(ExerciseExclusionReason.wristLoadRestricted));
      expect(result.eligible, false);
    });
  });

  group('Context immutability extended', () {
    test('preferences cannot be externally mutated', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final mutablePrefs = {WorkoutPreference.lowImpact};
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
        preferences: mutablePrefs,
      );

      mutablePrefs.add(WorkoutPreference.noFloorExercises);
      expect(context.preferences, isNot(contains(WorkoutPreference.noFloorExercises)));

      expect(() => context.preferences.add(WorkoutPreference.standingOnly),
          throwsUnsupportedError);
    });

    test('modifying original source Set after construction does not change context', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final mutableEquipment = {WorkoutEquipment.chair};
      final mutablePrefs = {WorkoutPreference.lowImpact};
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: mutableEquipment,
        environment: TrainingEnvironment.apartment,
        preferences: mutablePrefs,
      );

      mutableEquipment.add(WorkoutEquipment.towel);
      mutablePrefs.add(WorkoutPreference.avoidWristHeavy);

      expect(context.availableEquipment, isNot(contains(WorkoutEquipment.towel)));
      expect(context.preferences, isNot(contains(WorkoutPreference.avoidWristHeavy)));
    });
  });

  group('Capability comparison fix', () {
    test('comparison does not rely on enum index, uses explicit mapping', () {
      // This test ensures that even if enums were reordered, mapping still works
      // We verify that Level1 capability only allows Level1 exercise, not Level2
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
      );

      final level1Ex = createTestExercise(
        id: 'l1',
        difficulty: ExerciseDifficulty.level1,
      );
      final level2Ex = createTestExercise(
        id: 'l2',
        difficulty: ExerciseDifficulty.level2,
      );

      expect(ExerciseEligibilityEngine.evaluate(level1Ex, context).eligible, true);
      expect(
        ExerciseEligibilityEngine.evaluate(level2Ex, context).reasons,
        contains(ExerciseExclusionReason.aboveCapability),
      );
    });
  });
}
