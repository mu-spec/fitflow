import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_persistence_codec.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';
import 'helpers/profile_editor_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Seeds EVERY persisted store through the M18 persistence codec and
  /// returns the seeded raw values for later comparison.
  Future<Map<String, String>> seedEverything() async {
    final raw = BackupPersistenceCodec.rawValuesFor(fullBackupData());
    expect(BackupPersistenceCodec.coversOwnedKeys(raw), isTrue);
    final seeded = <String, String>{
      for (final entry in raw.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    SharedPreferences.setMockInitialValues(Map<String, Object>.of(seeded));
    return seeded;
  }

  Future<void> expectUntouchedExceptProfile(
    Map<String, String> seeded,
    SharedPreferences prefs,
  ) async {
    expect(
      prefs.getString(CapabilityProfileStorage.profileKey),
      seeded[CapabilityProfileStorage.profileKey],
      reason: 'capability profile must not change on profile edits',
    );
    expect(
      prefs.getString(AdaptiveProgressionEvidenceStorage.evidenceKey),
      seeded[AdaptiveProgressionEvidenceStorage.evidenceKey],
      reason: 'M10 progression evidence must not change on profile edits',
    );
    expect(
      prefs.getString(WorkoutHistoryStorage.key),
      seeded[WorkoutHistoryStorage.key],
      reason: 'workout history must not change on profile edits',
    );
    expect(
      prefs.getString(CustomWorkoutStorage.key),
      seeded[CustomWorkoutStorage.key],
      reason: 'custom workout templates must not change on profile edits',
    );
    expect(
      prefs.getString(AdaptiveProgramsStorage.key),
      seeded[AdaptiveProgramsStorage.key],
      reason: 'program progress must not change on profile edits',
    );
    expect(
      prefs.getString(WorkoutReminderStorage.key),
      seeded[WorkoutReminderStorage.key],
      reason: 'reminders must not change on profile edits',
    );
    expect(
      prefs.getString(AppearanceStorage.appearanceKey),
      seeded[AppearanceStorage.appearanceKey],
      reason: 'appearance must not change on profile edits',
    );
  }

  group('Cross-feature safety — editor save', () {
    testWidgets(
        'saving equipment touches only user_fitness_profile; capability, '
        'evidence, history, custom workouts, programs stay byte-identical', (
      tester,
    ) async {
      final seeded = await seedEverything();
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tester.tap(find.text('Dumbbells'));
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      expect(find.text('Equipment updated.'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      await expectUntouchedExceptProfile(seeded, prefs);

      // Only the profile key changed — and only its equipment field.
      expect(
        prefs.getString(UserFitnessProfileStorage.profileKey),
        isNot(seeded[UserFitnessProfileStorage.profileKey]),
      );
      final originalProfile = fullBackupData().userFitnessProfile!;
      final stored = UserFitnessProfileStorage(prefs).load()!;
      expect(
        stored.equipment,
        {...originalProfile.equipment, WorkoutEquipment.dumbbells},
      );
      expect(stored.goal, originalProfile.goal);
      expect(stored.experience, originalProfile.experience);
      expect(stored.workoutDuration, originalProfile.workoutDuration);
      expect(stored.environment, originalProfile.environment);
      expect(stored.preferences, originalProfile.preferences);
    });
  });

  group('Cross-feature safety — controller save', () {
    test('saveProfile rewrites only the user_fitness_profile key', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final current = await container.read(userFitnessProfileProvider.future);
      expect(current, isNotNull);

      final updated = current!.copyWith(
        goal: FitnessGoal.improveMobility,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        preferences: const {WorkoutPreference.standingOnly},
      );
      final saved = await container
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(updated);
      expect(saved, isTrue);

      final prefs = await SharedPreferences.getInstance();
      await expectUntouchedExceptProfile(seeded, prefs);

      final stored = UserFitnessProfileStorage(prefs).load();
      expect(stored, updated);
    });

    test('capability profile loads unchanged after a profile edit', () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final current = await container.read(userFitnessProfileProvider.future);
      await container
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(current!.copyWith(goal: FitnessGoal.stayActive));

      final prefs = await SharedPreferences.getInstance();
      final loaded = CapabilityProfileStorage(prefs).load();
      expect(loaded, isNotNull);
      expect(
        CapabilityProfileStorage.encode(loaded!),
        CapabilityProfileStorage.encode(fullBackupData().capabilityProfile!),
        reason: 'movement capability levels must survive profile edits',
      );
    });
  });

  group('Future workouts and programs see the updated profile', () {
    test('provider exposes the saved profile for downstream generation',
        () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final current = await container.read(userFitnessProfileProvider.future);
      final updated = current!.copyWith(
        goal: FitnessGoal.improveMobility,
        workoutDuration: WorkoutDuration.fortyFiveMinutes,
        environment: fullBackupData().userFitnessProfile!.environment,
        equipment: const {WorkoutEquipment.exerciseMat},
        preferences: const {WorkoutPreference.lowImpact},
      );
      await container
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(updated);

      // Generation-facing provider state reflects every edited field.
      final exposed = container.read(userFitnessProfileProvider).value!;
      expect(exposed.goal, FitnessGoal.improveMobility);
      expect(exposed.workoutDuration, WorkoutDuration.fortyFiveMinutes);
      expect(exposed.equipment, {WorkoutEquipment.exerciseMat});
      expect(exposed.preferences, {WorkoutPreference.lowImpact});

      // History that generators consume is untouched.
      final prefs = await SharedPreferences.getInstance();
      expect(
        WorkoutHistoryStorage(prefs).load(),
        fullBackupData().workoutHistory,
      );
    });

    test('changing goal re-points the M16 recommendation without touching '
        'program state', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final original = await container.read(userFitnessProfileProvider.future);
      final originalRecommendation = AdaptiveProgramRecommendationPolicy
          .recommendedProgramIdFor(original!.goal);

      final updated = original.copyWith(goal: FitnessGoal.improveMobility);
      await container
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(updated);

      // The provider carries the new goal, so the recommendation derived
      // from it naturally changes…
      final exposedGoal =
          container.read(userFitnessProfileProvider).value!.goal;
      expect(exposedGoal, FitnessGoal.improveMobility);
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(
          exposedGoal,
        ),
        'mobility_movement',
      );
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(
          exposedGoal,
        ),
        isNot(originalRecommendation),
      );

      // …while the persisted program state is untouched: no active-program
      // switch, no progress reset, no restart.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AdaptiveProgramsStorage.key),
        seeded[AdaptiveProgramsStorage.key],
      );
      final programsState = await const AdaptiveProgramsStorage().load();
      expect(
        programsState.activeProgramId,
        fullBackupData().adaptivePrograms.activeProgramId,
      );
      expect(
        programsState.progressByProgram,
        fullBackupData().adaptivePrograms.progressByProgram,
      );
    });
  });

  group('M18 backup compatibility', () {
    test('edited profile round-trips through the backup codec losslessly',
        () async {
      final original = fullBackupData();
      final editedProfile = original.userFitnessProfile!.copyWith(
        goal: FitnessGoal.buildMuscle,
        equipment: const {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.pullUpBar,
        },
        preferences: const {WorkoutPreference.avoidWristHeavy},
      );
      final edited = original.copyWith(userFitnessProfile: editedProfile);

      final result =
          BackupCodec.decode(BackupCodec.encode(envelopeOf(edited)));

      expect(result.isSuccess, isTrue);
      expect(result.envelope!.schemaVersion, BackupFormat.schemaVersion);
      expect(BackupFormat.schemaVersion, 1, reason: 'no schema bump in M19');
      expect(result.envelope!.data.userFitnessProfile, editedProfile);
    });

    test('snapshot reader picks up an edited profile for backups', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final current = await container.read(userFitnessProfileProvider.future);
      await container
          .read(userFitnessProfileProvider.notifier)
          .saveProfile(current!.copyWith(goal: FitnessGoal.loseWeight));

      final prefs = await SharedPreferences.getInstance();
      expect(
        UserFitnessProfileStorage(prefs).load()!.goal,
        FitnessGoal.loseWeight,
      );
      expect(
        prefs.getString(UserFitnessProfileStorage.profileKey),
        isNot(seeded[UserFitnessProfileStorage.profileKey]),
      );
    });
  });
}
