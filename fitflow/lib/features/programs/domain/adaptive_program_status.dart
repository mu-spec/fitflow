import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:flutter/foundation.dart';

/// Factual state of one planned session relative to saved program progress.
enum AdaptiveProgramSessionStatus {
  completed,
  next,
  planned,
}

extension AdaptiveProgramSessionStatusLabel on AdaptiveProgramSessionStatus {
  String get label {
    switch (this) {
      case AdaptiveProgramSessionStatus.completed:
        return 'Completed';
      case AdaptiveProgramSessionStatus.next:
        return 'Next';
      case AdaptiveProgramSessionStatus.planned:
        return 'Planned';
    }
  }
}

/// Pure calculator of program status from an immutable definition and an
/// optional progress record.
///
/// - completed count only counts session IDs that exist in the definition and
///   therefore can never exceed the definition total
/// - `next` is the first incomplete session in ordered structure
/// - no locking, no calendar lateness; the structural "current week" is the
///   week of the next session
@immutable
class AdaptiveProgramStatus {
  AdaptiveProgramStatus({
    required this.definition,
    required this.progress,
  })  : completedSessionIds = Set<String>.unmodifiable(
          progress == null
              ? const <String>{}
              : definition.sessions
                  .where((s) => progress.isSessionCompleted(s.id))
                  .map((s) => s.id),
        ),
        nextSession = _firstIncomplete(definition, progress);

  final AdaptiveProgramDefinition definition;
  final AdaptiveProgramProgress? progress;

  /// Completed planned session IDs that exist in the definition.
  final Set<String> completedSessionIds;

  /// First incomplete session in ordered structure, null when complete.
  final AdaptiveProgramSession? nextSession;

  static AdaptiveProgramSession? _firstIncomplete(
    AdaptiveProgramDefinition definition,
    AdaptiveProgramProgress? progress,
  ) {
    for (final s in definition.sessions) {
      if (progress == null || !progress.isSessionCompleted(s.id)) {
        return s;
      }
    }
    return null;
  }

  bool get hasProgress => progress != null;

  int get completedCount => completedSessionIds.length;

  int get totalCount => definition.totalSessionCount;

  /// True when every current definition session ID is completed.
  bool get isComplete => totalCount > 0 && completedCount >= totalCount;

  /// Structural current week derived from the next incomplete session.
  /// Returns the last week when the program is complete.
  int get currentWeek => nextSession?.week ?? definition.weekCount;

  /// 0..1 completion fraction for progress bars.
  double get completionFraction =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  /// Factual label such as "5 of 12 workouts completed".
  String get completionLabel =>
      '$completedCount of $totalCount workouts completed';

  AdaptiveProgramSessionStatus statusOf(AdaptiveProgramSession session) {
    if (completedSessionIds.contains(session.id)) {
      return AdaptiveProgramSessionStatus.completed;
    }
    if (nextSession?.id == session.id) {
      return AdaptiveProgramSessionStatus.next;
    }
    return AdaptiveProgramSessionStatus.planned;
  }

  AdaptiveProgramSessionStatus statusOfId(String sessionId) {
    final s = definition.sessionById(sessionId);
    if (s == null) return AdaptiveProgramSessionStatus.planned;
    return statusOf(s);
  }
}
