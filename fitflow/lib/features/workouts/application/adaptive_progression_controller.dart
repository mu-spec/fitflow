import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_engine.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of applying feedback, including success/failure.
class AdaptiveProgressionApplyResult {
  const AdaptiveProgressionApplyResult({
    required this.success,
    this.engineResult,
    this.errorMessage,
  });

  final bool success;
  final AdaptiveProgressionResult? engineResult;
  final String? errorMessage;
}

class AdaptiveProgressionController {
  AdaptiveProgressionController({
    required this.capabilityController,
    required this.evidenceStorage,
  });

  final CapabilityProfileController capabilityController;
  final AdaptiveProgressionEvidenceStorage evidenceStorage;

  /// Factory that creates controller with real SharedPreferences.
  static Future<AdaptiveProgressionController> createWithRealStorage({
    required CapabilityProfileController capabilityController,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return AdaptiveProgressionController(
      capabilityController: capabilityController,
      evidenceStorage: AdaptiveProgressionEvidenceStorage(prefs),
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

  /// Applies feedback with conservative persistence ordering.
  Future<AdaptiveProgressionApplyResult> applyFeedback({
    required CapabilityProfile currentProfile,
    required List<WorkoutExercisePrescription> effectiveMainPrescriptions,
    required Map<MovementPattern, MovementWorkoutFeedback> feedbackByMovement,
    required DateTime now,
  }) async {
    try {
      final currentEvidence = evidenceStorage.load();

      final engineResult = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: currentProfile,
          effectiveMainPrescriptions: effectiveMainPrescriptions,
          feedbackByMovement: feedbackByMovement,
          currentEvidence: currentEvidence,
          now: now,
        ),
      );

      final willChangeCapability = engineResult.updatedProfile != currentProfile;
      final willChangeEvidence = engineResult.updatedEvidence != currentEvidence;

      if (!willChangeCapability && !willChangeEvidence) {
        return AdaptiveProgressionApplyResult(
          success: true,
          engineResult: engineResult,
        );
      }

      if (!willChangeCapability) {
        final saved = await evidenceStorage.save(engineResult.updatedEvidence);
        if (!saved) {
          return const AdaptiveProgressionApplyResult(
            success: false,
            errorMessage: "Couldn't update your workout tuning. Try again.",
          );
        }
        return AdaptiveProgressionApplyResult(
          success: true,
          engineResult: engineResult,
        );
      }

      // Capability will change – conservative ordering: evidence first
      final evidenceSaved = await evidenceStorage.save(engineResult.updatedEvidence);
      if (!evidenceSaved) {
        return const AdaptiveProgressionApplyResult(
          success: false,
          errorMessage: "Couldn't update your workout tuning. Try again.",
        );
      }

      final capabilitySaved = await capabilityController.saveProfile(engineResult.updatedProfile);
      if (!capabilitySaved) {
        return const AdaptiveProgressionApplyResult(
          success: false,
          errorMessage: "Couldn't update your workout tuning. Try again.",
        );
      }

      return AdaptiveProgressionApplyResult(
        success: true,
        engineResult: engineResult,
      );
    } catch (_) {
      return const AdaptiveProgressionApplyResult(
        success: false,
        errorMessage: "Couldn't update your workout tuning. Try again.",
      );
    }
  }
}

final adaptiveProgressionControllerProvider = Provider<AdaptiveProgressionController>((ref) {
  throw UnimplementedError('Override adaptiveProgressionControllerProvider in tests or via FutureProvider');
});

final adaptiveProgressionEvidenceStorageProvider = FutureProvider<AdaptiveProgressionEvidenceStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AdaptiveProgressionEvidenceStorage(prefs);
});

final adaptiveProgressionControllerAsyncProvider = FutureProvider<AdaptiveProgressionController>((ref) async {
  final capabilityController = ref.read(capabilityProfileProvider.notifier);
  final storage = await ref.watch(adaptiveProgressionEvidenceStorageProvider.future);
  return AdaptiveProgressionController(
    capabilityController: capabilityController,
    evidenceStorage: storage,
  );
});

// For tests that need to override controller
final adaptiveProgressionControllerTestProvider = Provider<AdaptiveProgressionController>((ref) {
  throw UnimplementedError('Override in tests');
});
