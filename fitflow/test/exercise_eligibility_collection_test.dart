import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
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
    Set<String> tags = const {},
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
      tags: tags,
      active: active,
    );
  }

  CapabilityProfile createFullProfileLevel(CapabilityLevel level) {
    final now = DateTime.utc(2026, 1, 1);
    final map = <MovementPattern, MovementCapability>{};
    for (final p in CapabilityProfile.trainablePatterns) {
      map[p] = MovementCapability(
        movementPattern: p,
        level: level,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      );
    }
    return CapabilityProfile.fromMap(map);
  }

  CapabilityProfile createMixedProfile() {
    final now = DateTime.utc(2026, 1, 1);
    final map = <MovementPattern, MovementCapability>{
      MovementPattern.push: MovementCapability(
          movementPattern: MovementPattern.push,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.pull: MovementCapability(
          movementPattern: MovementPattern.pull,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.squat: MovementCapability(
          movementPattern: MovementPattern.squat,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.lunge: MovementCapability(
          movementPattern: MovementPattern.lunge,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.hinge: MovementCapability(
          movementPattern: MovementPattern.hinge,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.core: MovementCapability(
          movementPattern: MovementPattern.core,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.glute: MovementCapability(
          movementPattern: MovementPattern.glute,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.cardio: MovementCapability(
          movementPattern: MovementPattern.cardio,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.mobility: MovementCapability(
          movementPattern: MovementPattern.mobility,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
      MovementPattern.balance: MovementCapability(
          movementPattern: MovementPattern.balance,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now),
    };
    return CapabilityProfile.fromMap(map);
  }

  group('Missing Movement Pattern', () {
    test('null movementPattern gets missingMovementPattern and ineligible', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
        preferences: {},
      );

      final nullPatternExercise = createTestExercise(
        id: 'null_pattern',
        movementPattern: null,
        difficulty: ExerciseDifficulty.level1,
      );

      final result =
          ExerciseEligibilityEngine.evaluate(nullPatternExercise, context);
      expect(result.reasons,
          contains(ExerciseExclusionReason.missingMovementPattern));
      expect(result.eligible, false);
    });

    test('null movement does not crash', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final ex = createTestExercise(id: 'null_crash', movementPattern: null);
      expect(() => ExerciseEligibilityEngine.evaluate(ex, context),
          returnsNormally);
    });

    test('warmup does NOT get missingMovementPattern nor missingCapability',
        () {
      final incompleteProfile = CapabilityProfile.fromMap({});
      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final warmup = createTestExercise(
        id: 'warmup_test',
        movementPattern: MovementPattern.warmup,
        difficulty: ExerciseDifficulty.level1,
      );

      final result = ExerciseEligibilityEngine.evaluate(warmup, context);
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.missingMovementPattern)));
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.missingCapability)));
    });

    test('cooldown does NOT get missingMovementPattern nor missingCapability',
        () {
      final incompleteProfile = CapabilityProfile.fromMap({});
      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final cooldown = createTestExercise(
        id: 'cooldown_test',
        movementPattern: MovementPattern.cooldown,
        difficulty: ExerciseDifficulty.level5,
      );

      final result = ExerciseEligibilityEngine.evaluate(cooldown, context);
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.missingMovementPattern)));
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.missingCapability)));
    });

    test('null pattern can accumulate multiple reasons', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {}, // missing chair
        environment: TrainingEnvironment.apartment, // max small
        preferences: {},
      );

      final ex = Exercise(
        id: 'null_multi',
        name: 'null_multi',
        movementPattern: null,
        difficulty: ExerciseDifficulty.level1,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.large, // insufficient for apartment
        bodyPosition: ExercisePosition.standing,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        requiredEquipment: {WorkoutEquipment.chair}, // missing
        exerciseType: ExerciseType.reps,
        defaultReps: 10,
        defaultRest: const Duration(seconds: 30),
        active: true,
      );

      final result = ExerciseEligibilityEngine.evaluate(ex, context);
      expect(result.reasons,
          contains(ExerciseExclusionReason.missingMovementPattern));
      expect(result.reasons,
          contains(ExerciseExclusionReason.missingEquipment));
      expect(result.reasons,
          contains(ExerciseExclusionReason.insufficientSpace));
      expect(result.eligible, false);
    });
  });

  group('evaluateAll', () {
    test('result count equals catalog count and order matches by ID', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {
          WorkoutEquipment.chair,
          WorkoutEquipment.towel,
          WorkoutEquipment.bench
        },
        environment: TrainingEnvironment.largeRoom,
        preferences: {},
      );

      final all = ExerciseCatalog.all;
      final results = ExerciseEligibilityEngine.evaluateAll(all, context);

      expect(results.length, all.length);
      for (int i = 0; i < all.length; i++) {
        expect(results[i].exercise.id, all[i].id,
            reason: 'evaluateAll must preserve exact input order at index $i');
      }
    });

    test('eligible results correspond to filterEligible', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.apartment,
        preferences: {
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
          WorkoutPreference.noJumping
        },
      );

      final all = ExerciseCatalog.all;
      final evaluated = ExerciseEligibilityEngine.evaluateAll(all, context);
      final filtered = ExerciseEligibilityEngine.filterEligible(all, context);

      final eligibleFromEvaluateAll = evaluated
          .where((r) => r.eligible)
          .map((r) => r.exercise.id)
          .toList();
      final filteredIds = filtered.map((e) => e.id).toList();

      expect(eligibleFromEvaluateAll, filteredIds);
    });

    test('evaluateAll returns externally immutable list', () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );
      final input = [
        createTestExercise(id: 'a'),
        createTestExercise(id: 'b'),
      ];
      final results = ExerciseEligibilityEngine.evaluateAll(input, context);
      expect(() => results.add(results.first), throwsUnsupportedError);
    });

    test('evaluateAll does not mutate input', () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );
      final input = [
        createTestExercise(id: 'a'),
        createTestExercise(id: 'b'),
        createTestExercise(id: 'c'),
      ];
      final originalIds = input.map((e) => e.id).toList();
      ExerciseEligibilityEngine.evaluateAll(input, context);
      expect(input.map((e) => e.id).toList(), originalIds);
      expect(input.length, 3);
    });
  });

  group('filterEligible', () {
    test('empty input -> empty output', () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );
      final result = ExerciseEligibilityEngine.filterEligible([], context);
      expect(result, isEmpty);
    });

    test('preserves exact relative input order: eligible, ineligible, eligible, ineligible, eligible',
        () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {}, // no chair
        environment: TrainingEnvironment.normalHome,
        preferences: {},
      );

      // eligible = level1, no equipment, small space, quiet, active
      final e1 = createTestExercise(
          id: 'eligible_1',
          difficulty: ExerciseDifficulty.level1,
          equipment: {});
      // ineligible = above capability level5
      final i1 = createTestExercise(
          id: 'ineligible_1',
          difficulty: ExerciseDifficulty.level5,
          equipment: {});
      // eligible
      final e2 = createTestExercise(
          id: 'eligible_2',
          difficulty: ExerciseDifficulty.level1,
          equipment: {});
      // ineligible = missing equipment
      final i2 = createTestExercise(
          id: 'ineligible_2',
          difficulty: ExerciseDifficulty.level1,
          equipment: {WorkoutEquipment.chair});
      // eligible
      final e3 = createTestExercise(
          id: 'eligible_3',
          difficulty: ExerciseDifficulty.level1,
          equipment: {});

      final mixed = [e1, i1, e2, i2, e3];
      final filtered =
          ExerciseEligibilityEngine.filterEligible(mixed, context);

      expect(filtered.length, 3);
      expect(filtered[0].id, 'eligible_1');
      expect(filtered[1].id, 'eligible_2');
      expect(filtered[2].id, 'eligible_3');

      // Ensure no sorting by difficulty/name/movement/catalog rank
      // Our input order is already e1,e2,e3, so check that filtered order matches input eligible order
      expect(filtered.map((e) => e.id).toList(),
          ['eligible_1', 'eligible_2', 'eligible_3']);
    });

    test('filterEligible returns externally immutable list', () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );
      final input = [
        createTestExercise(id: 'a'),
        createTestExercise(id: 'b'),
      ];
      final result =
          ExerciseEligibilityEngine.filterEligible(input, context);
      expect(() => result.add(input.first), throwsUnsupportedError);
    });

    test('filterEligible does not mutate input', () {
      final profile = createFullProfileLevel(CapabilityLevel.level1);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );
      final input = [
        createTestExercise(id: 'x'),
        createTestExercise(id: 'y'),
        createTestExercise(id: 'z'),
      ];
      final originalIds = input.map((e) => e.id).toList();
      ExerciseEligibilityEngine.filterEligible(input, context);
      expect(input.map((e) => e.id).toList(), originalIds);
    });

    test('works with ExerciseCatalog.all', () {
      final profile = createFullProfileLevel(CapabilityLevel.level5);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
      );
      expect(
          () => ExerciseEligibilityEngine.filterEligible(
              ExerciseCatalog.all, context),
          returnsNormally);
    });
  });

  group('Determinism', () {
    test('evaluateAll twice identical input/context yields identical ordered results',
        () {
      final profile = createFullProfileLevel(CapabilityLevel.level2);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.chair},
        environment: TrainingEnvironment.apartment,
        preferences: {WorkoutPreference.lowImpact},
      );

      final input = [
        createTestExercise(
            id: 'a',
            difficulty: ExerciseDifficulty.level1,
            space: SpaceRequirement.small),
        createTestExercise(
            id: 'b',
            difficulty: ExerciseDifficulty.level5,
            space: SpaceRequirement.large),
        createTestExercise(
            id: 'c',
            difficulty: ExerciseDifficulty.level2,
            equipment: {WorkoutEquipment.chair}),
      ];

      final first = ExerciseEligibilityEngine.evaluateAll(input, context);
      final second = ExerciseEligibilityEngine.evaluateAll(input, context);

      expect(first.length, second.length);
      for (int i = 0; i < first.length; i++) {
        expect(first[i].exercise.id, second[i].exercise.id);
        expect(first[i].reasons, second[i].reasons);
        expect(first[i].eligible, second[i].eligible);
      }
    });

    test('filterEligible twice identical yields identical ordered results', () {
      final profile = createFullProfileLevel(CapabilityLevel.level2);
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
      );

      final input = [
        createTestExercise(id: 'a', difficulty: ExerciseDifficulty.level1),
        createTestExercise(id: 'b', difficulty: ExerciseDifficulty.level5),
        createTestExercise(id: 'c', difficulty: ExerciseDifficulty.level1),
      ];

      final first = ExerciseEligibilityEngine.filterEligible(input, context);
      final second = ExerciseEligibilityEngine.filterEligible(input, context);

      expect(first.map((e) => e.id).toList(),
          second.map((e) => e.id).toList());
    });
  });

  group('Full-Catalog Restrictive Context', () {
    test(
        'Apartment / quiet, no equipment, noJumping+lowImpact+standingOnly, complete capability',
        () {
      // Deliberate capability levels: all level2 to make capability part of eligibility
      final profile = createMixedProfile();
      expect(profile.isComplete, true);

      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {}, // no equipment
        environment: TrainingEnvironment.apartment, // small max, quiet max
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      final filtered =
          ExerciseEligibilityEngine.filterEligible(ExerciseCatalog.all, context);

      // Do not only assert non-empty; verify every returned exercise meets all constraints
      // Ensure at least some eligible exist for this restrictive context (sanity)
      // With level2 standing low impact etc, there should be eligible
      expect(filtered, isNotEmpty,
          reason: 'Restrictive context should still have some eligible');

      for (final ex in filtered) {
        // active == true
        expect(ex.active, true, reason: '${ex.id} should be active');

        // movement pattern is non-null
        expect(ex.movementPattern, isNotNull,
            reason: '${ex.id} movementPattern must be non-null');

        // if trainable, difficulty within capability
        final pattern = ex.movementPattern!;
        if (CapabilityProfile.trainablePatterns.contains(pattern)) {
          final cap = profile.capabilityFor(pattern);
          expect(cap, isNotNull,
              reason: '${ex.id} trainable pattern $pattern should have capability');
          final capDiff = cap!.level.toExerciseDifficulty();
          // compare ranks
          int rank(ExerciseDifficulty d) {
            switch (d) {
              case ExerciseDifficulty.level1:
                return 1;
              case ExerciseDifficulty.level2:
                return 2;
              case ExerciseDifficulty.level3:
                return 3;
              case ExerciseDifficulty.level4:
                return 4;
              case ExerciseDifficulty.level5:
                return 5;
            }
          }

          expect(rank(ex.difficulty) <= rank(capDiff), true,
              reason:
                  '${ex.id} difficulty ${ex.difficulty} should be <= capability ${cap.level} for $pattern');
        }

        // requires no unavailable real equipment
        final effectiveReq = ex.requiredEquipment
            .where((e) => e != WorkoutEquipment.none)
            .toSet();
        expect(effectiveReq, isEmpty,
            reason:
                '${ex.id} should require no real equipment, found $effectiveReq');

        // space is tiny/small
        expect(
            [
              SpaceRequirement.tiny,
              SpaceRequirement.small
            ].contains(ex.spaceRequirement),
            true,
            reason:
                '${ex.id} space ${ex.spaceRequirement} should be tiny/small for apartment');

        // noise is quiet
        expect(ex.noiseLevel, NoiseLevel.quiet,
            reason: '${ex.id} noise ${ex.noiseLevel} should be quiet for apartment');

        // impact is low
        expect(ex.impactLevel, ImpactLevel.low,
            reason: '${ex.id} impact ${ex.impactLevel} should be low');

        // body position is standing
        expect(ex.bodyPosition, ExercisePosition.standing,
            reason:
                '${ex.id} position ${ex.bodyPosition} should be standing');

        // No Jumping rule passes: explicit no_jumping OR no explicit jumping tag and not high impact
        final hasNoJumpingTag = ex.tags.contains('no_jumping');
        final hasJumpingTag = ex.tags.contains('jumping');
        final isHighImpact = ex.impactLevel == ImpactLevel.high;
        final passesNoJumping = hasNoJumpingTag || (!hasJumpingTag && !isHighImpact);
        expect(passesNoJumping, true,
            reason:
                '${ex.id} should pass No Jumping rule: hasNoJumping=$hasNoJumpingTag hasJumping=$hasJumpingTag high=$isHighImpact');

        // evaluation of that exercise has zero exclusion reasons
        final eval = ExerciseEligibilityEngine.evaluate(ex, context);
        expect(eval.reasons, isEmpty,
            reason:
                '${ex.id} evaluation should have zero reasons, found ${eval.reasons}');
        expect(eval.eligible, true);
      }
    });
  });

  group('Diagnostic Full-Catalog', () {
    test('evaluateAll count equals catalog count, order matches, eligible agrees', () {
      final profile = createMixedProfile();
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.apartment,
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      final all = ExerciseCatalog.all;
      final evaluated = ExerciseEligibilityEngine.evaluateAll(all, context);
      final filtered = ExerciseEligibilityEngine.filterEligible(all, context);

      // count equals catalog
      expect(evaluated.length, all.length);

      // order exactly matches catalog order by ID
      for (int i = 0; i < all.length; i++) {
        expect(evaluated[i].exercise.id, all[i].id);
      }

      // eligible results exactly correspond to filterEligible
      final eligibleIdsFromEval =
          evaluated.where((r) => r.eligible).map((r) => r.exercise.id).toList();
      final filteredIds = filtered.map((e) => e.id).toList();
      expect(eligibleIdsFromEval, filteredIds);
      expect(eligibleIdsFromEval.length, filtered.length);
    });
  });
}
