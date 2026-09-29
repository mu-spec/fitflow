import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';

final skillTreeTestDate = DateTime.utc(2026, 9, 29);

UserFitnessProfile skillTreeUserProfile({
  TrainingEnvironment environment = TrainingEnvironment.normalHome,
  Set<WorkoutEquipment> equipment = const <WorkoutEquipment>{},
  Set<WorkoutPreference> preferences = const <WorkoutPreference>{},
}) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.completelyNew,
    workoutDuration: WorkoutDuration.fifteenMinutes,
    environment: environment,
    equipment: equipment,
    preferences: preferences,
  );
}

CapabilityProfile skillTreeCapabilityProfile({
  Map<MovementPattern, CapabilityLevel> levels = const {},
  bool includeAllPatterns = true,
  CapabilityLevel defaultLevel = CapabilityLevel.level3,
}) {
  final capabilities = <MovementPattern, MovementCapability>{};
  if (includeAllPatterns) {
    for (final pattern in CapabilityProfile.trainablePatterns) {
      capabilities[pattern] = MovementCapability(
        movementPattern: pattern,
        level: defaultLevel,
        source: CapabilitySource.initialAssessment,
        updatedAt: skillTreeTestDate,
      );
    }
  }
  for (final entry in levels.entries) {
    capabilities[entry.key] = MovementCapability(
      movementPattern: entry.key,
      level: entry.value,
      source: CapabilitySource.initialAssessment,
      updatedAt: skillTreeTestDate,
    );
  }
  return CapabilityProfile.fromMap(capabilities);
}

Exercise skillTreeExercise({
  required String id,
  String? name,
  String? familyId = 'sample_family',
  int rank = 1,
  ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
  MovementPattern? movementPattern = MovementPattern.push,
  bool active = true,
  String? easierId,
  String? harderId,
  Set<WorkoutEquipment> equipment = const <WorkoutEquipment>{
    WorkoutEquipment.none,
  },
  SpaceRequirement space = SpaceRequirement.small,
  NoiseLevel noise = NoiseLevel.quiet,
  ImpactLevel impact = ImpactLevel.low,
  ExercisePosition? position = ExercisePosition.standing,
  JointLoad wristLoad = JointLoad.low,
  JointLoad kneeLoad = JointLoad.low,
  ExerciseType exerciseType = ExerciseType.reps,
  int? defaultReps = 8,
  Duration? defaultDuration = const Duration(seconds: 30),
  Set<String> tags = const <String>{},
}) {
  return Exercise(
    id: id,
    name: name ?? id,
    progressionFamilyId: familyId,
    progressionRank: rank,
    difficulty: difficulty,
    movementPattern: movementPattern,
    active: active,
    easierVariationId: easierId,
    harderVariationId: harderId,
    requiredEquipment: equipment,
    spaceRequirement: space,
    noiseLevel: noise,
    impactLevel: impact,
    bodyPosition: position,
    wristLoad: wristLoad,
    kneeLoad: kneeLoad,
    exerciseType: exerciseType,
    defaultReps: exerciseType == ExerciseType.reps ? defaultReps : null,
    defaultDuration:
        exerciseType == ExerciseType.timed ? defaultDuration : null,
    defaultRest: const Duration(seconds: 30),
    tags: tags,
  );
}

List<Exercise> skillTreeLadder({
  String familyId = 'sample_family',
  ExerciseDifficulty firstDifficulty = ExerciseDifficulty.level1,
  ExerciseDifficulty secondDifficulty = ExerciseDifficulty.level2,
  MovementPattern pattern = MovementPattern.push,
  Set<WorkoutEquipment> firstEquipment = const <WorkoutEquipment>{
    WorkoutEquipment.none,
  },
  Set<WorkoutEquipment> secondEquipment = const <WorkoutEquipment>{
    WorkoutEquipment.none,
  },
}) {
  return [
    skillTreeExercise(
      id: 'a_easy',
      name: 'Easier variation',
      familyId: familyId,
      rank: 1,
      difficulty: firstDifficulty,
      movementPattern: pattern,
      harderId: 'b_hard',
      equipment: firstEquipment,
    ),
    skillTreeExercise(
      id: 'b_hard',
      name: 'Harder variation',
      familyId: familyId,
      rank: 2,
      difficulty: secondDifficulty,
      movementPattern: pattern,
      easierId: 'a_easy',
      equipment: secondEquipment,
    ),
  ];
}
