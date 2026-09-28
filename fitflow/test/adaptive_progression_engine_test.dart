import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_decision.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_engine.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile createProfileWithLevel(MovementPattern pattern, CapabilityLevel level, {DateTime? updatedAt}) {
  final now = updatedAt ?? DateTime.utc(2026, 1, 1);
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: p == pattern ? level : CapabilityLevel.level2,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

CapabilityProfile createFullProfile(CapabilityLevel level) {
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

WorkoutExercisePrescription makePrescriptionForPattern(MovementPattern pattern, CapabilityLevel level, {String? id}) {
  // Create a fake exercise with exact difficulty matching capability level for deterministic tests
  final exercise = Exercise(
    id: id ?? '${pattern.name}_${level.name}_test',
    name: '${pattern.name} ${level.label}',
    movementPattern: pattern,
    difficulty: level.toExerciseDifficulty(),
    impactLevel: ImpactLevel.low,
    noiseLevel: NoiseLevel.quiet,
    spaceRequirement: SpaceRequirement.small,
    wristLoad: JointLoad.low,
    kneeLoad: JointLoad.low,
    exerciseType: ExerciseType.reps,
    defaultReps: 10,
    defaultRest: const Duration(seconds: 30),
  );
  return WorkoutExercisePrescription(
    exercise: exercise,
    sets: 3,
    repsPerSet: 10,
    restBetweenSets: const Duration(seconds: 30),
  );
}

void main() {
  group('Adaptive Progression Engine', () {
    test('only trainable Main patterns considered', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {
            MovementPattern.push: MovementWorkoutFeedback.easy,
            MovementPattern.warmup: MovementWorkoutFeedback.easy,
          },
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      // Warmup should be ignored
      expect(result.decisions.containsKey(MovementPattern.warmup), false);
      expect(result.decisions.containsKey(MovementPattern.push), true);
    });

    test('warmup ignored', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      // Even if warmup exercise is in effective list, feedback for warmup should be ignored
      final warmupCandidates = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.warmup).toList();
      final List<WorkoutExercisePrescription> effective;
      if (warmupCandidates.isNotEmpty) {
        final warmupExercise = warmupCandidates.first;
        effective = [
          WorkoutExercisePrescription(
            exercise: warmupExercise,
            sets: 1,
            workDuration: const Duration(seconds: 30),
            restBetweenSets: Duration.zero,
          )
        ];
      } else {
        effective = [];
      }
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: effective,
          feedbackByMovement: {MovementPattern.warmup: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions.containsKey(MovementPattern.warmup), false);
      expect(result.updatedProfile == profile, true);
    });

    test('cooldown ignored', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      // Cooldown is not trainable, so even if provided, should be ignored
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: const [],
          feedbackByMovement: {MovementPattern.cooldown: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions.containsKey(MovementPattern.cooldown), false);
    });

    test('feedback only affects rated movement', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final squatPres = makePrescriptionForPattern(MovementPattern.squat, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres, squatPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions.containsKey(MovementPattern.push), true);
      expect(result.decisions.containsKey(MovementPattern.squat), false);
      expect(result.updatedProfile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level2);
    });

    test('Just right → unchanged', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.unchangedJustRight);
    });

    test('Just right resets Easy evidence', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedEvidence.countFor(MovementPattern.push), 0);
    });

    test('first qualifying Easy → no promotion, evidence=1', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
      expect(result.updatedEvidence.countFor(MovementPattern.push), 1);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.firstEasySignal);
    });

    test('second consecutive qualifying Easy → +1 level', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level3);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.promoted);
    });

    test('promotion resets evidence', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedEvidence.countFor(MovementPattern.push), 0);
    });

    test('no jump by 2 levels', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level.rank,
          lessThanOrEqualTo(CapabilityLevel.level3.rank));
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level.rank -
          CapabilityLevel.level2.rank, lessThanOrEqualTo(1));
    });

    test('Level5 never exceeds Level5', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level5);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level5);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level5);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.alreadyAtMaximum);
    });

    test('Too hard → -1', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level3);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.reduced);
    });

    test('Level1 never below Level1', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level1);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level1);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level1);
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.alreadyAtMinimum);
    });

    test('Too hard resets Easy evidence', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level3);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedEvidence.countFor(MovementPattern.push), 0);
    });

    test('source progression on promotion', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final now = DateTime.utc(2026, 1, 2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: now,
        ),
      );
      final cap = result.updatedProfile.capabilityFor(MovementPattern.push)!;
      expect(cap.source, CapabilitySource.progression);
      expect(cap.updatedAt, now);
    });

    test('source workoutFeedback on reduction', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level3);
      final now = DateTime.utc(2026, 1, 2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
          currentEvidence: evidence,
          now: now,
        ),
      );
      final cap = result.updatedProfile.capabilityFor(MovementPattern.push)!;
      expect(cap.source, CapabilitySource.workoutFeedback);
      expect(cap.updatedAt, now);
    });

    test('correct updatedAt only on actual level change', () {
      final originalDate = DateTime.utc(2026, 1, 1);
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2, updatedAt: originalDate);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final now = DateTime.utc(2026, 1, 2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: now,
        ),
      );
      final cap = result.updatedProfile.capabilityFor(MovementPattern.push)!;
      expect(cap.updatedAt, originalDate); // unchanged
    });

    test('no-change preserves old metadata', () {
      final originalDate = DateTime.utc(2026, 1, 1);
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2, updatedAt: originalDate);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      final cap = result.updatedProfile.capabilityFor(MovementPattern.push)!;
      expect(cap.source, CapabilitySource.initialAssessment);
      expect(cap.updatedAt, originalDate);
    });

    test('qualifying Easy requires exercise difficulty == current capability', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level3);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions[MovementPattern.push]!.type, isNot(MovementProgressionDecisionType.easyNotQualified));
    });

    test('below-capability Easy does not qualify', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.easyNotQualified);
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level3);
      expect(result.updatedEvidence.countFor(MovementPattern.push), 0);
    });

    test('replaced-away harder exercise does not qualify', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      // Effective is Level2, original was Level3 but replaced away
      final effectivePres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [effectivePres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions[MovementPattern.push]!.type, MovementProgressionDecisionType.easyNotQualified);
    });

    test('effective replacement at current capability can qualify', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level3);
      final evidence = AdaptiveProgressionEvidence.zero();
      final effectivePres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level3);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [effectivePres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.decisions[MovementPattern.push]!.type, isNot(MovementProgressionDecisionType.easyNotQualified));
    });

    test('deterministic anchor exercise', () {
      final profile = createProfileWithLevel(MovementPattern.push, CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres1 = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final pushPres2 = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final result1 = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres1, pushPres2],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      final result2 = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres1, pushPres2],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result1.decisions[MovementPattern.push]!.qualifyingExerciseId,
          result2.decisions[MovementPattern.push]!.qualifyingExerciseId);
      expect(result1.updatedProfile.capabilityFor(MovementPattern.push)!.anchorExerciseId,
          result2.updatedProfile.capabilityFor(MovementPattern.push)!.anchorExerciseId);
    });

    test('multiple movements update independently', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final squatPres = makePrescriptionForPattern(MovementPattern.squat, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres, squatPres],
          feedbackByMovement: {
            MovementPattern.push: MovementWorkoutFeedback.tooHard,
            MovementPattern.squat: MovementWorkoutFeedback.easy,
          },
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level1);
      expect(result.updatedProfile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level2);
      expect(result.updatedEvidence.countFor(MovementPattern.push), 0);
      expect(result.updatedEvidence.countFor(MovementPattern.squat), 1);
    });

    test('unrated movement untouched', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final squatPres = makePrescriptionForPattern(MovementPattern.squat, CapabilityLevel.level2);
      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres, squatPres],
          feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.justRight},
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(result.updatedProfile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level2);
      expect(result.updatedEvidence.countFor(MovementPattern.squat), 0);
      expect(result.decisions.containsKey(MovementPattern.squat), false);
    });

    test('same inputs → same result', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final input = AdaptiveProgressionInput(
        currentProfile: profile,
        effectiveMainPrescriptions: [pushPres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        currentEvidence: evidence,
        now: DateTime.utc(2026, 1, 2),
      );
      final result1 = AdaptiveProgressionEngine.calculate(input);
      final result2 = AdaptiveProgressionEngine.calculate(input);
      expect(result1.updatedProfile, result2.updatedProfile);
      expect(result1.updatedEvidence, result2.updatedEvidence);
      expect(result1.decisions[MovementPattern.push]!.type,
          result2.decisions[MovementPattern.push]!.type);
    });

    test('result input objects not mutated', () {
      final profile = createFullProfile(CapabilityLevel.level2);
      final evidence = AdaptiveProgressionEvidence.zero();
      final pushPres = makePrescriptionForPattern(MovementPattern.push, CapabilityLevel.level2);
      final feedback = {MovementPattern.push: MovementWorkoutFeedback.easy};
      final originalProfileLevel = profile.capabilityFor(MovementPattern.push)!.level;
      final originalEvidenceCount = evidence.countFor(MovementPattern.push);

      AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: profile,
          effectiveMainPrescriptions: [pushPres],
          feedbackByMovement: feedback,
          currentEvidence: evidence,
          now: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(profile.capabilityFor(MovementPattern.push)!.level, originalProfileLevel);
      expect(evidence.countFor(MovementPattern.push), originalEvidenceCount);
    });
  });
}
