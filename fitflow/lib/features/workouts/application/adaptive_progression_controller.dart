import 'package:fitflow/core/persistence/mutation_queue.dart';
import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_engine.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of an M10 two-state tuning update.
enum AdaptiveProgressionApplyStatus {
  success,
  failed,
  rollbackIncomplete,
}

/// Result of applying feedback, including success/failure.
class AdaptiveProgressionApplyResult {
  const AdaptiveProgressionApplyResult({
    required this.success,
    this.status = AdaptiveProgressionApplyStatus.failed,
    this.engineResult,
    this.errorMessage,
  });

  static const String failedMessage =
      "Couldn't update your workout tuning. Try again.";

  static const String rollbackIncompleteMessage =
      "Couldn't update workout tuning. Restart FitFlow before trying again.";

  final bool success;
  final AdaptiveProgressionApplyStatus status;
  final AdaptiveProgressionResult? engineResult;
  final String? errorMessage;

  /// Disk and memory could not be restored to one consistent pair.
  bool get needsReload =>
      status == AdaptiveProgressionApplyStatus.rollbackIncomplete;

  factory AdaptiveProgressionApplyResult.succeeded(
    AdaptiveProgressionResult result,
  ) {
    return AdaptiveProgressionApplyResult(
      success: true,
      status: AdaptiveProgressionApplyStatus.success,
      engineResult: result,
    );
  }

  const AdaptiveProgressionApplyResult.failed()
      : success = false,
        status = AdaptiveProgressionApplyStatus.failed,
        engineResult = null,
        errorMessage = failedMessage;

  const AdaptiveProgressionApplyResult.rollbackIncomplete()
      : success = false,
        status = AdaptiveProgressionApplyStatus.rollbackIncomplete,
        engineResult = null,
        errorMessage = rollbackIncompleteMessage;
}

class AdaptiveProgressionController {
  AdaptiveProgressionController({
    required this.capabilityController,
    required this.evidenceStorage,
    this.readPersistedCapability,
  });

  final CapabilityProfileController capabilityController;
  final AdaptiveProgressionEvidenceStorage evidenceStorage;

  /// When set, success requires the persisted capability to match the
  /// calculated profile. Production wires this to the preferences seam.
  final Future<CapabilityProfile?> Function()? readPersistedCapability;

  final MutationQueue _mutations = MutationQueue();

  /// Builds a controller from an already-acquired preferences handle.
  ///
  /// Production code should obtain [preferences] from
  /// [sharedPreferencesProvider] rather than calling
  /// `SharedPreferences.getInstance()` itself.
  static AdaptiveProgressionController createWithPreferences({
    required CapabilityProfileController capabilityController,
    required SharedPreferences preferences,
    Future<CapabilityProfile?> Function()? readPersistedCapability,
  }) {
    return AdaptiveProgressionController(
      capabilityController: capabilityController,
      evidenceStorage: AdaptiveProgressionEvidenceStorage(preferences),
      readPersistedCapability: readPersistedCapability ??
          (() async => CapabilityProfileStorage(preferences).load()),
    );
  }

  /// Pure calculation without I/O, for preview.
  AdaptiveProgressionResult preview({
    required CapabilityProfile currentProfile,
    required List<WorkoutExercisePrescription> effectiveMainPrescriptions,
    required Map<MovementPattern, MovementWorkoutFeedback> feedbackByMovement,
    required AdaptiveProgressionEvidence currentEvidence,
    required DateTime now,
  }) {
    return AdaptiveProgressionEngine.calculate(
      AdaptiveProgressionInput(
        currentProfile: currentProfile,
        effectiveMainPrescriptions: effectiveMainPrescriptions,
        feedbackByMovement: feedbackByMovement,
        currentEvidence: currentEvidence,
        now: now,
      ),
    );
  }

  /// Applies feedback so capability and evidence commit together.
  ///
  /// Evidence is written first, then capability. If a required write fails,
  /// already-changed values are restored. Success is returned only when both
  /// persisted values match the calculated result. A failed rollback is
  /// reported as [AdaptiveProgressionApplyStatus.rollbackIncomplete] and the
  /// capability provider is kept aligned with what actually survived.
  Future<AdaptiveProgressionApplyResult> applyFeedback({
    required CapabilityProfile currentProfile,
    required List<WorkoutExercisePrescription> effectiveMainPrescriptions,
    required Map<MovementPattern, MovementWorkoutFeedback> feedbackByMovement,
    required DateTime now,
  }) {
    return _mutations.enqueue(() => _applyOnce(
          currentProfile: currentProfile,
          effectiveMainPrescriptions: effectiveMainPrescriptions,
          feedbackByMovement: feedbackByMovement,
          now: now,
        ));
  }

  Future<AdaptiveProgressionApplyResult> _applyOnce({
    required CapabilityProfile currentProfile,
    required List<WorkoutExercisePrescription> effectiveMainPrescriptions,
    required Map<MovementPattern, MovementWorkoutFeedback> feedbackByMovement,
    required DateTime now,
  }) async {
    late final AdaptiveProgressionEvidence originalEvidence;
    try {
      originalEvidence = evidenceStorage.load();
    } catch (_) {
      return const AdaptiveProgressionApplyResult.failed();
    }

    late final AdaptiveProgressionResult engineResult;
    try {
      engineResult = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: currentProfile,
          effectiveMainPrescriptions: effectiveMainPrescriptions,
          feedbackByMovement: feedbackByMovement,
          currentEvidence: originalEvidence,
          now: now,
        ),
      );
    } catch (_) {
      return const AdaptiveProgressionApplyResult.failed();
    }

    final willChangeCapability = engineResult.updatedProfile != currentProfile;
    final willChangeEvidence = engineResult.updatedEvidence != originalEvidence;

    if (!willChangeCapability && !willChangeEvidence) {
      return AdaptiveProgressionApplyResult.succeeded(engineResult);
    }

    var evidenceWritten = false;
    var capabilityWritten = false;

    try {
      // Capability changes still persist evidence first, matching the
      // established conservative order, even when the evidence value is
      // unchanged. A failed write never leaves the other key advanced.
      if (willChangeEvidence || willChangeCapability) {
        final saved = await evidenceStorage.save(engineResult.updatedEvidence);
        if (!saved) {
          return await _rollback(
            originalEvidence: originalEvidence,
            originalCapability: currentProfile,
            proposedCapability: engineResult.updatedProfile,
            restoreEvidence: !_evidenceEquals(originalEvidence),
            restoreCapability: false,
          );
        }
        evidenceWritten = true;
      }

      if (willChangeCapability) {
        final saved =
            await capabilityController.saveProfile(engineResult.updatedProfile);
        if (!saved) {
          _rejectUncommittedCapability(
            originalCapability: currentProfile,
            proposedCapability: engineResult.updatedProfile,
          );
          return await _rollback(
            originalEvidence: originalEvidence,
            originalCapability: currentProfile,
            proposedCapability: engineResult.updatedProfile,
            restoreEvidence: evidenceWritten &&
                !_evidenceEquals(originalEvidence),
            restoreCapability: false,
          );
        }
        capabilityWritten = true;
      }

      if (!await _commitsMatch(
        engineResult: engineResult,
        willChangeCapability: willChangeCapability,
      )) {
        return await _rollback(
          originalEvidence: originalEvidence,
          originalCapability: currentProfile,
          proposedCapability: engineResult.updatedProfile,
          restoreEvidence:
              evidenceWritten && !_evidenceEquals(originalEvidence),
          restoreCapability: capabilityWritten,
        );
      }

      if (willChangeCapability) {
        _adopt(engineResult.updatedProfile);
      }
      return AdaptiveProgressionApplyResult.succeeded(engineResult);
    } catch (_) {
      return await _rollback(
        originalEvidence: originalEvidence,
        originalCapability: currentProfile,
        proposedCapability: engineResult.updatedProfile,
        restoreEvidence:
            evidenceWritten && !_evidenceEquals(originalEvidence),
        restoreCapability: capabilityWritten,
      );
    }
  }

  Future<bool> _commitsMatch({
    required AdaptiveProgressionResult engineResult,
    required bool willChangeCapability,
  }) async {
    if (!_evidenceEquals(engineResult.updatedEvidence)) return false;
    if (!willChangeCapability) return true;
    return _capabilityMatches(engineResult.updatedProfile);
  }

  Future<AdaptiveProgressionApplyResult> _rollback({
    required AdaptiveProgressionEvidence originalEvidence,
    required CapabilityProfile originalCapability,
    required CapabilityProfile proposedCapability,
    required bool restoreEvidence,
    required bool restoreCapability,
  }) async {
    var evidenceOk = _evidenceEquals(originalEvidence);
    if (!evidenceOk && restoreEvidence) {
      evidenceOk = await _restoreEvidence(originalEvidence);
    } else if (!evidenceOk) {
      evidenceOk = await _restoreEvidence(originalEvidence);
    }

    var capabilityOk = true;
    if (restoreCapability) {
      capabilityOk = await _restoreCapability(originalCapability);
    } else {
      _rejectUncommittedCapability(
        originalCapability: originalCapability,
        proposedCapability: proposedCapability,
      );
    }

    if (!evidenceOk || !capabilityOk) {
      return const AdaptiveProgressionApplyResult.rollbackIncomplete();
    }
    return const AdaptiveProgressionApplyResult.failed();
  }

  Future<bool> _restoreEvidence(AdaptiveProgressionEvidence original) async {
    try {
      final saved = await evidenceStorage.save(original);
      if (!saved) return _evidenceEquals(original);
      return _evidenceEquals(original);
    } catch (_) {
      return _evidenceEquals(original);
    }
  }

  Future<bool> _restoreCapability(CapabilityProfile original) async {
    try {
      final saved = await capabilityController.saveProfile(original);
      final disk = await _readCapabilityDisk();
      if (disk != null) {
        _adopt(disk);
        return saved && disk == original;
      }
      if (saved) {
        _adopt(original);
      }
      return saved && capabilityController.memoryMatches(original) != false;
    } catch (_) {
      final disk = await _readCapabilityDisk();
      if (disk != null) {
        _adopt(disk);
        return disk == original;
      }
      return false;
    }
  }

  Future<bool> _capabilityMatches(CapabilityProfile expected) async {
    final reader = readPersistedCapability;
    if (reader != null) {
      try {
        final disk = await reader();
        if (disk != expected) return false;
      } catch (_) {
        return false;
      }
    }
    final memory = capabilityController.memoryMatches(expected);
    if (memory == false) return false;
    return true;
  }

  Future<CapabilityProfile?> _readCapabilityDisk() async {
    final reader = readPersistedCapability;
    if (reader == null) return null;
    try {
      return await reader();
    } catch (_) {
      return null;
    }
  }

  bool _evidenceEquals(AdaptiveProgressionEvidence expected) {
    try {
      return evidenceStorage.load() == expected;
    } catch (_) {
      return false;
    }
  }

  void _adopt(CapabilityProfile? profile) {
    capabilityController.adoptPersistedProfile(profile);
  }

  void _rejectUncommittedCapability({
    required CapabilityProfile originalCapability,
    required CapabilityProfile proposedCapability,
  }) {
    capabilityController.rejectUncommittedChange(
      original: originalCapability,
      proposed: proposedCapability,
    );
  }
}

final adaptiveProgressionControllerProvider =
    Provider<AdaptiveProgressionController>((ref) {
  throw UnimplementedError(
      'Override adaptiveProgressionControllerProvider in tests or via FutureProvider');
});

final adaptiveProgressionEvidenceStorageProvider =
    FutureProvider<AdaptiveProgressionEvidenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AdaptiveProgressionEvidenceStorage(prefs);
});

final adaptiveProgressionControllerAsyncProvider =
    FutureProvider<AdaptiveProgressionController>((ref) async {
  final capabilityController = ref.read(capabilityProfileProvider.notifier);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final storage =
      await ref.watch(adaptiveProgressionEvidenceStorageProvider.future);
  return AdaptiveProgressionController(
    capabilityController: capabilityController,
    evidenceStorage: storage,
    readPersistedCapability: () async =>
        CapabilityProfileStorage(prefs).load(),
  );
});

// For tests that need to override controller
final adaptiveProgressionControllerTestProvider =
    Provider<AdaptiveProgressionController>((ref) {
  throw UnimplementedError('Override in tests');
});
