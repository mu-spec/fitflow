import 'package:flutter/foundation.dart';

/// Factual record: one planned program session completed by one Player
/// session.
@immutable
class AdaptiveProgramSessionCompletion {
  const AdaptiveProgramSessionCompletion({
    required this.plannedSessionId,
    required this.playerSessionId,
    required this.completedAt,
  });

  /// The program's planned session ID (e.g. `balanced_foundations_w1_s1`).
  final String plannedSessionId;

  /// The Player session ID that completed it (matches M11 history ID).
  final String playerSessionId;

  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'plannedSessionId': plannedSessionId,
        'playerSessionId': playerSessionId,
        'completedAt': completedAt.toUtc().toIso8601String(),
      };

  /// Returns null when [json] is malformed.
  static AdaptiveProgramSessionCompletion? fromJson(Map<String, dynamic> json) {
    final planned = json['plannedSessionId'];
    final player = json['playerSessionId'];
    final completedAtRaw = json['completedAt'];
    if (planned is! String || planned.isEmpty) return null;
    if (player is! String || player.isEmpty) return null;
    if (completedAtRaw is! String) return null;
    final completedAt = DateTime.tryParse(completedAtRaw);
    if (completedAt == null) return null;
    return AdaptiveProgramSessionCompletion(
      plannedSessionId: planned,
      playerSessionId: player,
      completedAt: completedAt.toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramSessionCompletion &&
        other.plannedSessionId == plannedSessionId &&
        other.playerSessionId == playerSessionId &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(plannedSessionId, playerSessionId, completedAt);
}

/// Persistent, factual completion progress for one program.
///
/// Holds only what happened: when the program was started, when it was last
/// updated and which planned sessions were completed. It does not hold
/// generated plans.
@immutable
class AdaptiveProgramProgress {
  AdaptiveProgramProgress({
    required this.programId,
    required this.startedAt,
    required this.updatedAt,
    List<AdaptiveProgramSessionCompletion> completions = const [],
  }) : completions =
            List<AdaptiveProgramSessionCompletion>.unmodifiable(_dedupe(completions));

  /// Fresh progress with zero completions.
  factory AdaptiveProgramProgress.fresh({
    required String programId,
    required DateTime startedAt,
  }) {
    return AdaptiveProgramProgress(
      programId: programId,
      startedAt: startedAt.toUtc(),
      updatedAt: startedAt.toUtc(),
    );
  }

  final String programId;
  final DateTime startedAt;
  final DateTime updatedAt;

  /// Unmodifiable, de-duplicated completions in insertion order.
  final List<AdaptiveProgramSessionCompletion> completions;

  /// Deterministic de-duplication: a planned session counts once, and a
  /// Player session counts once. First occurrence wins.
  static List<AdaptiveProgramSessionCompletion> _dedupe(
      List<AdaptiveProgramSessionCompletion> input) {
    final planned = <String>{};
    final players = <String>{};
    final out = <AdaptiveProgramSessionCompletion>[];
    for (final c in input) {
      if (planned.contains(c.plannedSessionId)) continue;
      if (players.contains(c.playerSessionId)) continue;
      planned.add(c.plannedSessionId);
      players.add(c.playerSessionId);
      out.add(c);
    }
    return out;
  }

  /// Set of completed planned session IDs (unmodifiable).
  Set<String> get completedSessionIds =>
      Set<String>.unmodifiable(completions.map((c) => c.plannedSessionId));

  bool isSessionCompleted(String plannedSessionId) =>
      completions.any((c) => c.plannedSessionId == plannedSessionId);

  bool hasPlayerSession(String playerSessionId) =>
      completions.any((c) => c.playerSessionId == playerSessionId);

  /// Whether adding [completion] would change this progress.
  bool wouldAccept(AdaptiveProgramSessionCompletion completion) {
    return !isSessionCompleted(completion.plannedSessionId) &&
        !hasPlayerSession(completion.playerSessionId);
  }

  /// Returns a new progress with [completion] added, or `this` when it is a
  /// duplicate (idempotent).
  AdaptiveProgramProgress withCompletion(
      AdaptiveProgramSessionCompletion completion) {
    if (!wouldAccept(completion)) return this;
    return AdaptiveProgramProgress(
      programId: programId,
      startedAt: startedAt,
      updatedAt: completion.completedAt.toUtc(),
      completions: [...completions, completion],
    );
  }

  Map<String, dynamic> toJson() => {
        'programId': programId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'completions': completions.map((c) => c.toJson()).toList(),
      };

  /// Returns null when [json] is malformed. Malformed completion entries are
  /// skipped individually.
  static AdaptiveProgramProgress? fromJson(Map<String, dynamic> json) {
    final programId = json['programId'];
    final startedRaw = json['startedAt'];
    final updatedRaw = json['updatedAt'];
    if (programId is! String || programId.isEmpty) return null;
    if (startedRaw is! String) return null;
    final startedAt = DateTime.tryParse(startedRaw);
    if (startedAt == null) return null;
    final updatedAt =
        updatedRaw is String ? DateTime.tryParse(updatedRaw) : null;

    final completions = <AdaptiveProgramSessionCompletion>[];
    final rawCompletions = json['completions'];
    if (rawCompletions is List) {
      for (final item in rawCompletions) {
        if (item is! Map) continue;
        try {
          final c = AdaptiveProgramSessionCompletion.fromJson(
              Map<String, dynamic>.from(item));
          if (c != null) completions.add(c);
        } catch (_) {
          continue;
        }
      }
    }

    return AdaptiveProgramProgress(
      programId: programId,
      startedAt: startedAt.toUtc(),
      updatedAt: (updatedAt ?? startedAt).toUtc(),
      completions: completions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramProgress &&
        other.programId == programId &&
        other.startedAt == startedAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.completions, completions);
  }

  @override
  int get hashCode =>
      Object.hash(programId, startedAt, updatedAt, Object.hashAll(completions));

  @override
  String toString() =>
      'AdaptiveProgramProgress($programId, ${completions.length} completions)';
}
