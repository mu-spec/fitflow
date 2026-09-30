import 'package:flutter/foundation.dart';

/// Outcome of a restore transaction.
@immutable
class BackupRestoreResult {
  const BackupRestoreResult._({
    required this.success,
    required this.rollbackComplete,
    this.failedKey,
  });

  /// Every owned key was replaced successfully.
  const BackupRestoreResult.success()
      : this._(success: true, rollbackComplete: true);

  /// A write failed and every previously stored value was put back.
  const BackupRestoreResult.rolledBack({String? failedKey})
      : this._(success: false, rollbackComplete: true, failedKey: failedKey);

  /// A write failed AND at least one original value could not be restored.
  const BackupRestoreResult.rollbackIncomplete({String? failedKey})
      : this._(success: false, rollbackComplete: false, failedKey: failedKey);

  final bool success;

  /// Meaningful only when [success] is false.
  final bool rollbackComplete;

  /// The owned key whose write failed first (diagnostics/tests only).
  final String? failedKey;
}
