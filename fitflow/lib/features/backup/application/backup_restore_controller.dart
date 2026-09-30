import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_restore_transaction.dart';
import 'package:fitflow/features/backup/data/backup_snapshot_reader.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_restore_result.dart';
import 'package:fitflow/features/backup/domain/backup_validation_result.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_preview.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:fitflow/features/workouts/application/adaptive_progression_controller.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final backupFileServiceProvider =
    Provider<BackupFileService>((ref) => const FilePickerBackupFileService());

final backupClockProvider =
    Provider<DateTime Function()>((ref) => () => DateTime.now());

final backupPrefsProvider = Provider<Future<SharedPreferences> Function()>(
    (ref) => SharedPreferences.getInstance);

/// Seam so tests can inject failing writes into the restore transaction.
typedef BackupRestoreTransactionFactory = BackupRestoreTransaction Function(
    SharedPreferences prefs);

final backupRestoreTransactionFactoryProvider =
    Provider<BackupRestoreTransactionFactory>(
        (ref) => (prefs) => BackupRestoreTransaction(prefs: prefs));

final backupRestoreControllerProvider = StateNotifierProvider.autoDispose<
    BackupRestoreController, BackupRestoreState>((ref) {
  return BackupRestoreController(
    ref: ref,
    fileService: ref.watch(backupFileServiceProvider),
    clock: ref.watch(backupClockProvider),
    getPrefs: ref.watch(backupPrefsProvider),
    transactionFactory: ref.watch(backupRestoreTransactionFactoryProvider),
  );
});

enum BackupRestorePhase { idle, creating, picking, previewing, restoring }

/// Final outcome of a restore attempt, surfaced once to the UI.
enum BackupRestoreOutcome {
  success,
  successRemindersNeedAttention,
  rolledBack,
  rollbackIncomplete,
}

@immutable
class BackupRestoreState {
  const BackupRestoreState({
    this.phase = BackupRestorePhase.idle,
    this.pending,
    this.preview,
    this.message,
    this.outcome,
  });

  final BackupRestorePhase phase;

  /// Validated, not-yet-applied backup awaiting confirmation.
  final FitFlowBackupEnvelope? pending;
  final FitFlowBackupPreview? preview;

  /// One-shot feedback (snackbar).
  final String? message;

  /// Set exactly once after `confirmRestore` finishes.
  final BackupRestoreOutcome? outcome;

  bool get isBusy =>
      phase == BackupRestorePhase.creating ||
      phase == BackupRestorePhase.picking ||
      phase == BackupRestorePhase.restoring;

  BackupRestoreState copyWith({
    BackupRestorePhase? phase,
    FitFlowBackupEnvelope? pending,
    FitFlowBackupPreview? preview,
    bool clearPending = false,
    String? message,
    bool clearMessage = false,
    BackupRestoreOutcome? outcome,
    bool clearOutcome = false,
  }) {
    return BackupRestoreState(
      phase: phase ?? this.phase,
      pending: clearPending ? null : (pending ?? this.pending),
      preview: clearPending ? null : (preview ?? this.preview),
      message: clearMessage ? null : (message ?? this.message),
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
    );
  }
}

class BackupRestoreController extends StateNotifier<BackupRestoreState> {
  BackupRestoreController({
    required Ref ref,
    required BackupFileService fileService,
    required DateTime Function() clock,
    required Future<SharedPreferences> Function() getPrefs,
    BackupRestoreTransactionFactory? transactionFactory,
  })  : _ref = ref,
        _fileService = fileService,
        _clock = clock,
        _getPrefs = getPrefs,
        _transactionFactory = transactionFactory ??
            ((prefs) => BackupRestoreTransaction(prefs: prefs)),
        super(const BackupRestoreState());

  final Ref _ref;
  final BackupFileService _fileService;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _getPrefs;
  final BackupRestoreTransactionFactory _transactionFactory;

  void clearMessage() {
    if (state.message != null) state = state.copyWith(clearMessage: true);
  }

  void clearOutcome() {
    if (state.outcome != null) state = state.copyWith(clearOutcome: true);
  }

  /// Builds the envelope from PERSISTED data and hands the bytes to Save As.
  Future<void> createBackup() async {
    if (state.isBusy) return;
    state =
        state.copyWith(phase: BackupRestorePhase.creating, clearMessage: true);
    try {
      final data = await BackupSnapshotReader(getPrefs: _getPrefs).read();
      final now = _clock();
      final envelope = FitFlowBackupEnvelope(
        schemaVersion: BackupFormat.schemaVersion,
        createdAtUtc: now.toUtc(),
        data: data,
      );
      final outcome = await _fileService.saveBackup(
        suggestedFileName: BackupFormat.defaultFileName(now),
        bytes: BackupCodec.encode(envelope),
      );
      if (!mounted) return;
      state = state.copyWith(
        phase: BackupRestorePhase.idle,
        message: switch (outcome) {
          BackupSaveOutcome.saved => BackupCopy.backupSaved,
          BackupSaveOutcome.cancelled => null,
          BackupSaveOutcome.failed => BackupCopy.backupSaveFailed,
        },
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          phase: BackupRestorePhase.idle, message: BackupCopy.backupSaveFailed);
    }
  }

  /// Picks a file, validates it strictly and (only if valid) shows a preview.
  /// Nothing is written here.
  Future<void> pickAndValidate() async {
    if (state.isBusy) return;
    state = state.copyWith(
        phase: BackupRestorePhase.picking,
        clearMessage: true,
        clearPending: true);
    final picked = await _fileService.pickBackup();
    if (!mounted) return;
    switch (picked.status) {
      case BackupPickStatus.cancelled:
        state = state.copyWith(phase: BackupRestorePhase.idle);
        return;
      case BackupPickStatus.tooLarge:
        state = state.copyWith(
            phase: BackupRestorePhase.idle, message: BackupCopy.fileTooLarge);
        return;
      case BackupPickStatus.failed:
        state = state.copyWith(
            phase: BackupRestorePhase.idle, message: BackupCopy.fileUnreadable);
        return;
      case BackupPickStatus.picked:
        break;
    }
    final result = BackupCodec.decode(picked.bytes!);
    if (!mounted) return;
    if (!result.isSuccess) {
      state = state.copyWith(
          phase: BackupRestorePhase.idle,
          message: messageForError(result.error!));
      return;
    }
    final envelope = result.envelope!;
    state = state.copyWith(
      phase: BackupRestorePhase.previewing,
      pending: envelope,
      preview: FitFlowBackupPreview.fromEnvelope(envelope),
    );
  }

  void discardPending() {
    if (state.phase == BackupRestorePhase.restoring) return;
    state = state.copyWith(phase: BackupRestorePhase.idle, clearPending: true);
  }

  /// Applies the pending backup with REPLACE semantics inside the rollback
  /// transaction, then refreshes in-memory state only after the writes are
  /// final.
  Future<void> confirmRestore() async {
    final pending = state.pending;
    if (pending == null || state.isBusy) return;
    state = state.copyWith(
        phase: BackupRestorePhase.restoring,
        clearMessage: true,
        clearOutcome: true);

    BackupRestoreResult result;
    try {
      final prefs = await _getPrefs();
      result = await _transactionFactory(prefs).run(pending.data);
    } catch (_) {
      result = const BackupRestoreResult.rolledBack(failedKey: null);
    }
    if (!mounted) return;

    if (!result.success) {
      state = state.copyWith(
        phase: BackupRestorePhase.previewing,
        message: result.rollbackComplete
            ? BackupCopy.restoreFailedRolledBack
            : BackupCopy.restoreFailedRollbackIncomplete,
        outcome: result.rollbackComplete
            ? BackupRestoreOutcome.rolledBack
            : BackupRestoreOutcome.rollbackIncomplete,
      );
      return;
    }

    final remindersNeedAttention = await _refreshAfterRestore();
    if (!mounted) return;
    state = state.copyWith(
      phase: BackupRestorePhase.idle,
      clearPending: true,
      outcome: remindersNeedAttention
          ? BackupRestoreOutcome.successRemindersNeedAttention
          : BackupRestoreOutcome.success,
      message: remindersNeedAttention
          ? BackupCopy.restoreSucceededRemindersAttention
          : BackupCopy.restoreSucceeded,
    );
  }

  /// Refreshes every provider that caches restored data. Returns whether
  /// reminders need attention after reconciliation.
  Future<bool> _refreshAfterRestore() async {
    // Session mode is not persisted; a restore starts from Standard.
    _ref.read(workoutSessionModeProvider.notifier).reset();

    // Best effort: the splash start gate re-reads persisted data anyway, so a
    // refresh hiccup must never mask a restore that already succeeded.
    try {
      await _ref.read(userFitnessProfileProvider.notifier).reload();
      await _ref.read(capabilityProfileProvider.notifier).reload();
      await _ref.read(appearanceControllerProvider.notifier).reload();
      _ref.invalidate(adaptiveProgressionEvidenceStorageProvider);
      _ref.invalidate(adaptiveProgressionControllerAsyncProvider);
      _ref.invalidate(workoutHistoryProvider);
      await _ref.read(customWorkoutControllerProvider.notifier).refresh();
      await _ref.read(adaptiveProgramsControllerProvider.notifier).refresh();
    } catch (_) {
      // Ignored by design; see above.
    }

    try {
      return await _ref
          .read(workoutRemindersControllerProvider.notifier)
          .reloadAfterRestore();
    } catch (_) {
      return true;
    }
  }

  static String messageForError(BackupValidationError error) => switch (error) {
        BackupValidationError.tooLarge => BackupCopy.fileTooLarge,
        BackupValidationError.unreadable => BackupCopy.fileUnreadable,
        BackupValidationError.notFitFlowBackup => BackupCopy.notFitFlowBackup,
        BackupValidationError.newerVersion => BackupCopy.newerVersion,
        BackupValidationError.unsupportedVersion =>
          BackupCopy.unsupportedVersion,
        BackupValidationError.invalidData => BackupCopy.invalidData,
      };
}
