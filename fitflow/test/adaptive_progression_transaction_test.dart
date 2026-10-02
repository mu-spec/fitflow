import 'dart:async';

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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CapabilityProfile _profile(CapabilityLevel level) {
  final now = DateTime.utc(2026, 1, 1);
  final map = <MovementPattern, MovementCapability>{};
  for (final pattern in CapabilityProfile.trainablePatterns) {
    map[pattern] = MovementCapability(
      movementPattern: pattern,
      level: level,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

WorkoutExercisePrescription _pres(MovementPattern pattern, CapabilityLevel level) {
  return WorkoutExercisePrescription(
    exercise: Exercise(
      id: '${pattern.name}_${level.name}_tx',
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
    ),
    sets: 3,
    repsPerSet: 10,
    restBetweenSets: const Duration(seconds: 30),
  );
}

class _FailingCapabilityController extends CapabilityProfileController {
  _FailingCapabilityController(this.initial);
  final CapabilityProfile initial;
  CapabilityProfile? saved;

  @override
  Future<CapabilityProfile?> build() async => initial;

  @override
  Future<bool> saveProfile(CapabilityProfile profile) async => false;
}

class _DiskCapabilityController extends CapabilityProfileController {
  _DiskCapabilityController(this.storage, this.initial);
  final CapabilityProfileStorage storage;
  final CapabilityProfile initial;
  int saves = 0;
  int? failOnSave;

  @override
  Future<CapabilityProfile?> build() async => initial;

  @override
  Future<bool> saveProfile(CapabilityProfile profile) async {
    saves++;
    if (failOnSave == saves) return false;
    final saved = await storage.save(profile);
    if (saved) state = AsyncData(profile);
    return saved;
  }
}

class _GatedCapabilityController extends CapabilityProfileController {
  _GatedCapabilityController(this.gate);
  final Completer<void> gate;
  int calls = 0;
  CapabilityProfile? saved;

  @override
  Future<CapabilityProfile?> build() async => null;

  @override
  Future<bool> saveProfile(CapabilityProfile profile) async {
    calls++;
    await gate.future;
    saved = profile;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const push = MovementPattern.push;

  Future<AdaptiveProgressionEvidenceStorage> evidence({
    Future<bool> Function(String encoded)? writeString,
    int initialCount = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = AdaptiveProgressionEvidenceStorage(
      prefs,
      writeString: writeString,
    );
    await storage.save(
      AdaptiveProgressionEvidence.zero().withCount(push, initialCount),
    );
    return storage;
  }

  test('evidence write failure leaves both keys unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await AdaptiveProgressionEvidenceStorage(prefs).save(
      AdaptiveProgressionEvidence.zero().withCount(push, 1),
    );
    final storage = AdaptiveProgressionEvidenceStorage(
      prefs,
      writeString: (_) async => false,
    );
    final profile = _profile(CapabilityLevel.level2);
    final cap = _FailingCapabilityController(profile);
    final controller = AdaptiveProgressionController(
      capabilityController: cap,
      evidenceStorage: storage,
    );

    final result = await controller.applyFeedback(
      currentProfile: profile,
      effectiveMainPrescriptions: [_pres(push, CapabilityLevel.level2)],
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );

    expect(result.success, isFalse);
    expect(result.status, AdaptiveProgressionApplyStatus.failed);
    expect(result.needsReload, isFalse);
    expect(storage.load().countFor(push), 1);
    expect(cap.saved, isNull);
  });

  test('capability write failure rolls evidence back', () async {
    final storage = await evidence();
    final profile = _profile(CapabilityLevel.level2);
    final cap = _FailingCapabilityController(profile);
    final controller = AdaptiveProgressionController(
      capabilityController: cap,
      evidenceStorage: storage,
    );

    final result = await controller.applyFeedback(
      currentProfile: profile,
      effectiveMainPrescriptions: [_pres(push, CapabilityLevel.level2)],
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );

    expect(result.success, isFalse);
    expect(result.status, AdaptiveProgressionApplyStatus.failed);
    expect(result.errorMessage, AdaptiveProgressionApplyResult.failedMessage);
    expect(storage.load().countFor(push), 1);
    expect(cap.saved, isNull);
  });

  test('rollback failure is explicit and does not claim success', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var writes = 0;
    final storage = AdaptiveProgressionEvidenceStorage(
      prefs,
      writeString: (encoded) async {
        writes++;
        if (writes == 1) {
          return prefs.setString(
            AdaptiveProgressionEvidenceStorage.evidenceKey,
            encoded,
          );
        }
        return false;
      },
    );
    await storage.save(
      AdaptiveProgressionEvidence.zero().withCount(push, 1),
    );
    // The hook counted the seed write. Reset so the next write is the
    // forward commit and the one after that is the rollback.
    writes = 0;

    final profile = _profile(CapabilityLevel.level2);
    final cap = _FailingCapabilityController(profile);
    final controller = AdaptiveProgressionController(
      capabilityController: cap,
      evidenceStorage: storage,
    );

    final result = await controller.applyFeedback(
      currentProfile: profile,
      effectiveMainPrescriptions: [_pres(push, CapabilityLevel.level2)],
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );

    expect(result.success, isFalse);
    expect(result.status, AdaptiveProgressionApplyStatus.rollbackIncomplete);
    expect(result.needsReload, isTrue);
    expect(
      result.errorMessage,
      AdaptiveProgressionApplyResult.rollbackIncompleteMessage,
    );
    expect(storage.load().countFor(push), 0,
        reason: 'evidence advanced and the restore write failed');
    expect(cap.saved, isNull);
  });

  test('success commits both and provider matches persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
    await evidenceStorage.save(
      AdaptiveProgressionEvidence.zero().withCount(push, 1),
    );
    final capStorage = CapabilityProfileStorage(prefs);
    final initial = _profile(CapabilityLevel.level2);
    await capStorage.save(initial);

    final container = ProviderContainer(
      overrides: [
        capabilityProfileProvider.overrideWith(
          () => _DiskCapabilityController(capStorage, initial),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(capabilityProfileProvider.future);

    final controller = AdaptiveProgressionController(
      capabilityController: container.read(capabilityProfileProvider.notifier),
      evidenceStorage: evidenceStorage,
      readPersistedCapability: () async => capStorage.load(),
    );

    final result = await controller.applyFeedback(
      currentProfile: initial,
      effectiveMainPrescriptions: [_pres(push, CapabilityLevel.level2)],
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );

    expect(result.success, isTrue);
    expect(result.status, AdaptiveProgressionApplyStatus.success);
    expect(evidenceStorage.load().countFor(push), 0);
    final disk = capStorage.load()!;
    final memory = container.read(capabilityProfileProvider).value!;
    expect(disk.capabilityFor(push)!.level, CapabilityLevel.level3);
    expect(memory, disk);
  });

  test('provider stays on the original profile when capability save fails',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final evidenceStorage = AdaptiveProgressionEvidenceStorage(prefs);
    await evidenceStorage.save(
      AdaptiveProgressionEvidence.zero().withCount(push, 1),
    );
    final capStorage = CapabilityProfileStorage(prefs);
    final initial = _profile(CapabilityLevel.level2);
    await capStorage.save(initial);
    final diskCap = _DiskCapabilityController(capStorage, initial)
      ..failOnSave = 1;

    final container = ProviderContainer(
      overrides: [
        capabilityProfileProvider.overrideWith(() => diskCap),
      ],
    );
    addTearDown(container.dispose);
    await container.read(capabilityProfileProvider.future);

    final controller = AdaptiveProgressionController(
      capabilityController: container.read(capabilityProfileProvider.notifier),
      evidenceStorage: evidenceStorage,
      readPersistedCapability: () async => capStorage.load(),
    );

    final result = await controller.applyFeedback(
      currentProfile: initial,
      effectiveMainPrescriptions: [_pres(push, CapabilityLevel.level2)],
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );

    expect(result.success, isFalse);
    expect(container.read(capabilityProfileProvider).value, initial);
    expect(capStorage.load(), initial);
    expect(evidenceStorage.load().countFor(push), 1);
  });

  test('concurrent applies do not interleave a partial promotion', () async {
    final storage = await evidence();
    final gate = Completer<void>();
    final cap = _GatedCapabilityController(gate);
    final controller = AdaptiveProgressionController(
      capabilityController: cap,
      evidenceStorage: storage,
    );
    final profile = _profile(CapabilityLevel.level2);
    final pres = [_pres(push, CapabilityLevel.level2)];

    final first = controller.applyFeedback(
      currentProfile: profile,
      effectiveMainPrescriptions: pres,
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 2),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = controller.applyFeedback(
      currentProfile: profile,
      effectiveMainPrescriptions: pres,
      feedbackByMovement: {push: MovementWorkoutFeedback.easy},
      now: DateTime.utc(2026, 1, 3),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cap.calls, 1, reason: 'the second apply must wait for the first');
    gate.complete();
    final results = await Future.wait([first, second]);
    expect(results.first.success, isTrue);
    expect(cap.calls, 1, reason: 'the queued apply sees reset evidence');
    expect(storage.load().countFor(push), 1);
  });
}
