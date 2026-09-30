import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Outcome of a "Save As" attempt.
enum BackupSaveOutcome { saved, cancelled, failed }

/// Outcome of picking + reading a backup file. Bytes are only present for
/// [BackupPickStatus.picked].
enum BackupPickStatus { picked, cancelled, tooLarge, failed }

@immutable
class BackupPickResult {
  const BackupPickResult._(this.status, this.bytes, this.fileName);

  const BackupPickResult.picked(Uint8List bytes, {String? fileName})
      : this._(BackupPickStatus.picked, bytes, fileName);
  const BackupPickResult.cancelled()
      : this._(BackupPickStatus.cancelled, null, null);
  const BackupPickResult.tooLarge({String? fileName})
      : this._(BackupPickStatus.tooLarge, null, fileName);
  const BackupPickResult.failed() : this._(BackupPickStatus.failed, null, null);

  final BackupPickStatus status;
  final Uint8List? bytes;
  final String? fileName;
}

/// Seam over the system document picker. Widgets/controllers never call
/// `FilePicker` directly; tests inject a fake.
abstract class BackupFileService {
  /// Opens "Save As" with [bytes] pre-filled under [suggestedFileName].
  Future<BackupSaveOutcome> saveBackup({
    required String suggestedFileName,
    required Uint8List bytes,
  });

  /// Lets the user choose ONE file and reads it, enforcing [maxBytes] BEFORE
  /// the content is loaded/decoded.
  Future<BackupPickResult> pickBackup(
      {int maxBytes = BackupFormat.maxImportBytes});
}

/// Production implementation over `file_picker` (Android Storage Access
/// Framework — no storage permissions). Every failure is non-fatal.
class FilePickerBackupFileService implements BackupFileService {
  const FilePickerBackupFileService();

  @override
  Future<BackupSaveOutcome> saveBackup({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save FitFlow backup',
        fileName: suggestedFileName,
        bytes: bytes,
        mimeType: BackupFormat.mimeType,
        type: FileType.custom,
        allowedExtensions: const [BackupFormat.fileExtension],
      );
      return uri == null
          ? BackupSaveOutcome.cancelled
          : BackupSaveOutcome.saved;
    } catch (_) {
      return BackupSaveOutcome.failed;
    }
  }

  @override
  Future<BackupPickResult> pickBackup(
      {int maxBytes = BackupFormat.maxImportBytes}) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose a FitFlow backup',
        type: FileType.custom,
        allowedExtensions: const [BackupFormat.fileExtension],
      );
      if (file == null) return const BackupPickResult.cancelled();
      final length = await file.length();
      if (length != null && length > maxBytes) {
        return BackupPickResult.tooLarge(fileName: file.name);
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        return BackupPickResult.tooLarge(fileName: file.name);
      }
      return BackupPickResult.picked(bytes, fileName: file.name);
    } catch (_) {
      return const BackupPickResult.failed();
    }
  }
}
