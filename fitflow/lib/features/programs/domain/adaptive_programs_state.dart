import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:flutter/foundation.dart';

/// Immutable root state for adaptive programs.
///
/// - exactly one (or no) active program
/// - progress retained for every program that was ever started
@immutable
class AdaptiveProgramsState {
  AdaptiveProgramsState({
    this.activeProgramId,
    Map<String, AdaptiveProgramProgress> progressByProgram = const {},
  }) : progressByProgram =
            Map<String, AdaptiveProgramProgress>.unmodifiable(progressByProgram);

  /// Safe empty state.
  static final AdaptiveProgramsState empty = AdaptiveProgramsState();

  final String? activeProgramId;

  /// Unmodifiable progress keyed by program ID.
  final Map<String, AdaptiveProgramProgress> progressByProgram;

  AdaptiveProgramProgress? progressFor(String programId) =>
      progressByProgram[programId];

  bool hasProgress(String programId) => progressByProgram.containsKey(programId);

  bool isActive(String programId) => activeProgramId == programId;

  /// Progress of the active program, if any.
  AdaptiveProgramProgress? get activeProgress {
    final id = activeProgramId;
    if (id == null) return null;
    return progressByProgram[id];
  }

  /// Deterministic ordered program IDs with progress (sorted).
  List<String> get startedProgramIds {
    final ids = progressByProgram.keys.toList()..sort();
    return List<String>.unmodifiable(ids);
  }

  AdaptiveProgramsState copyWith({
    String? activeProgramId,
    bool clearActive = false,
    Map<String, AdaptiveProgramProgress>? progressByProgram,
  }) {
    return AdaptiveProgramsState(
      activeProgramId:
          clearActive ? null : (activeProgramId ?? this.activeProgramId),
      progressByProgram: progressByProgram ?? this.progressByProgram,
    );
  }

  /// Returns a new state with [progress] stored under its program ID.
  AdaptiveProgramsState withProgress(AdaptiveProgramProgress progress) {
    final map = Map<String, AdaptiveProgramProgress>.from(progressByProgram);
    map[progress.programId] = progress;
    return copyWith(progressByProgram: map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveProgramsState &&
        other.activeProgramId == activeProgramId &&
        mapEquals(other.progressByProgram, progressByProgram);
  }

  @override
  int get hashCode => Object.hash(
        activeProgramId,
        Object.hashAll(
          progressByProgram.entries
              .map((e) => Object.hash(e.key, e.value))
              .toList()
            ..sort(),
        ),
      );

  @override
  String toString() =>
      'AdaptiveProgramsState(active: $activeProgramId, started: ${progressByProgram.keys.toList()..sort()})';
}
