import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:flutter/foundation.dart';

/// One planned session inside an adaptive program.
///
/// A session never stores exercise IDs. It only carries the structural
/// position (week/session), a short focus label and the [FitnessGoal] that is
/// used as a temporary generation goal when the workout is generated from the
/// user's CURRENT profile and capability.
@immutable
class AdaptiveProgramSession {
  const AdaptiveProgramSession({
    required this.id,
    required this.programId,
    required this.week,
    required this.session,
    required this.focus,
    required this.generationGoal,
  });

  /// Deterministic, globally unique ID: `<programId>_w<week>_s<session>`.
  final String id;

  final String programId;

  /// 1-based week number.
  final int week;

  /// 1-based session number within the week.
  final int session;

  /// Short human readable focus, e.g. "Strength".
  final String focus;

  /// Goal used ONLY for generating this session's workout.
  final FitnessGoal generationGoal;

  /// Structural title, e.g. "Week 2 • Session 1".
  String get title => 'Week $week • Session $session';

  /// Builds the deterministic session ID.
  static String buildId(String programId, int week, int session) =>
      '${programId}_w${week}_s$session';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramSession &&
        other.id == id &&
        other.programId == programId &&
        other.week == week &&
        other.session == session &&
        other.focus == focus &&
        other.generationGoal == generationGoal;
  }

  @override
  int get hashCode =>
      Object.hash(id, programId, week, session, focus, generationGoal);

  @override
  String toString() => 'AdaptiveProgramSession($id, $focus, ${generationGoal.name})';
}

/// One week of an adaptive program, holding its ordered sessions.
@immutable
class AdaptiveProgramWeek {
  AdaptiveProgramWeek({
    required this.number,
    required List<AdaptiveProgramSession> sessions,
  }) : sessions = List<AdaptiveProgramSession>.unmodifiable(sessions);

  /// 1-based week number.
  final int number;

  /// Ordered, unmodifiable sessions of this week.
  final List<AdaptiveProgramSession> sessions;

  int get sessionCount => sessions.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramWeek &&
        other.number == number &&
        listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode => Object.hash(number, Object.hashAll(sessions));
}

/// A slot template that repeats every week: focus label + generation goal.
@immutable
class AdaptiveProgramSessionTemplate {
  const AdaptiveProgramSessionTemplate({
    required this.focus,
    required this.generationGoal,
  });

  final String focus;
  final FitnessGoal generationGoal;
}

/// Immutable built-in adaptive program definition.
///
/// Programs are NOT saved workout plans. They describe an ordered structure of
/// weeks and sessions; every workout is generated later from the user's
/// current profile and capability via the existing `WorkoutGenerator`.
@immutable
class AdaptiveProgramDefinition {
  AdaptiveProgramDefinition._({
    required this.id,
    required this.name,
    required this.description,
    required this.focus,
    required this.weekCount,
    required this.sessionsPerWeek,
    required List<AdaptiveProgramSessionTemplate> weeklyTemplate,
    required Set<FitnessGoal> recommendedFor,
    required List<AdaptiveProgramWeek> weeks,
  })  : weeklyTemplate =
            List<AdaptiveProgramSessionTemplate>.unmodifiable(weeklyTemplate),
        recommendedFor = Set<FitnessGoal>.unmodifiable(recommendedFor),
        weeks = List<AdaptiveProgramWeek>.unmodifiable(weeks),
        sessions = List<AdaptiveProgramSession>.unmodifiable(
          weeks.expand((w) => w.sessions),
        );

  /// Builds a definition by repeating [weeklyTemplate] for [weekCount] weeks.
  factory AdaptiveProgramDefinition.build({
    required String id,
    required String name,
    required String description,
    required String focus,
    required int weekCount,
    required List<AdaptiveProgramSessionTemplate> weeklyTemplate,
    required Set<FitnessGoal> recommendedFor,
  }) {
    if (weekCount < 1) {
      throw ArgumentError.value(weekCount, 'weekCount', 'must be >= 1');
    }
    if (weeklyTemplate.isEmpty) {
      throw ArgumentError.value(
          weeklyTemplate, 'weeklyTemplate', 'must not be empty');
    }
    final weeks = <AdaptiveProgramWeek>[];
    for (var w = 1; w <= weekCount; w++) {
      final sessions = <AdaptiveProgramSession>[];
      for (var s = 1; s <= weeklyTemplate.length; s++) {
        final template = weeklyTemplate[s - 1];
        sessions.add(
          AdaptiveProgramSession(
            id: AdaptiveProgramSession.buildId(id, w, s),
            programId: id,
            week: w,
            session: s,
            focus: template.focus,
            generationGoal: template.generationGoal,
          ),
        );
      }
      weeks.add(AdaptiveProgramWeek(number: w, sessions: sessions));
    }
    return AdaptiveProgramDefinition._(
      id: id,
      name: name,
      description: description,
      focus: focus,
      weekCount: weekCount,
      sessionsPerWeek: weeklyTemplate.length,
      weeklyTemplate: weeklyTemplate,
      recommendedFor: recommendedFor,
      weeks: weeks,
    );
  }

  final String id;
  final String name;
  final String description;

  /// Short program focus shown on cards, e.g. "Full-body basics".
  final String focus;

  final int weekCount;
  final int sessionsPerWeek;

  /// Repeating weekly slot template (focus + generation goal per session).
  final List<AdaptiveProgramSessionTemplate> weeklyTemplate;

  /// Goals for which the recommendation policy points to this program.
  final Set<FitnessGoal> recommendedFor;

  /// Ordered, unmodifiable weeks.
  final List<AdaptiveProgramWeek> weeks;

  /// Flattened ordered, unmodifiable sessions (week-major).
  final List<AdaptiveProgramSession> sessions;

  int get totalSessionCount => sessions.length;

  /// Ordered generation goals of one week.
  List<FitnessGoal> get weeklyGoals => List<FitnessGoal>.unmodifiable(
        weeklyTemplate.map((t) => t.generationGoal),
      );

  /// Returns the session with [sessionId] or null when it is not part of
  /// this program.
  AdaptiveProgramSession? sessionById(String sessionId) {
    for (final s in sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }

  bool containsSession(String sessionId) => sessionById(sessionId) != null;

  /// Zero-based ordered index of [sessionId], or -1.
  int indexOfSession(String sessionId) {
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].id == sessionId) return i;
    }
    return -1;
  }

  /// Structural validation problems (empty when valid).
  List<String> validate() {
    final problems = <String>[];
    if (id.trim().isEmpty) problems.add('id must not be empty');
    if (name.trim().isEmpty) problems.add('name must not be empty');
    if (weekCount != weeks.length) {
      problems.add('weekCount $weekCount != weeks.length ${weeks.length}');
    }
    final seen = <String>{};
    for (var w = 0; w < weeks.length; w++) {
      final week = weeks[w];
      if (week.number != w + 1) {
        problems.add('week ${week.number} at index $w is not sequential');
      }
      if (week.sessionCount != sessionsPerWeek) {
        problems.add(
            'week ${week.number} has ${week.sessionCount} sessions, expected $sessionsPerWeek');
      }
      for (var s = 0; s < week.sessions.length; s++) {
        final session = week.sessions[s];
        if (session.programId != id) {
          problems.add('session ${session.id} belongs to ${session.programId}');
        }
        if (session.week != week.number) {
          problems.add('session ${session.id} week mismatch');
        }
        if (session.session != s + 1) {
          problems.add('session ${session.id} number is not sequential');
        }
        if (session.id !=
            AdaptiveProgramSession.buildId(id, week.number, s + 1)) {
          problems.add('session ${session.id} id is not deterministic');
        }
        if (!seen.add(session.id)) {
          problems.add('duplicate session id ${session.id}');
        }
        if (session.focus.trim().isEmpty) {
          problems.add('session ${session.id} focus is empty');
        }
        if (!FitnessGoal.values.contains(session.generationGoal)) {
          problems.add('session ${session.id} has invalid goal');
        }
      }
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramDefinition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AdaptiveProgramDefinition($id, $weekCount weeks x $sessionsPerWeek)';
}
