import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Immutable answer for one movement's assessment.
@immutable
class CapabilityAssessmentAnswer {
  const CapabilityAssessmentAnswer({
    required this.movementPattern,
    required this.selectedLevel,
    this.anchorExerciseId,
  });

  final MovementPattern movementPattern;
  final CapabilityLevel selectedLevel;
  final String? anchorExerciseId;

  List<String> validate() {
    final problems = <String>[];
    if (movementPattern == MovementPattern.warmup ||
        movementPattern == MovementPattern.cooldown) {
      problems.add('movementPattern ${movementPattern.name} is not trainable');
    }
    if (anchorExerciseId != null && anchorExerciseId!.trim().isEmpty) {
      problems.add('anchorExerciseId must not be blank when provided');
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  CapabilityAssessmentAnswer copyWith({
    MovementPattern? movementPattern,
    CapabilityLevel? selectedLevel,
    String? anchorExerciseId,
    bool clearAnchor = false,
  }) {
    return CapabilityAssessmentAnswer(
      movementPattern: movementPattern ?? this.movementPattern,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      anchorExerciseId:
          clearAnchor ? null : (anchorExerciseId ?? this.anchorExerciseId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapabilityAssessmentAnswer &&
        other.movementPattern == movementPattern &&
        other.selectedLevel == selectedLevel &&
        other.anchorExerciseId == anchorExerciseId;
  }

  @override
  int get hashCode => Object.hash(
        movementPattern,
        selectedLevel,
        anchorExerciseId,
      );

  @override
  String toString() =>
      'CapabilityAssessmentAnswer(movementPattern: ${movementPattern.name}, selectedLevel: ${selectedLevel.name}, anchorExerciseId: $anchorExerciseId)';

  Map<String, dynamic> toJson() {
    return {
      'movementPattern': movementPattern.name,
      'selectedLevel': selectedLevel.name,
      if (anchorExerciseId != null) 'anchorExerciseId': anchorExerciseId,
    };
  }

  static CapabilityAssessmentAnswer? fromJson(Map<String, dynamic> json) {
    try {
      final patternName = json['movementPattern'] as String?;
      final levelName = json['selectedLevel'] as String?;
      if (patternName == null || levelName == null) {
        return null;
      }

      final pattern = MovementPattern.values
          .where((p) => p.name == patternName)
          .cast<MovementPattern?>()
          .firstWhere((p) => p != null, orElse: () => null);
      if (pattern == null) {
        return null;
      }
      if (pattern == MovementPattern.warmup ||
          pattern == MovementPattern.cooldown) {
        return null;
      }

      final level = CapabilityLevel.values
          .where((l) => l.name == levelName)
          .cast<CapabilityLevel?>()
          .firstWhere((l) => l != null, orElse: () => null);
      if (level == null) {
        return null;
      }

      final anchor = json['anchorExerciseId'] as String?;

      final answer = CapabilityAssessmentAnswer(
        movementPattern: pattern,
        selectedLevel: level,
        anchorExerciseId: anchor,
      );
      if (!answer.isValid) {
        return null;
      }
      return answer;
    } catch (_) {
      return null;
    }
  }
}
