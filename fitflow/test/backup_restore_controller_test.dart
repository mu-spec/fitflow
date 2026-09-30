import 'dart:convert';
import 'dart:typed_data';

import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_restore_transaction.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_validation_result.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackupFileService files;
  late FakeWorkoutReminderNotificationService reminders;

  setUp(() {
    ensureTimezones();
    SharedPreferences.setMockInitialValues({'unrelated': 'keep'});
    files = FakeBackupFileService();
    reminders = FakeWorkoutReminderNotificationService();
  });

  ProviderContainer makeContainer({
    BackupRestoreTransactionFactory? transactionFactory,
  }) {
    final container = ProviderContainer(overrides: [
      backupFileServiceProvider.overrideWithValue(files),
      backupClockProvider.overrideWithValue(() => backupTestNow),
      if (transactionFactory != null)
        backupRestoreTransactionFactoryProvider
            .overrideWithValue(transactionFactory),
      ...reminderOverrides(service: reminders),
    ]);
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive for the test.
    container.listen(backupRestoreControllerProvider, (_, __) {});
    return container;
  }

  Future<Map<String, Object?>> rawOwned() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final k in BackupFormat.ownedPreferenceKeys) k: prefs.get(k)};
  }

  /// Seeds the device with a "previous" data set via the transaction.
  Future<void> seedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final previous = fullBackupData().copyWith(
      appearance: AppearanceMode.light,
      workoutHistory: backupHistory(count: 1),
      workoutReminders: backupReminders(enabled: false),
    );
    await BackupRestoreTransaction(prefs: prefs).run(previous);
  }

  group('createBackup', () {
    test('hands deterministic bytes + timestamped name to the file service',
        () async {
      await seedDevice();
      final container = makeContainer();
      final controller =
          container.read(backupRestoreControllerProvider.notifier);

      await controller.createBackup();

      expect(files.saveCalls, 1);
      expect(files.lastSavedFileName, 'FitFlow-backup-20260930-070509.json');
      final decoded = BackupCodec.decode(files.lastSavedBytes!);
      expect(decoded.isSuccess, isTrue, reason: decoded.detail);
      expect(decoded.envelope!.createdAtUtc, backupTestNow);
      expect(decoded.envelope!.data.appearance, AppearanceMode.light);
      expect(decoded.envelope!.data.workoutHistory.length, 1);
      expect(container.read(backupRestoreControllerProvider).message,
          BackupCopy.backupSaved);
      expect(container.read(backupRestoreControllerProvider).phase,
          BackupRestorePhase.idle);
    });

    test('backs up PERSISTED data (fresh install → empty sections)', () async {
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .createBackup();
      final data = BackupCodec.decode(files.lastSavedBytes!).envelope!.data;
      expect(data.userFitnessProfile, isNull);
      expect(data.workoutHistory, isEmpty);
      final text = utf8.decode(files.lastSavedBytes!);
      expect(text.contains('unrelated'), isFalse);
    });

    test('cancelled Save As → no message, no error', () async {
      files.saveOutcome = BackupSaveOutcome.cancelled;
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .createBackup();
      final state = container.read(backupRestoreControllerProvider);
      expect(state.message, isNull);
      expect(state.phase, BackupRestorePhase.idle);
      expect(files.saved, isEmpty);
    });

    test('failed Save As → retry copy', () async {
      files.saveOutcome = BackupSaveOutcome.failed;
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .createBackup();
      expect(container.read(backupRestoreControllerProvider).message,
          BackupCopy.backupSaveFailed);
    });
  });

  group('pickAndValidate', () {
    test('cancel → idle, silent, no writes', () async {
      await seedDevice();
      final before = await rawOwned();
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .pickAndValidate();
      final state = container.read(backupRestoreControllerProvider);
      expect(state.phase, BackupRestorePhase.idle);
      expect(state.message, isNull);
      expect(state.preview, isNull);
      expect(await rawOwned(), before);
      expect(files.lastMaxBytes, BackupFormat.maxImportBytes);
    });

    test('too large → message, no writes', () async {
      await seedDevice();
      final before = await rawOwned();
      files.pickResult = const BackupPickResult.tooLarge(fileName: 'big.json');
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .pickAndValidate();
      expect(container.read(backupRestoreControllerProvider).message,
          BackupCopy.fileTooLarge);
      expect(await rawOwned(), before);
    });

    test('read failure → unreadable message', () async {
      files.pickResult = const BackupPickResult.failed();
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .pickAndValidate();
      expect(container.read(backupRestoreControllerProvider).message,
          BackupCopy.fileUnreadable);
    });

    test('invalid file → concise error, nothing written, no preview', () async {
      await seedDevice();
      final before = await rawOwned();
      final cases = <Uint8List, String>{
        bytesOf({'hello': 'world'}): BackupCopy.notFitFlowBackup,
        mutatedBackup((r) => r['schemaVersion'] = 7): BackupCopy.newerVersion,
        mutatedBackup((r) => r['schemaVersion'] = 'x'):
            BackupCopy.unsupportedVersion,
        mutatedBackup((r) => dataOf(r)['appearance'] = 'neon'):
            BackupCopy.invalidData,
        Uint8List.fromList([0xFF, 0xFE]): BackupCopy.fileUnreadable,
      };
      for (final entry in cases.entries) {
        files.pickResult = BackupPickResult.picked(entry.key);
        final container = makeContainer();
        await container
            .read(backupRestoreControllerProvider.notifier)
            .pickAndValidate();
        final state = container.read(backupRestoreControllerProvider);
        expect(state.message, entry.value);
        expect(state.preview, isNull);
        expect(state.pending, isNull);
        expect(state.phase, BackupRestorePhase.idle);
        container.dispose();
      }
      expect(await rawOwned(), before);
    });

    test('valid file → preview with accurate counts, still no writes',
        () async {
      await seedDevice();
      final before = await rawOwned();
      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .pickAndValidate();
      final state = container.read(backupRestoreControllerProvider);
      expect(state.phase, BackupRestorePhase.previewing);
      expect(state.message, isNull);
      final p = state.preview!;
      expect(p.hasProfile, isTrue);
      expect(p.hasCapabilityProfile, isTrue);
      expect(p.evidencePatternCount, 2);
      expect(p.historyCount, 3);
      expect(p.customWorkoutCount, 2);
      expect(p.startedProgramCount, 2);
      expect(p.completedProgramSessionCount, 2);
      expect(p.remindersEnabled, isTrue);
      expect(p.appearance, AppearanceMode.dark);
      expect(p.createdAtUtc, backupTestNow);
      expect(await rawOwned(), before, reason: 'preview must not write');

      container.read(backupRestoreControllerProvider.notifier).discardPending();
      expect(container.read(backupRestoreControllerProvider).preview, isNull);
      expect(container.read(backupRestoreControllerProvider).phase,
          BackupRestorePhase.idle);
    });
  });

  group('confirmRestore — success path', () {
    test(
        'replaces data, refreshes providers, resets session mode, reconciles reminders',
        () async {
      await seedDevice();
      final container = makeContainer();

      // Warm providers with the OLD data.
      expect((await container.read(userFitnessProfileProvider.future))!.goal,
          FitnessGoal.buildStrength);
      expect(await container.read(appearanceControllerProvider.future),
          AppearanceMode.light);
      expect((await container.read(workoutHistoryProvider.future)).length, 1);
      await container.read(customWorkoutControllerProvider.notifier).refresh();
      await container
          .read(adaptiveProgramsControllerProvider.notifier)
          .refresh();
      await container
          .read(workoutRemindersControllerProvider.notifier)
          .initialize();
      expect(
          container.read(workoutRemindersControllerProvider).enabled, isFalse);
      container
          .read(workoutSessionModeProvider.notifier)
          .selectMode(WorkoutSessionMode.lowEnergy);

      final restored = fullBackupData().copyWith(
        userFitnessProfile: UserFitnessProfile(
          goal: FitnessGoal.improveMobility,
          experience: backupProfile().experience,
          workoutDuration: backupProfile().workoutDuration,
          environment: backupProfile().environment,
          equipment: backupProfile().equipment,
          preferences: backupProfile().preferences,
        ),
        workoutHistory: backupHistory(count: 3),
        customWorkouts: const [],
        appearance: AppearanceMode.dark,
        workoutReminders: backupReminders(enabled: true),
      );
      files.pickResult =
          BackupPickResult.picked(BackupCodec.encode(envelopeOf(restored)));
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();

      final state = container.read(backupRestoreControllerProvider);
      expect(state.outcome, BackupRestoreOutcome.success);
      expect(state.message, BackupCopy.restoreSucceeded);
      expect(state.pending, isNull);
      expect(state.phase, BackupRestorePhase.idle);

      // Persisted.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unrelated'), 'keep');
      expect(prefs.getString(AppearanceStorage.appearanceKey), 'dark');

      // Providers reflect the restored data without a restart.
      expect(container.read(userFitnessProfileProvider).value!.goal,
          FitnessGoal.improveMobility);
      expect(container.read(capabilityProfileProvider).value,
          restored.capabilityProfile);
      expect(container.read(appearanceControllerProvider).value,
          AppearanceMode.dark);
      expect((await container.read(workoutHistoryProvider.future)).length, 3);
      expect(container.read(customWorkoutControllerProvider).value, isEmpty);
      expect(
          container
              .read(adaptiveProgramsControllerProvider)
              .value
              ?.activeProgramId,
          AdaptiveProgramCatalog.balancedFoundationsId);
      expect(container.read(workoutSessionModeProvider),
          WorkoutSessionMode.standard);

      // Reminders: restored intent applied + reconciled against device tz.
      final rem = container.read(workoutRemindersControllerProvider);
      expect(rem.enabled, isTrue);
      expect(rem.preferences.weekdays, {1, 3, 5});
      expect(rem.status, WorkoutReminderScheduleStatus.scheduled);
      expect(reminders.scheduledIds,
          {1, 3, 5}.map(WorkoutReminderIds.forWeekday).toSet());
      expect(reminders.permissionRequests, 0,
          reason: 'never request during restore');
      final storedReminders = await const WorkoutReminderStorage().load();
      expect(storedReminders.lastScheduledTimezoneId, reminders.timezoneId);
    });

    test('restored reminders disabled → owned weekly ids cancelled', () async {
      await seedDevice();
      final container = makeContainer();
      await container
          .read(workoutRemindersControllerProvider.notifier)
          .initialize();
      for (final id in WorkoutReminderIds.allWeekly) {
        reminders.injectPending(id);
      }
      files.pickResult = BackupPickResult.picked(BackupCodec.encode(envelopeOf(
          fullBackupData()
              .copyWith(workoutReminders: backupReminders(enabled: false)))));
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();

      expect(container.read(backupRestoreControllerProvider).outcome,
          BackupRestoreOutcome.success);
      expect(reminders.cancelled.toSet(),
          containsAll(WorkoutReminderIds.allWeekly));
      expect(reminders.scheduledIds, isEmpty);
      expect(container.read(workoutRemindersControllerProvider).status,
          WorkoutReminderScheduleStatus.off);
    });

    test(
        'enabled + permission denied → data success with attention warning, kept enabled',
        () async {
      reminders.permission = WorkoutReminderPermissionStatus.denied;
      final container = makeContainer();
      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();

      final state = container.read(backupRestoreControllerProvider);
      expect(state.outcome, BackupRestoreOutcome.successRemindersNeedAttention);
      expect(state.message, BackupCopy.restoreSucceededRemindersAttention);
      final rem = container.read(workoutRemindersControllerProvider);
      expect(rem.enabled, isTrue, reason: 'user intent preserved');
      expect(rem.status, WorkoutReminderScheduleStatus.permissionBlocked);
      expect(reminders.scheduledIds, isEmpty);
      expect(reminders.permissionRequests, 0);
      // Data was still restored.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceStorage.appearanceKey), 'dark');
    });

    test('scheduling failure → data success with attention warning', () async {
      reminders.scheduleSucceeds = false;
      final container = makeContainer();
      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();

      final state = container.read(backupRestoreControllerProvider);
      expect(state.outcome, BackupRestoreOutcome.successRemindersNeedAttention);
      expect(
          container.read(workoutRemindersControllerProvider).lastScheduleFailed,
          isTrue);
      expect(container.read(userFitnessProfileProvider).value, isNotNull);
    });

    test('restore uses the CURRENT device timezone, not one from the file',
        () async {
      reminders.timezoneId = 'Europe/Berlin';
      final container = makeContainer();
      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();
      final stored = await const WorkoutReminderStorage().load();
      expect(stored.lastScheduledTimezoneId, 'Europe/Berlin');
      expect(reminders.scheduled.values.first.scheduledAt.location.name,
          'Europe/Berlin');
    });

    test('empty backup restores a fresh-install state', () async {
      await seedDevice();
      final container = makeContainer();
      await container.read(userFitnessProfileProvider.future);
      files.pickResult = BackupPickResult.picked(
          BackupCodec.encode(envelopeOf(emptyBackupData())));
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      expect(
          container.read(backupRestoreControllerProvider).preview!.hasProfile,
          isFalse);
      await controller.confirmRestore();
      expect(container.read(backupRestoreControllerProvider).outcome,
          BackupRestoreOutcome.success);
      expect(container.read(userFitnessProfileProvider).value, isNull);
      expect(container.read(capabilityProfileProvider).value, isNull);
      expect(container.read(appearanceControllerProvider).value,
          AppearanceMode.system);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unrelated'), 'keep');
    });
  });

  group('confirmRestore — failure path', () {
    test('write failure → rolled back, providers untouched, previous data kept',
        () async {
      await seedDevice();
      final before = await rawOwned();
      var failed = false;
      final container = makeContainer(
        transactionFactory: (prefs) => BackupRestoreTransaction(
          prefs: prefs,
          setString: (k, v) async {
            if (k == AppearanceStorage.appearanceKey && !failed) {
              failed = true;
              return false;
            }
            return prefs.setString(k, v);
          },
        ),
      );
      expect(await container.read(appearanceControllerProvider.future),
          AppearanceMode.light);
      await container
          .read(workoutRemindersControllerProvider.notifier)
          .initialize();

      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();

      final state = container.read(backupRestoreControllerProvider);
      expect(state.outcome, BackupRestoreOutcome.rolledBack);
      expect(state.message, BackupCopy.restoreFailedRolledBack);
      expect(state.phase, BackupRestorePhase.previewing,
          reason: 'user may retry');
      expect(state.pending, isNotNull);
      expect(await rawOwned(), before);
      expect(container.read(appearanceControllerProvider).value,
          AppearanceMode.light);
      expect(container.read(workoutSessionModeProvider),
          WorkoutSessionMode.standard);
      expect(reminders.scheduleCalls, 0,
          reason: 'no reminder reconcile after failed restore');
      expect(reminders.permissionRequests, 0);
    });

    test('rollback failure → truthful "may need to be restored again" copy',
        () async {
      await seedDevice();
      var appearanceCalls = 0;
      final container = makeContainer(
        transactionFactory: (prefs) => BackupRestoreTransaction(
          prefs: prefs,
          setString: (k, v) async {
            if (k == AppearanceStorage.appearanceKey) {
              appearanceCalls++;
              return false; // apply fails AND rollback fails
            }
            return prefs.setString(k, v);
          },
        ),
      );
      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      final controller =
          container.read(backupRestoreControllerProvider.notifier);
      await controller.pickAndValidate();
      await controller.confirmRestore();
      final state = container.read(backupRestoreControllerProvider);
      expect(state.outcome, BackupRestoreOutcome.rollbackIncomplete);
      expect(state.message, BackupCopy.restoreFailedRollbackIncomplete);
      expect(appearanceCalls, 2);
    });

    test('confirmRestore without a pending backup is a no-op', () async {
      await seedDevice();
      final before = await rawOwned();
      final container = makeContainer();
      await container
          .read(backupRestoreControllerProvider.notifier)
          .confirmRestore();
      expect(container.read(backupRestoreControllerProvider).outcome, isNull);
      expect(await rawOwned(), before);
    });
  });

  test('messageForError maps every validation error to concise copy', () {
    for (final e in BackupValidationError.values) {
      final msg = BackupRestoreController.messageForError(e);
      expect(msg, isNotEmpty);
      expect(msg.contains('Exception'), isFalse);
      expect(msg.contains('#0'), isFalse);
    }
  });
}
