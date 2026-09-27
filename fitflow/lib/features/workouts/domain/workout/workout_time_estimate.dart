import 'package:flutter/foundation.dart';

/// Immutable time estimate for a prescription or section (5C-2).
///
/// - work: active work time
/// - rest: rest between sets (and transitions handled at section level)
/// - transition: transition between exercises (0 at prescription level)
/// - total: work + rest + transition
///
/// All durations must be non-negative.
@immutable
class WorkoutTimeEstimate {
  const WorkoutTimeEstimate({
    required this.work,
    required this.rest,
    required this.transition,
    required this.total,
  });

  final Duration work;
  final Duration rest;
  final Duration transition;
  final Duration total;

  /// Factory that enforces invariant total = work+rest+transition
  factory WorkoutTimeEstimate.fromComponents({
    required Duration work,
    required Duration rest,
    required Duration transition,
  }) {
    if (work < Duration.zero ||
        rest < Duration.zero ||
        transition < Duration.zero) {
      throw ArgumentError('Durations must be non-negative');
    }
    return WorkoutTimeEstimate(
      work: work,
      rest: rest,
      transition: transition,
      total: work + rest + transition,
    );
  }

  /// Zero estimate (empty section).
  static const zero = WorkoutTimeEstimate(
    work: Duration.zero,
    rest: Duration.zero,
    transition: Duration.zero,
    total: Duration.zero,
  );

  List<String> validate() {
    final problems = <String>[];
    if (work < Duration.zero) {
      problems.add('work must be >= Duration.zero');
    }
    if (rest < Duration.zero) {
      problems.add('rest must be >= Duration.zero');
    }
    if (transition < Duration.zero) {
      problems.add('transition must be >= Duration.zero');
    }
    if (total != work + rest + transition) {
      problems.add('total must equal work + rest + transition');
    }
    if (total < Duration.zero) {
      problems.add('total must be >= Duration.zero');
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutTimeEstimate) return false;
    return work == other.work &&
        rest == other.rest &&
        transition == other.transition &&
        total == other.total;
  }

  @override
  int get hashCode => Object.hash(work, rest, transition, total);

  @override
  String toString() =>
      'WorkoutTimeEstimate(work: $work, rest: $rest, transition: $transition, total: $total)';
}
