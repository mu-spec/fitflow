import 'dart:io';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/settings/data/privacy_policy_links.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_url_launcher_channel.dart';
import 'helpers/profile_editor_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final strings = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
  final backupRules = File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync();
  final extractionRules =
      File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
  final gitignore = File('.gitignore').readAsStringSync();
  final androidGitignore = File('android/.gitignore').readAsStringSync();

  group('release configuration', () {
    test('version is the first production release', () {
      expect(
        RegExp(r'^version:\s*1\.0\.0\+1\s*$', multiLine: true).hasMatch(pubspec),
        isTrue,
      );
      expect(gradle.contains('versionCode = flutter.versionCode'), isTrue);
      expect(gradle.contains('versionName = flutter.versionName'), isTrue);
    });

    test('SDK levels are explicit and do not drop below API 26', () {
      expect(gradle.contains('minSdk = 26'), isTrue);
      expect(gradle.contains('minSdk = 24'), isFalse);
      expect(gradle.contains('targetSdk = 36'), isTrue);
      expect(gradle.contains('compileSdk = 36'), isTrue);
      expect(gradle.contains('flutter.minSdkVersion'), isFalse);
      expect(gradle.contains('flutter.targetSdkVersion'), isFalse);
      expect(gradle.contains('flutter.compileSdkVersion'), isFalse);
      expect(gradle.contains('JavaVersion.VERSION_17'), isTrue);
      expect(gradle.contains('JvmTarget.JVM_17'), isTrue);
      expect(gradle.contains('isCoreLibraryDesugaringEnabled = true'), isTrue);
    });

    test('native libraries are 64-bit ARM only', () {
      final gradleProperties =
          File('android/gradle.properties').readAsStringSync();
      expect(gradleProperties.contains('target-platform=android-arm64'), isTrue);
      for (final abi in ['lib/armeabi-v7a/**', 'lib/x86/**', 'lib/x86_64/**']) {
        expect(gradle.contains(abi), isTrue, reason: abi);
      }
      expect(gradle.contains('packaging {'), isTrue);
      expect(gradle.contains('jniLibs {'), isTrue);
    });

    test('applicationId candidate is unchanged', () {
      expect(gradle.contains('namespace = "com.fitflow.fitflow"'), isTrue);
      expect(gradle.contains('applicationId = "com.fitflow.fitflow"'), isTrue);
    });

    test('launcher label is Home Workout from a string resource', () {
      expect(manifest.contains('android:label="@string/app_name"'), isTrue);
      expect(manifest.contains('android:label="fitflow"'), isFalse);
      expect(strings.contains('<string name="app_name">Home Workout</string>'), isTrue);
    });

    test('release signing cannot fall back to the debug key', () {
      expect(gradle.contains('signingConfigs.getByName("debug")'), isFalse);
      expect(gradle.contains('signingConfig = signingConfigs.getByName("debug")'), isFalse);
      expect(gradle.contains('hasReleaseSigning'), isTrue);
      expect(gradle.contains('will not sign a release'), isTrue);
      expect(File('android/key.properties').existsSync(), isFalse);
      expect(File('android/key.properties.example').existsSync(), isTrue);
      final example = File('android/key.properties.example').readAsStringSync();
      expect(example.contains('REPLACE_WITH_STORE_PASSWORD'), isTrue);
      expect(example.contains('REPLACE_WITH_KEYSTORE_PATH'), isTrue);
      for (final ignore in [gitignore, androidGitignore]) {
        expect(ignore.contains('key.properties'), isTrue);
        expect(ignore.contains('*.jks') || ignore.contains('**/*.jks'), isTrue);
        expect(
          ignore.contains('*.keystore') || ignore.contains('**/*.keystore'),
          isTrue,
        );
      }
    });
  });

  group('Android backup and permissions', () {
    test('automatic OS backup and device transfer are excluded', () {
      expect(manifest.contains('android:allowBackup="false"'), isTrue);
      expect(manifest.contains('android:fullBackupContent="@xml/backup_rules"'), isTrue);
      expect(
        manifest.contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
        isTrue,
      );
      for (final domain in ['root', 'file', 'database', 'sharedpref', 'external']) {
        expect(backupRules.contains('domain="$domain"'), isTrue, reason: domain);
        expect(extractionRules.contains('domain="$domain"'), isTrue, reason: domain);
      }
      expect(extractionRules.contains('<cloud-backup>'), isTrue);
      expect(extractionRules.contains('<device-transfer>'), isTrue);
      expect(extractionRules.contains('<include '), isFalse);
      expect(backupRules.contains('<include '), isFalse);
    });

    test('manual backup schema and sections are unchanged', () {
      expect(BackupFormat.schemaVersion, 1);
      expect(BackupFormat.sections, [
        'userFitnessProfile',
        'capabilityProfile',
        'adaptiveProgressionEvidence',
        'workoutHistory',
        'customWorkouts',
        'adaptivePrograms',
        'workoutReminders',
        'appearance',
      ]);
      expect(
        BackupFormat.ownedPreferenceKeys.any((key) => key.toLowerCase().contains('locale')),
        isFalse,
      );
      expect(BackupFormat.sections.contains('locale'), isFalse);
    });

    test('release manifest does not add unexpected dangerous permissions', () {
      const allowed = {
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
      };
      final declared = RegExp(r'android:name="(android\.permission\.[^"]+)"')
          .allMatches(manifest)
          .map((match) => match.group(1)!)
          .toSet();
      expect(declared, allowed);
      for (final forbidden in const [
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'READ_CONTACTS',
        'CAMERA',
        'RECORD_AUDIO',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'MANAGE_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES',
        'SCHEDULE_EXACT_ALARM',
        'USE_EXACT_ALARM',
        'QUERY_ALL_PACKAGES',
        'AD_ID',
        'health.READ_',
        'BIND_ACCESSIBILITY_SERVICE',
      ]) {
        expect(manifest.contains(forbidden), isFalse, reason: forbidden);
      }
      expect(manifest.contains('android.intent.action.TTS_SERVICE'), isTrue);
      expect(manifest.contains('android.intent.action.PROCESS_TEXT'), isTrue);
    });
  });

  group('privacy policy', () {
    test('hosted policy is static, complete, and matches the in-app link', () {
      final html = File('docs/privacy-policy.html').readAsStringSync();
      final lower = html.toLowerCase();
      // Static page: no scripts, no external subresources, no trackers.
      expect(lower.contains('<script'), isFalse);
      expect(lower.contains('<iframe'), isFalse);
      expect(RegExp(r'src="https?://').hasMatch(html), isFalse);
      expect(RegExp(r'<link[^>]+href="https?://').hasMatch(html), isFalse);
      // It describes this app, not a template for some other product.
      expect(html.contains('com.fitflow.fitflow'), isTrue);
      expect(lower.contains('internet permission'), isTrue);
      expect(lower.contains('not a medical device'), isTrue);
      expect(lower.contains('allowbackup="false"'), isTrue);
      expect(html.contains('mailto:'), isTrue);
      // Every entry point opens exactly the official hosted page.
      expect(
        PrivacyPolicyLinks.privacyPolicyUrl,
        'https://mu-spec.github.io/home-workout-privacy/',
      );
      final launcherSource =
          File('lib/features/settings/presentation/privacy_policy_launcher.dart')
              .readAsStringSync();
      expect(
          launcherSource.contains('PrivacyPolicyLinks.privacyPolicyUrl'), isTrue);
      expect(launcherSource.contains('LaunchMode.externalApplication'), isTrue);
      expect(
          File('lib/features/settings/presentation/settings_screen.dart')
              .readAsStringSync()
              .contains('openPrivacyPolicyInBrowser'),
          isTrue);
      // Three operator fields are still marked for the developer to fill in.
      final publishing =
          File('docs/release/PRIVACY_POLICY_PUBLISHING.md').readAsStringSync();
      for (final field in ['DEVELOPER_NAME', 'CONTACT_EMAIL', 'PUBLIC_URL']) {
        expect(publishing.contains(field), isTrue, reason: field);
      }
      expect(File('docs/release/PRIVACY_POLICY_PUBLISHING.md').existsSync(), isTrue);
      expect(File('docs/release/play_data_safety.md').existsSync(), isTrue);
      expect(File('docs/release/play_health_declaration.md').existsSync(), isTrue);
      expect(File('docs/release/play_console_checklist.md').existsSync(), isTrue);
      expect(File('docs/release/data_safety_audit.md').existsSync(), isTrue);
      expect(File('docs/release/android_binary_validation.md').existsSync(), isTrue);
      expect(File('docs/release/local_release_validation.md').existsSync(), isTrue);
    });

    testWidgets('Settings Privacy Policy tile opens the official URL externally',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      ensureTimezones();
      final launcher = FakeUrlLauncherChannel()..install();
      addTearDown(launcher.uninstall);
      final reminders = FakeWorkoutReminderNotificationService();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = AppRouter.create(initialLocation: AppRoutes.settings);
      await tester.pumpWidget(
        ProviderScope(
          overrides: reminderOverrides(service: reminders),
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await settleProfileFrames(tester);

      expect(find.text('Privacy Policy'), findsOneWidget);
      final tile = find.byKey(SettingsScreen.privacyPolicyTileKey);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await settleProfileFrames(tester);

      // Tapping the existing tile hands the official policy to the device
      // browser (useWebView stays false); it does not push a second, in-app
      // copy of the policy.
      expect(launcher.calls, hasLength(1));
      expect(launcher.lastLaunchedUrl,
          'https://mu-spec.github.io/home-workout-privacy/');
      expect(launcher.lastUsedWebView, isFalse);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
