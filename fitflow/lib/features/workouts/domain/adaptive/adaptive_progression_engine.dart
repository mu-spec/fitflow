import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_decision.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';

class AdaptiveProgressionInput {
  const AdaptiveProgressionInput({
    required this.currentProfile,
    required this.effectiveMainPrescriptions,
    required this.feedbackByMovement,
    required this.currentEvidence,
    required this.now,
  });

  final CapabilityProfile currentProfile;
  final List<WorkoutExercisePrescription> effectiveMainPrescriptions;
  final Map<MovementPattern, MovementWorkoutFeedback> feedbackByMovement;
  final AdaptiveProgressionEvidence currentEvidence;
  final DateTime now;
}

class AdaptiveProgressionResult {
  const AdaptiveProgressionResult({
    required this.updatedProfile,
    required this.updatedEvidence,
    required this.decisions,
  });

  final CapabilityProfile updatedProfile;
  final AdaptiveProgressionEvidence updatedEvidence;
  final Map<MovementPattern, MovementProgressionDecision> decisions;
}

class AdaptiveProgressionEngine {
  const AdaptiveProgressionEngine._();

  static AdaptiveProgressionResult calculate(AdaptiveProgressionInput input) {
    // Defensive copies, pure function, no mutation of inputs
    var newProfile = input.currentProfile;
    var newEvidence = input.currentEvidence;
    final decisions = <MovementPattern, MovementProgressionDecision>{};

    // Build lookup of effective Main exercises grouped by movement pattern, preserving execution order
    final exercisesByMovement = <MovementPattern, List<WorkoutExercisePrescription>>{};
    for (final pres in input.effectiveMainPrescriptions) {
      final pattern = pres.exercise.movementPattern;
      if (pattern == null) continue;
      if (!CapabilityProfile.trainablePatterns.contains(pattern)) continue;
      exercisesByMovement.putIfAbsent(pattern, () => []).add(pres);
    }

    for (final entry in input.feedbackByMovement.entries) {
      final pattern = entry.key;
      final feedback = entry.value;

      if (!CapabilityProfile.trainablePatterns.contains(pattern)) continue;

      final currentCapability = input.currentProfile.capabilityFor(pattern);
      if (currentCapability == null) continue;

      final effectiveForPattern = exercisesByMovement[pattern] ?? const [];
      if (effectiveForPattern.isEmpty) {
        // Movement not actually performed, treat as not qualified / unchanged
        // We still produce a decision that explains it wasn't performed
        decisions[pattern] = MovementProgressionDecision(
          movementPattern: pattern,
          type: MovementProgressionDecisionType.easyNotQualified,
          previousLevel: currentCapability.level,
          newLevel: currentCapability.level,
          explanation: '${pattern.label} was not performed in Main, so no change.',
          evidenceBefore: input.currentEvidence.countFor(pattern),
          evidenceAfter: input.currentEvidence.countFor(pattern),
        );
        continue;
      }

      final previousLevel = currentCapability.level;
      final evidenceBefore = input.currentEvidence.countFor(pattern);

      switch (feedback) {
        case MovementWorkoutFeedback.justRight:
          // Unchanged, reset evidence to 0
          newEvidence = newEvidence.withCount(pattern, 0);
          decisions[pattern] = MovementProgressionDecision(
            movementPattern: pattern,
            type: MovementProgressionDecisionType.unchangedJustRight,
            previousLevel: previousLevel,
            newLevel: previousLevel,
            explanation: '${pattern.label} stays at ${previousLevel.label}.',
            evidenceBefore: evidenceBefore,
            evidenceAfter: 0,
          );
          // No profile change, preserve metadata
          break;

        case MovementWorkoutFeedback.tooHard:
          // Conservative immediate one-level reduction
          final newLevel = _decrementLevel(previousLevel);
          newEvidence = newEvidence.withCount(pattern, 0);

          if (newLevel == previousLevel) {
            // Already at minimum
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.alreadyAtMinimum,
              previousLevel: previousLevel,
              newLevel: newLevel,
              explanation: '${pattern.label} stays at ${previousLevel.label} (already at minimum).',
              evidenceBefore: evidenceBefore,
              evidenceAfter: 0,
            );
            // No profile change
          } else {
            // Reduce capability with workoutFeedback source
            final anchorId = _firstEffectiveExerciseId(effectiveForPattern);
            final updatedCapability = MovementCapability(
              movementPattern: pattern,
              level: newLevel,
              source: CapabilitySource.workoutFeedback,
              updatedAt: input.now,
              anchorExerciseId: anchorId,
            );
            newProfile = newProfile.withCapability(updatedCapability);
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.reduced,
              previousLevel: previousLevel,
              newLevel: newLevel,
              explanation: '${pattern.label} moved from ${previousLevel.label} to ${newLevel.label} because you marked it Too hard.',
              qualifyingExerciseId: anchorId,
              evidenceBefore: evidenceBefore,
              evidenceAfter: 0,
            );
          }
          break;

        case MovementWorkoutFeedback.easy:
          // Determine qualifying evidence
          final qualifyingExercises = _qualifyingExercisesAtCurrentLevel(
            effectiveForPattern: effectiveForPattern,
            currentLevel: previousLevel,
          );

          final isQualifying = qualifyingExercises.isNotEmpty;

          if (!isQualifying) {
            // Easy not qualified because no exercise at current capability level
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.easyNotQualified,
              previousLevel: previousLevel,
              newLevel: previousLevel,
              explanation:
                  '${pattern.label} stays at ${previousLevel.label} because today\'s effective ${pattern.label.toLowerCase()} work was below your current capability level.',
              evidenceBefore: evidenceBefore,
              evidenceAfter: evidenceBefore, // unchanged
            );
            // Evidence unchanged, profile unchanged
            break;
          }

          // Qualifying Easy
          if (previousLevel == CapabilityLevel.level5) {
            // Already at maximum
            newEvidence = newEvidence.withCount(pattern, 0);
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.alreadyAtMaximum,
              previousLevel: previousLevel,
              newLevel: previousLevel,
              explanation: '${pattern.label} stays at ${previousLevel.label} (already at maximum).',
              evidenceBefore: evidenceBefore,
              evidenceAfter: 0,
            );
            break;
          }

          if (evidenceBefore == 0) {
            // First qualifying Easy
            newEvidence = newEvidence.withCount(pattern, 1);
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.firstEasySignal,
              previousLevel: previousLevel,
              newLevel: previousLevel,
              explanation:
                  '${pattern.label} stays at ${previousLevel.label}. One more Easy session at your current level may progress it.',
              qualifyingExerciseId: _firstExerciseId(qualifyingExercises),
              evidenceBefore: evidenceBefore,
              evidenceAfter: 1,
            );
          } else {
            // Second consecutive qualifying Easy → promote
            final promotedLevel = _incrementLevel(previousLevel);
            final anchorId = _firstExerciseId(qualifyingExercises);
            final updatedCapability = MovementCapability(
              movementPattern: pattern,
              level: promotedLevel,
              source: CapabilitySource.progression,
              updatedAt: input.now,
              anchorExerciseId: anchorId,
            );
            newProfile = newProfile.withCapability(updatedCapability);
            newEvidence = newEvidence.withCount(pattern, 0);
            decisions[pattern] = MovementProgressionDecision(
              movementPattern: pattern,
              type: MovementProgressionDecisionType.promoted,
              previousLevel: previousLevel,
              newLevel: promotedLevel,
              explanation:
                  '${pattern.label} moved from ${previousLevel.label} to ${promotedLevel.label} after two Easy sessions at your current level.',
              qualifyingExerciseId: anchorId,
              evidenceBefore: evidenceBefore,
              evidenceAfter: 0,
            );
          }
          break;
      }
    }

    return AdaptiveProgressionResult(
      updatedProfile: newProfile,
      updatedEvidence: newEvidence,
      decisions: Map.unmodifiable(decisions),
    );
  }

  static List<WorkoutExercisePrescription> _qualifyingExercisesAtCurrentLevel({
    required List<WorkoutExercisePrescription> effectiveForPattern,
    required CapabilityLevel currentLevel,
  }) {
    final targetDifficulty = currentLevel.toExerciseDifficulty();
    final qualifying = <WorkoutExercisePrescription>[];
    for (final pres in effectiveForPattern) {
      if (pres.exercise.difficulty == targetDifficulty) {
        qualifying.add(pres);
      }
    }
    return qualifying;
  }

  static String? _firstEffectiveExerciseId(List<WorkoutExercisePrescription> list) {
    if (list.isEmpty) return null;
    return list.first.exercise.id;
  }

  static String? _firstExerciseId(List<WorkoutExercisePrescription> list) {
    if (list.isEmpty) return null;
    return list.first.exercise.id;
  }

  static CapabilityLevel _incrementLevel(CapabilityLevel level) {
    switch (level) {
      case CapabilityLevel.level1:
        return CapabilityLevel.level2;
      case CapabilityLevel.level2:
        return CapabilityLevel.level3;
      case CapabilityLevel.level3:
        return CapabilityLevel.level4;
      case CapabilityLevel.level4:
        return CapabilityLevel.level5;
      case CapabilityLevel.level5:
        return CapabilityLevel.level5;
    }
  }

  static CapabilityLevel _decrementLevel(CapabilityLevel level) {
    switch (level) {
      case CapabilityLevel.level1:
        return CapabilityLevel.level1;
      case CapabilityLevel.level2:
        return CapabilityLevel.level1;
      case CapabilityLevel.level3:
        return CapabilityLevel.level2;
      case CapabilityLevel.level4:
        return CapabilityLevel.level3;
      case CapabilityLevel.level5:
        return CapabilityLevel.level4;
    }
  }
}

// MovementPattern already has label, no extra extension needed

