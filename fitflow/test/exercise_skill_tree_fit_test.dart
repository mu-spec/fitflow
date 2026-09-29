import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

ExerciseSkillTreeNode _resolveFirstNode(
  Exercise exercise, {
  required UserFitnessProfile userProfile,
  required CapabilityProfile capabilityProfile,
}) {
  final familyId = exercise.progressionFamilyId ?? 'fit_test_family';
  final movement = exercise.movementPattern ?? MovementPattern.push;
  final sibling = skillTreeExercise(
    id: '${exercise.id}_sibling',
    familyId: familyId,
    rank: exercise.progressionRank + 1,
    difficulty: ExerciseDifficulty.level1,
    movementPattern: movement,
    easierId: exercise.id,
  );
  final catalog = ExerciseSkillTreeResolver.resolve(
    exercises: [exercise, sibling],
    userProfile: userProfile,
    capabilityProfile: capabilityProfile,
  );
  return catalog.trees.single.nodes.firstWhere(
    (node) => node.exercise.id == exercise.id,
  );
}

Exercise _targetExercise({
  String id = 'target',
  int rank = 1,
  ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
  Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
  SpaceRequirement space = SpaceRequirement.small,
  NoiseLevel noise = NoiseLevel.quiet,
  ImpactLevel impact = ImpactLevel.low,
  ExercisePosition? position = ExercisePosition.standing,
  JointLoad wristLoad = JointLoad.low,
  JointLoad kneeLoad = JointLoad.low,
  Set<String> tags = const {},
}) {
  return skillTreeExercise(
    id: id,
    familyId: 'fit_test_family',
    rank: rank,
    difficulty: difficulty,
    equipment: equipment,
    space: space,
    noise: noise,
    impact: impact,
    position: position,
    wristLoad: wristLoad,
    kneeLoad: kneeLoad,
    tags: tags,
  );
}

void main() {
  group('Exercise skill-tree movement-level fit', () {
    test('Level 1 exercise fits Level 1 movement capability', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level1),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level1},
        ),
      );

      expect(node.fitsCurrentLevel, isTrue);
      expect(node.status, ExerciseSkillTreeNodeStatus.fitsCurrentLevel);
    });

    test('Level 2 exercise is above Level 1 capability', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level2),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level1},
        ),
      );

      expect(node.fitsCurrentLevel, isFalse);
      expect(node.aboveCurrentLevel, isTrue);
    });

    test('lower exercise difficulty fits higher movement capability', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level2),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level4},
        ),
      );

      expect(node.fitsCurrentLevel, isTrue);
    });

    test('Level 5 exercise fits Level 5 capability', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level5),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level5},
        ),
      );

      expect(node.fitsCurrentLevel, isTrue);
    });

    test('missing capability is unavailable rather than guessed', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level1),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: CapabilityProfile.fromMap(const {}),
      );

      expect(node.fitsCurrentLevel, isNull);
      expect(node.status, ExerciseSkillTreeNodeStatus.movementLevelUnavailable);
      expect(node.canonicalEligibilityResult!.reasons,
          contains(ExerciseExclusionReason.missingCapability));
      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.fitsSetup);
    });

    test('progression rank does not determine capability fit', () {
      final capability = skillTreeCapabilityProfile(
        levels: const {MovementPattern.push: CapabilityLevel.level1},
      );
      final catalog = ExerciseSkillTreeResolver.resolve(
        exercises: [
          skillTreeExercise(
            id: 'rank_one_hard',
            familyId: 'rank_is_not_level',
            rank: 1,
            difficulty: ExerciseDifficulty.level5,
            harderId: 'rank_two_easy',
          ),
          skillTreeExercise(
            id: 'rank_two_easy',
            familyId: 'rank_is_not_level',
            rank: 2,
            difficulty: ExerciseDifficulty.level1,
            easierId: 'rank_one_hard',
          ),
        ],
        userProfile: skillTreeUserProfile(),
        capabilityProfile: capability,
      );

      expect(catalog.trees.single.nodes[0].progressionRank, 1);
      expect(
          catalog.trees.single.nodes[0].difficulty, ExerciseDifficulty.level5);
      expect(catalog.trees.single.nodes[0].fitsCurrentLevel, isFalse);
      expect(catalog.trees.single.nodes[1].progressionRank, 2);
      expect(
          catalog.trees.single.nodes[1].difficulty, ExerciseDifficulty.level1);
      expect(catalog.trees.single.nodes[1].fitsCurrentLevel, isTrue);
    });

    test('two nodes with the same exercise difficulty can both fit', () {
      final catalog = ExerciseSkillTreeResolver.resolve(
        exercises: [
          skillTreeExercise(
            id: 'same_level_a',
            familyId: 'same_difficulty',
            rank: 1,
            difficulty: ExerciseDifficulty.level2,
            harderId: 'same_level_b',
          ),
          skillTreeExercise(
            id: 'same_level_b',
            familyId: 'same_difficulty',
            rank: 2,
            difficulty: ExerciseDifficulty.level2,
            easierId: 'same_level_a',
          ),
        ],
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level2},
        ),
      );

      expect(catalog.trees.single.nodes.map((node) => node.fitsCurrentLevel),
          [true, true]);
    });

    test('resolver does not mutate the original CapabilityProfile', () {
      final capability = skillTreeCapabilityProfile(
        levels: const {MovementPattern.push: CapabilityLevel.level2},
      );
      final before = capability.toJson();
      _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level2),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: capability,
      );

      expect(capability.toJson(), before);
      expect(capability.capabilityFor(MovementPattern.push)?.level,
          CapabilityLevel.level2);
    });

    test('same input profiles and catalog produce the same fit result', () {
      final exercises = _targetExercise(difficulty: ExerciseDifficulty.level3);
      final user = skillTreeUserProfile();
      final capability = skillTreeCapabilityProfile(
        levels: const {MovementPattern.push: CapabilityLevel.level2},
      );
      final first = _resolveFirstNode(
        exercises,
        userProfile: user,
        capabilityProfile: capability,
      );
      final second = _resolveFirstNode(
        exercises,
        userProfile: user,
        capabilityProfile: capability,
      );

      expect(second.fitsCurrentLevel, first.fitsCurrentLevel);
      expect(
          second.canonicalEligibilityResult, first.canonicalEligibilityResult);
      expect(second.setupStatus, first.setupStatus);
    });
  });

  group('Exercise skill-tree setup compatibility', () {
    test('available required equipment fits setup', () {
      final node = _resolveFirstNode(
        _targetExercise(
          equipment: const {WorkoutEquipment.bench},
        ),
        userProfile: skillTreeUserProfile(
          equipment: const {WorkoutEquipment.bench},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.fitsSetup);
      expect(node.setupIssueLabels, isEmpty);
    });

    test('missing equipment reports a setup change', () {
      final node = _resolveFirstNode(
        _targetExercise(equipment: const {WorkoutEquipment.bench}),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.needsSetupChange);
      expect(node.setupExclusionReasons,
          contains(ExerciseExclusionReason.missingEquipment));
      expect(node.setupIssueLabels, contains('Needs different equipment'));
    });

    test('insufficient space uses canonical eligibility and factual copy', () {
      final node = _resolveFirstNode(
        _targetExercise(space: SpaceRequirement.medium),
        userProfile: skillTreeUserProfile(
          environment: TrainingEnvironment.apartment,
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupExclusionReasons,
          contains(ExerciseExclusionReason.insufficientSpace));
      expect(node.setupIssueLabels, contains('Needs more space'));
    });

    test('apartment noise limit uses canonical eligibility', () {
      final node = _resolveFirstNode(
        _targetExercise(noise: NoiseLevel.moderate),
        userProfile: skillTreeUserProfile(
          environment: TrainingEnvironment.apartment,
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupExclusionReasons,
          contains(ExerciseExclusionReason.tooNoisy));
      expect(node.setupIssueLabels,
          contains("Doesn't fit your current noise setting"));
    });

    test('low-impact preference is represented separately from level fit', () {
      final node = _resolveFirstNode(
        _targetExercise(impact: ImpactLevel.moderate),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.lowImpact},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupExclusionReasons,
          contains(ExerciseExclusionReason.lowImpactRequired));
      expect(node.setupIssueLabels,
          contains('Conflicts with low-impact preference'));
    });

    test('no-floor preference is represented by setup status', () {
      final node = _resolveFirstNode(
        _targetExercise(position: ExercisePosition.floor),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.noFloorExercises},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupIssueLabels,
          contains('Conflicts with your floor preference'));
    });

    test('standing-only preference is represented by setup status', () {
      final node = _resolveFirstNode(
        _targetExercise(position: ExercisePosition.floor),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.standingOnly},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupIssueLabels,
          contains('Conflicts with standing-only preference'));
    });

    test('wrist preference uses canonical joint-load exclusion', () {
      final node = _resolveFirstNode(
        _targetExercise(wristLoad: JointLoad.high),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.avoidWristHeavy},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(
          node.setupIssueLabels, contains('Conflicts with wrist preference'));
    });

    test('knee preference uses canonical joint-load exclusion', () {
      final node = _resolveFirstNode(
        _targetExercise(kneeLoad: JointLoad.high),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.avoidDeepKneeBending},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupIssueLabels, contains('Conflicts with knee preference'));
    });

    test('no-jumping preference uses canonical impact/tag rules', () {
      final node = _resolveFirstNode(
        _targetExercise(impact: ImpactLevel.high),
        userProfile: skillTreeUserProfile(
          preferences: const {WorkoutPreference.noJumping},
        ),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.setupExclusionReasons,
          contains(ExerciseExclusionReason.jumpingRestricted));
      expect(node.setupIssueLabels,
          contains('Conflicts with no-jumping preference'));
    });

    test('above-capability alone still fits the current setup', () {
      final node = _resolveFirstNode(
        _targetExercise(difficulty: ExerciseDifficulty.level4),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level2},
        ),
      );

      expect(node.fitsCurrentLevel, isFalse);
      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.fitsSetup);
      expect(node.setupExclusionReasons, isEmpty);
      expect(node.canonicalEligibilityResult!.reasons,
          contains(ExerciseExclusionReason.aboveCapability));
    });

    test('above-level exercise with available equipment shows both facts', () {
      final node = _resolveFirstNode(
        _targetExercise(
          difficulty: ExerciseDifficulty.level3,
          equipment: const {WorkoutEquipment.bench},
        ),
        userProfile: skillTreeUserProfile(
          equipment: const {WorkoutEquipment.bench},
        ),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level1},
        ),
      );

      expect(node.fitsCurrentLevel, isFalse);
      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.fitsSetup);
    });

    test('above-level exercise missing equipment keeps both statuses', () {
      final node = _resolveFirstNode(
        _targetExercise(
          difficulty: ExerciseDifficulty.level3,
          equipment: const {WorkoutEquipment.bench},
        ),
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(
          levels: const {MovementPattern.push: CapabilityLevel.level1},
        ),
      );

      expect(node.fitsCurrentLevel, isFalse);
      expect(node.setupStatus, ExerciseSkillTreeSetupStatus.needsSetupChange);
      expect(node.setupIssueLabels, contains('Needs different equipment'));
    });

    test('timed/reps exercise details stay sourced from Exercise data', () {
      final timed = skillTreeExercise(
        id: 'timed_target',
        familyId: 'timed_family',
        rank: 1,
        exerciseType: ExerciseType.timed,
      );
      final node = _resolveFirstNode(
        timed,
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(node.exercise.exerciseType, ExerciseType.timed);
      expect(node.canonicalEligibilityResult!.exercise.id, 'timed_target');
    });
  });
}
