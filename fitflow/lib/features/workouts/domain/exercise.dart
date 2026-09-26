import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter/foundation.dart';

/// An immutable exercise definition.
///
/// Exercises are data only — no behaviour beyond lightweight validation.
/// No dataset is defined yet: this milestone ships the schema only.
@immutable
class Exercise {
  Exercise({
    required this.id,
    required this.name,
    this.shortDescription,
    Set<MuscleGroup>? primaryMuscles,
    Set<MuscleGroup>? secondaryMuscles,
    this.movementPattern,
    required this.difficulty,
    Set<WorkoutEquipment>? requiredEquipment,
    this.bodyPosition,
    required this.impactLevel,
    required this.noiseLevel,
    required this.spaceRequirement,
    required this.wristLoad,
    required this.kneeLoad,
    required this.exerciseType,
    this.defaultReps,
    this.defaultDuration,
    this.defaultRest,
    this.progressionFamilyId,
    this.progressionRank = 0,
    this.easierVariationId,
    this.harderVariationId,
    List<String>? instructions,
    List<String>? commonMistakes,
    this.breathingGuidance,
    Set<String>? tags,
    this.assetPath,
    this.active = true,
  })  : primaryMuscles = Set.unmodifiable(primaryMuscles ?? const {}),
        secondaryMuscles = Set.unmodifiable(secondaryMuscles ?? const {}),
        requiredEquipment = Set.unmodifiable(requiredEquipment ?? const {}),
        instructions = List.unmodifiable(instructions ?? const []),
        commonMistakes = List.unmodifiable(commonMistakes ?? const []),
        tags = Set.unmodifiable(tags ?? const {});

  /// Stable identifier, e.g. `pushup_standard`.
  final String id;

  /// Display name.
  final String name;

  /// Short description.
  final String? shortDescription;

  /// Primary muscle groups trained.
  final Set<MuscleGroup> primaryMuscles;

  /// Secondary muscle groups trained.
  final Set<MuscleGroup> secondaryMuscles;

  /// Broad movement category, when applicable.
  final MovementPattern? movementPattern;

  /// Difficulty rating.
  final ExerciseDifficulty difficulty;

  /// Equipment required to perform the exercise.
  final Set<WorkoutEquipment> requiredEquipment;

  /// Body position, when applicable.
  final ExercisePosition? bodyPosition;

  /// Impact intensity.
  final ImpactLevel impactLevel;

  /// Typical noise produced.
  final NoiseLevel noiseLevel;

  /// Floor space needed.
  final SpaceRequirement spaceRequirement;

  /// Load placed on the wrists.
  final JointLoad wristLoad;

  /// Load placed on the knees.
  final JointLoad kneeLoad;

  /// Whether the exercise is measured in reps or time.
  final ExerciseType exerciseType;

  /// Default repetition count for [ExerciseType.reps] exercises.
  final int? defaultReps;

  /// Default duration for [ExerciseType.timed] exercises.
  final Duration? defaultDuration;

  /// Default rest between sets.
  final Duration? defaultRest;

  /// Identifies the progression family this exercise belongs to, e.g.
  /// `pushup`. Exercises sharing a family form a progression ladder.
  final String? progressionFamilyId;

  /// Position in the progression ladder. Must not be negative.
  final int progressionRank;

  /// ID of the easier variation, when one exists.
  final String? easierVariationId;

  /// ID of the harder variation, when one exists.
  final String? harderVariationId;

  /// Step-by-step instructions.
  final List<String> instructions;

  /// Common mistakes to avoid.
  final List<String> commonMistakes;

  /// Breathing guidance.
  final String? breathingGuidance;

  /// Free-form tags.
  final Set<String> tags;

  /// Path to a demonstration asset, when available.
  final String? assetPath;

  /// Whether the exercise is currently available.
  final bool active;

  /// Lightweight validation. Returns human-readable problems; empty when the
  /// exercise is valid.
  List<String> validate() {
    final problems = <String>[];
    if (id.trim().isEmpty) {
      problems.add('id must not be empty');
    }
    if (name.trim().isEmpty) {
      problems.add('name must not be empty');
    }
    if (progressionRank < 0) {
      problems.add('progressionRank must not be negative');
    }
    if (exerciseType == ExerciseType.reps &&
        (defaultReps == null || defaultReps! <= 0)) {
      problems.add('a reps exercise requires a positive defaultReps');
    }
    if (exerciseType == ExerciseType.timed &&
        (defaultDuration == null || defaultDuration! <= Duration.zero)) {
      problems.add('a timed exercise requires a positive defaultDuration');
    }
    return problems;
  }

  /// Whether this exercise passes [validate].
  bool get isValid => validate().isEmpty;
}
