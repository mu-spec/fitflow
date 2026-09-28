import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

enum MovementProgressionDecisionType {
  promoted,
  reduced,
  unchangedJustRight,
  firstEasySignal,
  easyNotQualified,
  alreadyAtMaximum,
  alreadyAtMinimum,
}

class MovementProgressionDecision {
  const MovementProgressionDecision({
    required this.movementPattern,
    required this.type,
    required this.previousLevel,
    required this.newLevel,
    required this.explanation,
    this.qualifyingExerciseId,
    this.evidenceBefore,
    this.evidenceAfter,
  });

  final MovementPattern movementPattern;
  final MovementProgressionDecisionType type;
  final CapabilityLevel previousLevel;
  final CapabilityLevel newLevel;
  final String explanation;
  final String? qualifyingExerciseId;
  final int? evidenceBefore;
  final int? evidenceAfter;

  bool get didPromote => type == MovementProgressionDecisionType.promoted;
  bool get didReduce => type == MovementProgressionDecisionType.reduced;
  bool get didChangeLevel => previousLevel != newLevel;
}
