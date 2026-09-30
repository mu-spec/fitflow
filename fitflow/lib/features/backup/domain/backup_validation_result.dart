import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:flutter/foundation.dart';

/// Why an import was rejected. Mapped to concise user copy by the UI layer;
/// never exposes stack traces or internal names.
enum BackupValidationError {
  /// Larger than [BackupFormat.maxImportBytes] — rejected before decoding.
  tooLarge,

  /// Empty / invalid UTF-8 / malformed JSON / root not an object.
  unreadable,

  /// Root `format` is not `fitflow_backup`.
  notFitFlowBackup,

  /// `schemaVersion` greater than this app supports.
  newerVersion,

  /// Missing / malformed / unsupported (older) schema version.
  unsupportedVersion,

  /// A data section failed strict validation.
  invalidData,
}

/// Outcome of strict validation: either a fully validated immutable
/// [FitFlowBackupEnvelope] or a single [BackupValidationError].
@immutable
class BackupValidationResult {
  const BackupValidationResult.success(FitFlowBackupEnvelope this.envelope)
      : error = null,
        detail = null;

  const BackupValidationResult.failure(BackupValidationError this.error,
      {this.detail})
      : envelope = null;

  final FitFlowBackupEnvelope? envelope;
  final BackupValidationError? error;

  /// Short developer-facing reason (tests/logging only; never shown raw).
  final String? detail;

  bool get isSuccess => envelope != null;
}
