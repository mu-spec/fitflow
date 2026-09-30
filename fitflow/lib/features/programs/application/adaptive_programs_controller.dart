import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adaptiveProgramsStorageProvider = Provider<AdaptiveProgramsStorage>((ref) {
  return const AdaptiveProgramsStorage();
});

/// Injectable clock so tests can pin timestamps.
final adaptiveProgramsClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

final adaptiveProgramsControllerProvider = StateNotifierProvider<
    AdaptiveProgramsController, AsyncValue<AdaptiveProgramsState>>((ref) {
  final storage = ref.watch(adaptiveProgramsStorageProvider);
  final clock = ref.watch(adaptiveProgramsClockProvider);
  return AdaptiveProgramsController(storage, clock: clock);
});

/// Riverpod controller for adaptive program state.
///
/// Responsibilities: load, start/resume, switch active, restart, mark session
/// completion (exactly-once; Player wiring arrives in Part 2), and read-only
/// status helpers.
///
/// Every mutating method persists first and only replaces state on success;
/// on persistence failure the previous successful state is preserved and the
/// method returns `false`.
class AdaptiveProgramsController
    extends StateNotifier<AsyncValue<AdaptiveProgramsState>> {
  AdaptiveProgramsController(
    this._storage, {
    DateTime Function()? clock,
  })  : _clock = clock ?? (() => DateTime.now().toUtc()),
        super(const AsyncValue.loading()) {
    _load();
  }

  final AdaptiveProgramsStorage _storage;
  final DateTime Function() _clock;

  Future<void> _load() async {
    try {
      final loaded = await _storage.load();
      if (!mounted) return;
      state = AsyncValue.data(loaded);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  /// Current successful state or the empty state.
  AdaptiveProgramsState get current =>
      state.value ?? AdaptiveProgramsState.empty;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<bool> _commit(AdaptiveProgramsState next) async {
    try {
      final ok = await _storage.save(next);
      if (!ok) return false;
      if (!mounted) return false;
      state = AsyncValue.data(next);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Starts [programId] fresh when it has no progress, or resumes it when it
  /// does. In both cases it becomes the single active program. Progress of
  /// any previously active program is kept.
  Future<bool> startOrResumeProgram(String programId, {DateTime? now}) async {
    if (!AdaptiveProgramCatalog.contains(programId)) return false;
    final base = current;
    final existing = base.progressFor(programId);
    var next = base.copyWith(activeProgramId: programId);
    if (existing == null) {
      next = next.withProgress(
        AdaptiveProgramProgress.fresh(
          programId: programId,
          startedAt: (now ?? _clock()).toUtc(),
        ),
      );
    }
    if (next == base) return true;
    return _commit(next);
  }

  /// Switches the active program to [programId]. Existing progress is
  /// resumed; otherwise the program is started fresh. Semantically identical
  /// to [startOrResumeProgram]; named for UI clarity.
  Future<bool> switchActiveProgram(String programId, {DateTime? now}) =>
      startOrResumeProgram(programId, now: now);

  /// Clears only the saved program progress of [programId] and re-initialises
  /// it fresh. Workout history is untouched. Active program is unchanged.
  Future<bool> restartProgram(String programId, {DateTime? now}) async {
    if (!AdaptiveProgramCatalog.contains(programId)) return false;
    final base = current;
    final next = base.withProgress(
      AdaptiveProgramProgress.fresh(
        programId: programId,
        startedAt: (now ?? _clock()).toUtc(),
      ),
    );
    return _commit(next);
  }

  /// Records that [plannedSessionId] of [programId] was completed by the
  /// Player session [playerSessionId].
  ///
  /// Exactly-once semantics:
  /// - duplicate planned session → counted once (no write, returns true)
  /// - duplicate Player session → counted once (no write, returns true)
  /// - unknown program or session not in the definition → false
  /// - out-of-order completion is allowed
  Future<bool> markSessionCompleted({
    required String programId,
    required String plannedSessionId,
    required String playerSessionId,
    DateTime? completedAt,
  }) async {
    final definition = AdaptiveProgramCatalog.byId(programId);
    if (definition == null) return false;
    if (!definition.containsSession(plannedSessionId)) return false;
    if (playerSessionId.isEmpty) return false;

    final base = current;
    final at = (completedAt ?? _clock()).toUtc();
    final existing = base.progressFor(programId) ??
        AdaptiveProgramProgress.fresh(programId: programId, startedAt: at);

    final completion = AdaptiveProgramSessionCompletion(
      plannedSessionId: plannedSessionId,
      playerSessionId: playerSessionId,
      completedAt: at,
    );

    if (!existing.wouldAccept(completion)) {
      // Already counted — idempotent no-op.
      return true;
    }

    final next = base.withProgress(existing.withCompletion(completion));
    return _commit(next);
  }

  // ---------------------------------------------------------------------------
  // Read-only helpers
  // ---------------------------------------------------------------------------

  String? get activeProgramId => current.activeProgramId;

  AdaptiveProgramDefinition? get activeDefinition =>
      AdaptiveProgramCatalog.byId(current.activeProgramId);

  AdaptiveProgramProgress? progressFor(String programId) =>
      current.progressFor(programId);

  /// Status for [programId], or null when the program is unknown.
  AdaptiveProgramStatus? statusFor(String programId) {
    final def = AdaptiveProgramCatalog.byId(programId);
    if (def == null) return null;
    return AdaptiveProgramStatus(
      definition: def,
      progress: current.progressFor(programId),
    );
  }

  int completedCount(String programId) =>
      statusFor(programId)?.completedCount ?? 0;

  AdaptiveProgramSession? firstIncompleteSession(String programId) =>
      statusFor(programId)?.nextSession;

  bool isProgramComplete(String programId) =>
      statusFor(programId)?.isComplete ?? false;
}
