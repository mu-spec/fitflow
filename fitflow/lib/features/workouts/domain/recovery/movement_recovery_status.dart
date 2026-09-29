import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Training-recency categories – neutral, non-medical wording.
enum RecoveryCategory {
  notTrainedRecently,
  trainedRecently,
  resting,
  wellRested,
}

extension RecoveryCategoryLabel on RecoveryCategory {
  String get label {
    switch (this) {
      case RecoveryCategory.notTrainedRecently:
        return 'No recent training';
      case RecoveryCategory.trainedRecently:
        return 'Trained recently';
      case RecoveryCategory.resting:
        return 'Resting';
      case RecoveryCategory.wellRested:
        return 'More rested';
    }
  }

  String get description {
    switch (this) {
      case RecoveryCategory.notTrainedRecently:
        return 'No recent training for this movement in your history.';
      case RecoveryCategory.trainedRecently:
        return 'Trained within last 24 hours.';
      case RecoveryCategory.resting:
        return 'Last trained 24 to 48 hours ago.';
      case RecoveryCategory.wellRested:
        return 'Last trained more than 48 hours ago.';
    }
  }
}

@immutable
class MovementRecoveryStatus {
  const MovementRecoveryStatus({
    required this.movementPattern,
    required this.lastTrained,
    required this.category,
    required this.sessionsLast7Days,
    required this.setsLast7Days,
    required this.hoursSinceLastTrained,
  });

  final MovementPattern movementPattern;
  final DateTime? lastTrained;
  final RecoveryCategory category;
  final int sessionsLast7Days;
  final int setsLast7Days;
  final double? hoursSinceLastTrained;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MovementRecoveryStatus) return false;
    return movementPattern == other.movementPattern &&
        lastTrained == other.lastTrained &&
        category == other.category &&
        sessionsLast7Days == other.sessionsLast7Days &&
        setsLast7Days == other.setsLast7Days &&
        hoursSinceLastTrained == other.hoursSinceLastTrained;
  }

  @override
  int get hashCode => Object.hash(
        movementPattern,
        lastTrained,
        category,
        sessionsLast7Days,
        setsLast7Days,
        hoursSinceLastTrained,
      );

  @override
  String toString() => 'MovementRecoveryStatus(${movementPattern.name} last:$lastTrained cat:${category.name} sessions7:$sessionsLast7Days sets7:$setsLast7Days hours:$hoursSinceLastTrained)';
}
