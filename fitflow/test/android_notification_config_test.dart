import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source/config verification for the M17 Android setup (no APK build).
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final service = File(
          'lib/features/reminders/application/local_workout_reminder_notification_service.dart')
      .readAsStringSync();
  final mainActivity =
      File('android/app/src/main/kotlin/com/fitflow/fitflow/MainActivity.kt').readAsStringSync();

  group('AndroidManifest', () {
    test('no exact-alarm permission', () {
      expect(manifest.contains('SCHEDULE_EXACT_ALARM'), isFalse);
      expect(manifest.contains('USE_EXACT_ALARM'), isFalse);
    });

    test('POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED present', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('scheduling + boot receivers present and not exported', () {
      expect(manifest, contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver'));
      expect(manifest, contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
      expect(RegExp(r'<receiver[^>]*android:exported="true"').hasMatch(manifest), isFalse);
    });

    test('no unrelated permissions (internet, location, foreground service, full-screen)', () {
      for (final p in [
        'android.permission.INTERNET',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'FOREGROUND_SERVICE',
        'USE_FULL_SCREEN_INTENT',
        'WAKE_LOCK',
      ]) {
        expect(manifest.contains(p), isFalse, reason: p);
      }
      expect(manifest.contains('firebase'), isFalse);
      expect(manifest.contains('onesignal'), isFalse);
    });
  });

  group('Gradle', () {
    test('core-library desugaring enabled with Java 17 preserved', () {
      expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(gradle, contains('sourceCompatibility = JavaVersion.VERSION_17'));
      expect(gradle, contains('targetCompatibility = JavaVersion.VERSION_17'));
      expect(gradle, contains('JvmTarget.JVM_17'));
      expect(RegExp(r'coreLibraryDesugaring\("com\.android\.tools:desugar_jdk_libs:2\.\d+\.\d+"\)')
              .hasMatch(gradle),
          isTrue);
      expect(gradle.contains('VERSION_11'), isFalse);
      expect(gradle.contains('VERSION_1_8'), isFalse);
    });

    test('minSdk stays 24 and Play target/compile SDK are explicit', () {
      expect(gradle, contains('minSdk = 24'));
      expect(gradle, contains('targetSdk = 36'));
      expect(gradle, contains('compileSdk = 36'));
      expect(gradle.contains('flutter.minSdkVersion'), isFalse);
    });
  });

  group('Dependencies', () {
    test('local-only stable notification stack; no remote push SDKs', () {
      expect(pubspec, contains('flutter_local_notifications: ^22.3.1'));
      expect(pubspec, contains('timezone: ^0.11.1'));
      expect(pubspec, contains('flutter_timezone: ^5.1.0'));
      for (final banned in [
        'firebase',
        'onesignal',
        'http:',
        'dio:',
        'awesome_notifications',
        'workmanager',
        'android_alarm_manager',
        '-dev',
        '-beta',
      ]) {
        expect(pubspec.contains(banned), isFalse, reason: banned);
      }
    });
  });

  group('Production service source policy', () {
    test('inexact scheduling only; no exact/alarm-clock modes; no cancelAll', () {
      expect(service, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
      expect(service.contains('AndroidScheduleMode.exact'), isFalse);
      expect(service.contains('AndroidScheduleMode.alarmClock'), isFalse);
      expect(service.contains('requestExactAlarmsPermission'), isFalse);
      expect(service.contains('cancelAll'), isFalse);
      expect(service.contains('fullScreenIntent: true'), isFalse);
      expect(service, contains('DateTimeComponents.dayOfWeekAndTime'));
      expect(service, contains('Importance.defaultImportance'));
      expect(service, contains("'fitflow_workout_reminders_v1'"));
    });

    test('settings channel opens notification settings without extra permissions', () {
      expect(mainActivity, contains('fitflow/notification_settings'));
      expect(mainActivity, contains('ACTION_APP_NOTIFICATION_SETTINGS'));
      expect(mainActivity.contains('AlarmManager'), isFalse);
    });
  });
}
