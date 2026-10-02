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
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:flutter_test/flutter_test.dart';

/// Milestone 20 Part 2: canonical eligibility regression matrix.
///
/// Every assertion goes through `ExerciseEligibilityEngine.evaluate` — no
/// duplicated rules inside tests beyond expected-result assertions.
void main() {
  final anchorDate = DateTime.utc(2026, 10, 1);

  // Level-5 capability everywhere so only the restriction under test gates.
  final capability = CapabilityProfile.fromMap({
    for (final pattern in CapabilityProfile.trainablePatterns)
      pattern: MovementCapability(
        movementPattern: pattern,
        level: CapabilityLevel.level5,
        source: CapabilitySource.initialAssessment,
        updatedAt: anchorDate,
      ),
  });

  ExerciseEligibilityContext context({
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {},
    Set<WorkoutPreference> preferences = const {},
  }) {
    return ExerciseEligibilityContext(
      capabilityProfile: capability,
      environment: environment,
      availableEquipment: equipment,
      preferences: preferences,
    );
  }

  Exercise exercise(String id) {
    final found = ExerciseCatalog.byId(id);
    expect(found, isNotNull, reason: 'catalog must contain $id');
    return found!;
  }

  group('equipment restriction', () {
    test('missing chair excludes chair exercises with missingEquipment', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('dip_chair'),
        context(equipment: const {}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.missingEquipment));
      expect(result.missingEquipment, contains(WorkoutEquipment.chair));
    });

    test('having the chair makes dip_chair equipment-eligible', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('dip_chair'),
        context(equipment: const {WorkoutEquipment.chair}),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.missingEquipment)));
    });

    test('bench and towel requirements behave canonically', () {
      expect(
        ExerciseEligibilityEngine.evaluate(
                exercise('pushup_incline'), context(equipment: const {}))
            .missingEquipment,
        contains(WorkoutEquipment.bench),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(
                exercise('row_towel'), context(equipment: const {}))
            .missingEquipment,
        contains(WorkoutEquipment.towel),
      );
      expect(
        ExerciseEligibilityEngine.evaluate(exercise('pushup_standard'),
                context(equipment: const {}))
            .eligible,
        isTrue,
      );
    });

    test('no catalog exercise requires equipment the app does not model '
        'as available user gear', () {
      // Factual coverage statement: bands/dumbbells/kettlebell/pull-up bar
      // exist in the enum but the catalog intentionally needs none of them.
      final usedEquipment = ExerciseCatalog.all
          .expand((e) => e.requiredEquipment)
          .toSet()
          .difference({WorkoutEquipment.none});
      for (final item in usedEquipment) {
        expect(
          const [
            WorkoutEquipment.chair,
            WorkoutEquipment.bench,
            WorkoutEquipment.towel,
          ],
          contains(item),
          reason: 'unexpected equipment requirement: $item',
        );
      }
    });
  });

  group('space restriction', () {
    test('medium-space exercise is insufficient for apartment space', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('lunge_forward'),
        context(environment: TrainingEnvironment.apartment),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.insufficientSpace));
    });

    test('tiny-space exercise passes apartment space', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('march_in_place'),
        context(environment: TrainingEnvironment.apartment),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.insufficientSpace)));
    });
  });

  group('noise restriction', () {
    test('loud exercise is too noisy for apartment', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('jumping_jacks'),
        context(environment: TrainingEnvironment.apartment),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons, contains(ExerciseExclusionReason.tooNoisy));
    });

    test('quiet exercise passes apartment noise rules', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('step_jack'),
        context(environment: TrainingEnvironment.apartment),
      );
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.tooNoisy)));
    });
  });

  group('impact / jumping restriction', () {
    test('noJumping excludes jumping-tagged exercise', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('high_knees'),
        context(preferences: const {WorkoutPreference.noJumping}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.jumpingRestricted));
    });

    test('no_jumping-tagged skater_step remains eligible under noJumping',
        () {
      final skater = exercise('skater_step');
      expect(skater.tags, contains('no_jumping'));
      // Instructions must no longer encourage hopping.
      expect(
        skater.instructions.join(' ').toLowerCase(),
        isNot(contains('hop')),
      );
      final result = ExerciseEligibilityEngine.evaluate(
        skater,
        context(preferences: const {WorkoutPreference.noJumping}),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });

    test('lowImpact excludes non-low impact exercise', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('burpee_low_impact'),
        context(preferences: const {WorkoutPreference.lowImpact}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.lowImpactRequired));
    });
  });

  group('floor restriction (protects Part 1 dip_chair correction)', () {
    test('floor exercise is excluded under noFloorExercises', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('plank_forearm'),
        context(preferences: const {WorkoutPreference.noFloorExercises}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.floorRestricted));
    });

    test('dip_chair is NOT rejected as floor-only anymore', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('dip_chair'),
        context(
          equipment: const {WorkoutEquipment.chair},
          preferences: const {WorkoutPreference.noFloorExercises},
        ),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.floorRestricted)));
      expect(result.eligible, isTrue,
          reason: 'chair dip never touches the floor; reasons: '
              '${result.reasons}');
    });

    test('dip_chair may still fail other profile restrictions truthfully',
        () {
      // Without the chair it remains equipment-gated.
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('dip_chair'),
        context(preferences: const {WorkoutPreference.noFloorExercises}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.missingEquipment));
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.floorRestricted)));
    });
  });

  group('standing-only restriction (protects Part 1 dip_chair correction)',
      () {
    test('only standing exercises pass standingOnly', () {
      final standing = ExerciseEligibilityEngine.evaluate(
        exercise('march_in_place'),
        context(preferences: const {WorkoutPreference.standingOnly}),
      );
      expect(standing.eligible, isTrue);

      final floor = ExerciseEligibilityEngine.evaluate(
        exercise('plank_forearm'),
        context(preferences: const {WorkoutPreference.standingOnly}),
      );
      expect(floor.reasons,
          contains(ExerciseExclusionReason.standingOnlyRequired));
    });

    test('seated dip_chair is not considered standing', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('dip_chair'),
        context(
          equipment: const {WorkoutEquipment.chair},
          preferences: const {WorkoutPreference.standingOnly},
        ),
      );
      expect(result.reasons,
          contains(ExerciseExclusionReason.standingOnlyRequired));
    });
  });

  group('wrist restriction', () {
    test('avoidWristHeavy excludes high wrist-load push-up', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('pushup_standard'),
        context(preferences: const {WorkoutPreference.avoidWristHeavy}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.wristLoadRestricted));
    });

    test('forearm plank (no wrist load) passes wrist avoidance', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('plank_forearm'),
        context(preferences: const {WorkoutPreference.avoidWristHeavy}),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.wristLoadRestricted)));
    });
  });

  group('knee restriction', () {
    test('avoidDeepKneeBending excludes high knee-load lunge', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('lunge_forward'),
        context(preferences: const {WorkoutPreference.avoidDeepKneeBending}),
      );
      expect(result.eligible, isFalse);
      expect(result.reasons,
          contains(ExerciseExclusionReason.kneeLoadRestricted));
    });

    test('low knee-load exercise passes knee avoidance', () {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise('bridge_glute'),
        context(preferences: const {WorkoutPreference.avoidDeepKneeBending}),
      );
      expect(result.reasons,
          isNot(contains(ExerciseExclusionReason.kneeLoadRestricted)));
    });
  });
}
