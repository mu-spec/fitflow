import 'dart:typed_data';

import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the calls the production service makes to the plugin platform
/// and serves scripted results. No method channels are touched.
class _FakePlatform extends FilePickerPlatform {
  Uri? saveResult = Uri.parse('content://documents/1');
  Object? saveError;
  PlatformFile? pickResult;
  Object? pickError;

  final List<Map<String, Object?>> saveCalls = [];
  final List<Map<String, Object?>> pickCalls = [];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saveCalls.add({
      'fileName': fileName,
      'bytes': bytes,
      'mimeType': mimeType,
      'dialogTitle': dialogTitle,
    });
    if (saveError != null) throw saveError!;
    return saveResult;
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    pickCalls.add({
      'dialogTitle': dialogTitle,
      'type': type,
      'allowedExtensions': allowedExtensions,
    });
    if (pickError != null) throw pickError!;
    return pickResult;
  }
}

base class _FakeFile extends PlatformFile {
  _FakeFile(
      {required this.name,
      required this.bytes,
      this.reportedLength,
      this.lengthError});

  @override
  final String name;
  final Uint8List bytes;
  final int? reportedLength;
  final Object? lengthError;
  int readCalls = 0;

  @override
  Uri get uri => Uri.parse('content://documents/$name');

  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => reportedLength;

  @override
  Future<int?> length() async {
    if (lengthError != null) throw lengthError!;
    return reportedLength;
  }

  @override
  Future<Uint8List> readAsBytes() async {
    readCalls++;
    return bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

void main() {
  late _FakePlatform platform;
  const service = FilePickerBackupFileService();
  final payload = Uint8List.fromList([123, 125]);

  setUp(() {
    platform = _FakePlatform();
    FilePickerPlatform.instance = platform;
  });

  group('saveBackup', () {
    test('passes name, bytes and application/json to Save As → saved',
        () async {
      final outcome = await service.saveBackup(
          suggestedFileName: 'FitFlow-backup-20260930-070509.json',
          bytes: payload);
      expect(outcome, BackupSaveOutcome.saved);
      expect(platform.saveCalls.single['fileName'],
          'FitFlow-backup-20260930-070509.json');
      expect(platform.saveCalls.single['bytes'], same(payload));
      expect(platform.saveCalls.single['mimeType'], BackupFormat.mimeType);
      expect(platform.saveCalls.single['mimeType'], 'application/json');
    });

    test('null uri (user cancelled) → cancelled, no error', () async {
      platform.saveResult = null;
      expect(
          await service.saveBackup(suggestedFileName: 'a.json', bytes: payload),
          BackupSaveOutcome.cancelled);
    });

    test('platform exception → failed (never throws to the UI)', () async {
      platform.saveError = StateError('boom');
      expect(
          await service.saveBackup(suggestedFileName: 'a.json', bytes: payload),
          BackupSaveOutcome.failed);
    });
  });

  group('pickBackup', () {
    test('restricts to a single custom .json file', () async {
      platform.pickResult = null;
      await service.pickBackup();
      expect(platform.pickCalls.single['type'], FileType.custom);
      expect(platform.pickCalls.single['allowedExtensions'], ['json']);
    });

    test('null (user cancelled) → cancelled', () async {
      platform.pickResult = null;
      final result = await service.pickBackup();
      expect(result.status, BackupPickStatus.cancelled);
      expect(result.bytes, isNull);
    });

    test('returns bytes + name for a normal file', () async {
      final file =
          _FakeFile(name: 'my.json', bytes: payload, reportedLength: 2);
      platform.pickResult = file;
      final result = await service.pickBackup();
      expect(result.status, BackupPickStatus.picked);
      expect(result.bytes, payload);
      expect(result.fileName, 'my.json');
      expect(file.readCalls, 1);
    });

    test('too large by reported length → rejected BEFORE reading bytes',
        () async {
      final file = _FakeFile(
          name: 'huge.json',
          bytes: payload,
          reportedLength: BackupFormat.maxImportBytes + 1);
      platform.pickResult = file;
      final result = await service.pickBackup();
      expect(result.status, BackupPickStatus.tooLarge);
      expect(result.bytes, isNull);
      expect(file.readCalls, 0);
    });

    test(
        'exactly the limit is accepted; unknown length falls back to byte count',
        () async {
      final atLimit = _FakeFile(
          name: 'ok.json',
          bytes: payload,
          reportedLength: BackupFormat.maxImportBytes);
      platform.pickResult = atLimit;
      expect((await service.pickBackup()).status, BackupPickStatus.picked);

      final unknown = _FakeFile(
          name: 'big.json',
          bytes: Uint8List(BackupFormat.maxImportBytes + 1),
          reportedLength: null);
      platform.pickResult = unknown;
      expect((await service.pickBackup()).status, BackupPickStatus.tooLarge);
    });

    test('custom maxBytes is honoured', () async {
      platform.pickResult =
          _FakeFile(name: 'x.json', bytes: payload, reportedLength: 2);
      expect((await service.pickBackup(maxBytes: 1)).status,
          BackupPickStatus.tooLarge);
    });

    test('platform or read exception → failed', () async {
      platform.pickError = StateError('boom');
      expect((await service.pickBackup()).status, BackupPickStatus.failed);
      platform.pickError = null;
      platform.pickResult = _FakeFile(
          name: 'x.json', bytes: payload, lengthError: StateError('io'));
      expect((await service.pickBackup()).status, BackupPickStatus.failed);
    });
  });
}
