import 'package:fitflow/features/backup/data/backup_persistence_codec.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_restore_result.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Transaction-like REPLACE of the eight FitFlow-owned preference keys.
///
/// 1. capture the CURRENT raw value of every owned key (rollback snapshot)
/// 2. apply the validated replacement values, checking EVERY write/remove
/// 3. on any failure, put every captured value back (best effort) and report
///    truthfully whether that rollback fully succeeded
///
/// Never calls `SharedPreferences.clear()` and never touches keys outside
/// [BackupFormat.ownedPreferenceKeys].
class BackupRestoreTransaction {
  BackupRestoreTransaction({
    required SharedPreferences prefs,
    Future<bool> Function(String key, String value)? setString,
    Future<bool> Function(String key)? remove,
  })  : _prefs = prefs,
        _setString = setString ?? ((k, v) => prefs.setString(k, v)),
        _remove = remove ?? prefs.remove;

  final SharedPreferences _prefs;
  final Future<bool> Function(String key, String value) _setString;
  final Future<bool> Function(String key) _remove;

  Future<BackupRestoreResult> run(FitFlowBackupData data) async {
    final desired = BackupPersistenceCodec.rawValuesFor(data);
    assert(BackupPersistenceCodec.coversOwnedKeys(desired));

    // 1. Rollback snapshot of the current raw values.
    final original = <String, String?>{
      for (final key in BackupFormat.ownedPreferenceKeys) key: _readRaw(key),
    };

    // 2. Apply, checking every result.
    String? failedKey;
    for (final key in BackupFormat.ownedPreferenceKeys) {
      if (!await _write(key, desired[key])) {
        failedKey = key;
        break;
      }
    }
    if (failedKey == null) return const BackupRestoreResult.success();

    // 3. Best-effort rollback of every owned key.
    var rollbackComplete = true;
    for (final key in BackupFormat.ownedPreferenceKeys) {
      if (!await _write(key, original[key])) rollbackComplete = false;
    }
    return rollbackComplete
        ? BackupRestoreResult.rolledBack(failedKey: failedKey)
        : BackupRestoreResult.rollbackIncomplete(failedKey: failedKey);
  }

  String? _readRaw(String key) {
    try {
      final value = _prefs.get(key);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// `null` value → key must be absent. Never throws.
  Future<bool> _write(String key, String? value) async {
    try {
      if (value == null) {
        if (!_prefs.containsKey(key)) return true;
        return await _remove(key);
      }
      return await _setString(key, value);
    } catch (_) {
      return false;
    }
  }
}
