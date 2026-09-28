import 'package:fitflow/features/workouts/application/adaptive_progression_controller.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
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
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CapabilityProfile createProfile(CapabilityLevel level) {
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

WorkoutExercisePrescription makePres(MovementPattern pattern, CapabilityLevel level) {
  final ex = Exercise(
    id: '${pattern.name}_${level.name}_test',
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
  return WorkoutExercisePrescription(exercise: ex, sets: 3, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30));
}

class FakeCapabilityController extends CapabilityProfileController {
  FakeCapabilityController({this.failSave = false, CapabilityProfile? initial}) : _initial = initial;
  bool failSave;
  CapabilityProfile? saved;
  CapabilityProfile? _initial;

  @override
  Future<CapabilityProfile?> build() async => _initial;

  @override
  Future<bool> saveProfile(CapabilityProfile profile) async {
    if (failSave) return false;
    saved = profile;
    return true;
  }
}

class _StorageBackedFakeController extends CapabilityProfileController {
  _StorageBackedFakeController(this.storage, this.fake);
  final CapabilityProfileStorage storage;
  final FakeCapabilityController fake;

  @override
  Future<CapabilityProfile?> build() async => fake._initial;

  @override
  Future<bool> saveProfile(CapabilityProfile profile) async {
    if (fake.failSave) return false;
    fake.saved = profile;
    return storage.save(profile);
  }
}

void main() {
  group('Adaptive Progression Application', () {
    test('evidence-only feedback persists evidence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, true);
      expect(evidenceStorage.load().countFor(MovementPattern.push), 1);
      expect(capController.saved, isNull); // no capability change
    });

    test('second Easy promotes capability', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, true);
      expect(capController.saved!.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level3);
      expect(evidenceStorage.load().countFor(MovementPattern.push), 0);
    });

    test('evidence reset persisted before promotion save', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      // Evidence should be reset even if capability saved
      expect(evidenceStorage.load().countFor(MovementPattern.push), 0);
      expect(capController.saved, isNotNull);
    });

    test('Too hard persists reset + capability reduction', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level3);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level3);

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, true);
      expect(evidenceStorage.load().countFor(MovementPattern.push), 0);
      expect(capController.saved!.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
    });

    test('capability save failure returns failure', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final capController = FakeCapabilityController(failSave: true);
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
    });

    test('no false success', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      final capController = FakeCapabilityController(failSave: true);
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      // Need evidence 1 to trigger promotion which will fail
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, false);
    });

    test('failed promotion cannot leave stale promotion-ready evidence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final capController = FakeCapabilityController(failSave: true);
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      // Evidence should be reset to 0 (conservative), not left at 1 which could promote repeatedly
      expect(evidenceStorage.load().countFor(MovementPattern.push), 0);
    });

    test('only rated movement capability changes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level3);
      final pushPres = makePres(MovementPattern.push, CapabilityLevel.level3);
      final squatPres = makePres(MovementPattern.squat, CapabilityLevel.level3);

      final result = await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pushPres, squatPres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.tooHard},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, true);
      expect(capController.saved!.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
      expect(capController.saved!.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level3);
    });

    test('provider reflects successful saved profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      final storage = CapabilityProfileStorage(prefs);
      final initialProfile = createProfile(CapabilityLevel.level2);
      await storage.save(initialProfile);

      // Use fake controller that also persists via storage for testability
      final fakeCapController = FakeCapabilityController(initial: initialProfile);
      // Override save to also write to storage
      final controller = AdaptiveProgressionController(
        capabilityController: _StorageBackedFakeController(storage, fakeCapController),
        evidenceStorage: evidenceStorage,
      );

      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);
      await evidenceStorage.save(AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1));

      final result = await controller.applyFeedback(
        currentProfile: initialProfile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      expect(result.success, true);
      final loaded = storage.load();
      expect(loaded!.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level3);
    });

    test('no workout history written', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
      final capController = FakeCapabilityController();
      final controller = AdaptiveProgressionController(
        capabilityController: capController,
        evidenceStorage: evidenceStorage,
      );

      final profile = createProfile(CapabilityLevel.level2);
      final pres = makePres(MovementPattern.push, CapabilityLevel.level2);

      await controller.applyFeedback(
        currentProfile: profile,
        effectiveMainPrescriptions: [pres],
        feedbackByMovement: {MovementPattern.push: MovementWorkoutFeedback.easy},
        now: DateTime.utc(2026, 1, 2),
      );

      // Only evidence key and capability key should exist, no history keys
      final keys = prefs.getKeys();
      expect(keys.contains('adaptive_progression_evidence_v1'), true);
      // Ensure no history-like keys
      expect(keys.any((k) => k.contains('history') || k.contains('workout') && k != 'capability_profile'), false);
    });
  });
}
