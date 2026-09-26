import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_answer.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Immutable state representing user's current assessment answers.
///
/// Holds one answer per movement, tracks completeness, supports immutable updates.
@immutable
class CapabilityAssessmentState {
  const CapabilityAssessmentState._(
      Map<MovementPattern, CapabilityAssessmentAnswer> answers)
      : _answers = answers;

  final Map<MovementPattern, CapabilityAssessmentAnswer> _answers;

  /// Unmodifiable view of answers.
  Map<MovementPattern, CapabilityAssessmentAnswer> get answers =>
      Map.unmodifiable(_answers);

  List<CapabilityAssessmentAnswer> get allAnswers =>
      List.unmodifiable(_answers.values);

  static const int totalCount = 10;

  int get answeredCount => _answers.length;

  bool get isComplete {
    if (_answers.length != totalCount) return false;
    for (final pattern in CapabilityProfile.trainablePatterns) {
      final ans = _answers[pattern];
      if (ans == null) return false;
      if (!ans.isValid) return false;
    }
    return true;
  }

  bool get isEmpty => _answers.isEmpty;

  /// Returns answer for given pattern, or null.
  CapabilityAssessmentAnswer? answerFor(MovementPattern pattern) {
    if (!_isTrainable(pattern)) {
      return null;
    }
    return _answers[pattern];
  }

  CapabilityAssessmentAnswer? operator [](MovementPattern pattern) =>
      answerFor(pattern);

  static bool _isTrainable(MovementPattern pattern) {
    return CapabilityProfile.trainablePatterns.contains(pattern);
  }

  /// Validation similar to other domain models.
  List<String> validate() {
    final problems = <String>[];
    if (_answers.length > totalCount) {
      problems.add('answers must not exceed $totalCount, found ${_answers.length}');
    }
    for (final entry in _answers.entries) {
      if (!_isTrainable(entry.key)) {
        problems.add('unsupported pattern ${entry.key.name}');
      }
      if (entry.value.movementPattern != entry.key) {
        problems.add(
            'key ${entry.key.name} mismatches answer movementPattern ${entry.value.movementPattern.name}');
      }
      problems.addAll(entry.value.validate().map((p) => '${entry.key.name}: $p'));
    }
    // Check duplicates not possible via map, but ensure uniqueness already via map keys
    return problems;
  }

  bool get isValid => validate().isEmpty;

  /// Immutable update: add or replace answer for one movement.
  CapabilityAssessmentState withAnswer(
      CapabilityAssessmentAnswer answer) {
    if (!_isTrainable(answer.movementPattern)) {
      // Invalid pattern, return self unchanged, no crash
      return this;
    }
    if (!answer.isValid) {
      // Invalid answer, return self unchanged
      return this;
    }
    final newMap =
        Map<MovementPattern, CapabilityAssessmentAnswer>.from(_answers);
    newMap[answer.movementPattern] = answer;
    return CapabilityAssessmentState._(Map.unmodifiable(newMap));
  }

  /// Remove answer for pattern (for reset scenarios).
  CapabilityAssessmentState withoutAnswer(MovementPattern pattern) {
    if (!_answers.containsKey(pattern)) return this;
    final newMap =
        Map<MovementPattern, CapabilityAssessmentAnswer>.from(_answers);
    newMap.remove(pattern);
    return CapabilityAssessmentState._(Map.unmodifiable(newMap));
  }

  /// Empty state factory.
  factory CapabilityAssessmentState.empty() {
    return CapabilityAssessmentState._(
        Map.unmodifiable(<MovementPattern, CapabilityAssessmentAnswer>{}));
  }

  /// Suggested mapping from onboarding ExperienceLevel to CapabilityLevel.
  ///
  /// completelyNew → Level1
  /// someExperience → Level2
  /// regularTraining → Level3
  /// experienced → Level4
  /// Never suggests Level5 automatically.
  static CapabilityLevel _suggestedLevelForExperience(
      ExperienceLevel experience) {
    switch (experience) {
      case ExperienceLevel.completelyNew:
        return CapabilityLevel.level1;
      case ExperienceLevel.someExperience:
        return CapabilityLevel.level2;
      case ExperienceLevel.regularTraining:
        return CapabilityLevel.level3;
      case ExperienceLevel.experienced:
        return CapabilityLevel.level4;
    }
  }

  /// Creates initial suggested answers for all 10 movements using ExperienceLevel mapping.
  ///
  /// All movements get same suggested level initially, but user can later change each independently.
  factory CapabilityAssessmentState.fromExperienceLevel(
      ExperienceLevel experience) {
    final suggested = _suggestedLevelForExperience(experience);
    final map = <MovementPattern, CapabilityAssessmentAnswer>{};
    for (final pattern in CapabilityProfile.trainablePatterns) {
      map[pattern] = CapabilityAssessmentAnswer(
        movementPattern: pattern,
        selectedLevel: suggested,
      );
    }
    return CapabilityAssessmentState._(Map.unmodifiable(map));
  }

  /// Reset to unanswered (empty).
  CapabilityAssessmentState resetToUnanswered() {
    return CapabilityAssessmentState.empty();
  }

  /// Reset to suggested values from ExperienceLevel.
  CapabilityAssessmentState resetToSuggested(
      ExperienceLevel experience) {
    return CapabilityAssessmentState.fromExperienceLevel(experience);
  }

  /// Deterministic conversion to CapabilityProfile.
  ///
  /// Only succeeds for complete valid assessment, otherwise returns null (does not fabricate).
  CapabilityProfile? toCapabilityProfile({required DateTime updatedAt}) {
    if (!isComplete) {
      return null;
    }
    if (!isValid) {
      return null;
    }

    final map = <MovementPattern, MovementCapability>{};
    for (final pattern in CapabilityProfile.trainablePatterns) {
      final answer = _answers[pattern];
      if (answer == null) {
        return null; // Should not happen if isComplete, but safe
      }
      map[pattern] = MovementCapability(
        movementPattern: pattern,
        level: answer.selectedLevel,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
        anchorExerciseId: answer.anchorExerciseId,
      );
    }

    final profile = CapabilityProfile.fromMap(map);
    // Ensure profile is complete and valid
    if (!profile.isComplete || !profile.isValid) {
      return null;
    }
    return profile;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CapabilityAssessmentState) return false;
    if (_answers.length != other._answers.length) return false;
    for (final key in _answers.keys) {
      if (_answers[key] != other._answers[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (final pattern in CapabilityProfile.trainablePatterns) {
      hash = hash ^ (_answers[pattern]?.hashCode ?? 0);
    }
    return hash;
  }

  @override
  String toString() {
    final entries = _answers.entries
        .map((e) => '${e.key.name}=${e.value.selectedLevel.name}')
        .join(', ');
    return 'CapabilityAssessmentState($entries)';
  }
}
