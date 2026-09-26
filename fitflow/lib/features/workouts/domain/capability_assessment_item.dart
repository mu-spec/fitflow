import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Immutable metadata/configuration for one movement's assessment.
///
/// Domain configuration only, no UI widgets.
@immutable
class CapabilityAssessmentItem {
  const CapabilityAssessmentItem({
    required this.movementPattern,
    required this.title,
    required this.prompt,
    this.examples = const [],
    this.availableLevels = CapabilityLevel.values,
  });

  final MovementPattern movementPattern;
  final String title;
  final String prompt;
  final List<String> examples;
  final List<CapabilityLevel> availableLevels;

  List<String> validate() {
    final problems = <String>[];
    if (movementPattern == MovementPattern.warmup ||
        movementPattern == MovementPattern.cooldown) {
      problems.add('assessment item must not be warmup/cooldown: ${movementPattern.name}');
    }
    if (title.trim().isEmpty) {
      problems.add('title must not be empty for ${movementPattern.name}');
    }
    if (prompt.trim().isEmpty) {
      problems.add('prompt must not be empty for ${movementPattern.name}');
    }
    if (availableLevels.isEmpty) {
      problems.add('availableLevels must not be empty for ${movementPattern.name}');
    }
    // Ensure availableLevels contains 1..5 (order not critical but should be all)
    if (availableLevels.length != CapabilityLevel.values.length) {
      // Not strictly required to be exactly 5, but for FitFlow we expect 5
      // Allow but warn if not 5? For validation, we require exactly 5 to match spec
      if (availableLevels.length != 5) {
        problems.add('availableLevels should contain 5 levels for ${movementPattern.name}');
      }
    }
    for (final ex in examples) {
      if (ex.trim().isEmpty) {
        problems.add('example must not be empty for ${movementPattern.name}');
      }
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapabilityAssessmentItem &&
        other.movementPattern == movementPattern &&
        other.title == title &&
        other.prompt == prompt &&
        listEquals(other.examples, examples) &&
        listEquals(other.availableLevels, availableLevels);
  }

  @override
  int get hashCode => Object.hash(
        movementPattern,
        title,
        prompt,
        Object.hashAll(examples),
        Object.hashAll(availableLevels),
      );

  @override
  String toString() =>
      'CapabilityAssessmentItem(movementPattern: ${movementPattern.name}, title: $title)';
}
