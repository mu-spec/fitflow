import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M18 regression guard: backup/restore uses the Storage Access Framework via
/// the system picker only — no broad storage permissions may ever be added.
void main() {
  test('AndroidManifest declares no storage permissions', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final forbidden in const [
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'MANAGE_EXTERNAL_STORAGE',
      'READ_MEDIA_IMAGES',
      'READ_MEDIA_VIDEO',
      'READ_MEDIA_AUDIO',
    ]) {
      expect(manifest.contains(forbidden), isFalse,
          reason: '$forbidden must not be declared');
    }
  });

  test('M17 exact-alarm permissions are still absent', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('SCHEDULE_EXACT_ALARM'), isFalse);
    expect(manifest.contains('USE_EXACT_ALARM'), isFalse);
  });

  test('pubspec pins a stable file_picker and no share_plus', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
        RegExp(r'^\s*file_picker:\s*\^13\.\d+\.\d+\s*$', multiLine: true)
            .hasMatch(pubspec),
        isTrue);
    expect(pubspec.contains('share_plus'), isFalse);
    final lock = File('pubspec.lock').readAsStringSync();
    final match =
        RegExp(r'  file_picker:\n(?:.*\n){1,6}?    version: "([^"]+)"')
            .firstMatch(lock);
    expect(match, isNotNull);
    expect(match!.group(1)!.contains('-'), isFalse, reason: 'no prerelease');
  });
}
