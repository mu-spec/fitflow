import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_persistence_codec.dart';
import 'package:fitflow/features/backup/data/backup_snapshot_reader.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testNow = DateTime.utc(2026, 9, 30, 12);

  /// Seeds every persisted store through the M18 persistence codec and
  /// returns the seeded raw values for byte-level comparison.
  Future<Map<String, String>> seedEverything() async {
    final raw = BackupPersistenceCodec.rawValuesFor(fullBackupData());
    final seeded = <String, String>{
      for (final entry in raw.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    SharedPreferences.setMockInitialValues(Map<String, Object>.of(seeded));
    return seeded;
  }

  /// Capability profile at the top level for every trainable pattern, so
  /// eligibility/generation tests isolate setup-related rules.
  CapabilityProfile maxCapability() {
    final at = DateTime.utc(2026, 9, 1, 10);
    return CapabilityProfile.fromMap({
      for (final pattern in CapabilityProfile.trainablePatterns)
        pattern: MovementCapability(
          movementPattern: pattern,
          level: CapabilityLevel.values.last,
          source: CapabilitySource.progression,
          updatedAt: at,
        ),
    });
  }

  /// Generation-friendly base profile (bodyweight-only catalog support).
  UserFitnessProfile generativeProfile({
    FitnessGoal goal = FitnessGoal.generalFitness,
    WorkoutDuration duration = WorkoutDuration.tenMinutes,
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
    ExperienceLevel experience = ExperienceLevel.completelyNew,
  }) =>
      UserFitnessProfile(
        goal: goal,
        experience: experience,
        workoutDuration: duration,
        environment: environment,
        equipment: equipment,
        preferences: preferences,
      );

  group('M19 §10 — edited duration drives future adaptive generation', () {
    test('future generation reads 30 minutes after a 10→30 minute edit',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userFitnessProfileProvider.notifier);
      final original = await container.read(userFitnessProfileProvider.future);
      expect(original, isNotNull);

      // Persisted profile starts at 10 minutes.
      final tenMinute = generativeProfile(duration: WorkoutDuration.tenMinutes);
      expect(await notifier.saveProfile(tenMinute), isTrue);

      final capability = maxCapability();
      final planAt10 = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(planAt10, isNotNull);
      expect(planAt10!.timeBudget.target, const Duration(minutes: 10));

      // Edit + save to 30 minutes through the existing M19 path.
      final thirtyMinute = tenMinute.copyWith(
        workoutDuration: WorkoutDuration.thirtyMinutes,
      );
      expect(await notifier.saveProfile(thirtyMinute), isTrue);

      // Future generation reads the updated profile through the provider.
      final exposed = container.read(userFitnessProfileProvider).value!;
      expect(exposed.workoutDuration, WorkoutDuration.thirtyMinutes);
      final planAt30 = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(
          userProfile: exposed,
          capabilityProfile: capability,
        ),
      );
      expect(planAt30, isNotNull);
      expect(planAt30!.timeBudget.target, const Duration(minutes: 30));

      // Completed sessions stay untouched.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(WorkoutHistoryStorage.key),
        seeded[WorkoutHistoryStorage.key],
      );
    });
  });

  group('M19 §11–13 — setup edits flow through the canonical eligibility '
      'engine', () {
    test('removing required equipment excludes the exercise', () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);

      final benchExercise = ExerciseCatalog.all.firstWhere(
        (exercise) =>
            exercise.active &&
            exercise.requiredEquipment.contains(WorkoutEquipment.bench),
      );
      final capability = maxCapability();

      // With the bench available the exercise is eligible.
      final withBench = generativeProfile(
        equipment: const {WorkoutEquipment.bench},
      );
      await notifier.saveProfile(withBench);
      final before = ExerciseEligibilityEngine.evaluate(
        benchExercise,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(before.eligible, isTrue, reason: before.reasons.toString());

      // Removing the bench through the saved profile excludes it.
      await notifier.saveProfile(
        withBench.copyWith(equipment: const {WorkoutEquipment.none}),
      );
      final after = ExerciseEligibilityEngine.evaluate(
        benchExercise,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(after.eligible, isFalse);
      expect(
        after.reasons,
        contains(ExerciseExclusionReason.missingEquipment),
      );
      expect(after.missingEquipment, {WorkoutEquipment.bench});
    });

    test('changing environment restricts space-limited exercises', () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);

      final spaceLimited = ExerciseCatalog.all.firstWhere(
        (exercise) =>
            exercise.active &&
            exercise.spaceRequirement == SpaceRequirement.medium &&
            !exercise.tags.contains('jumping') &&
            exercise.requiredEquipment.contains(WorkoutEquipment.none),
      );
      final capability = maxCapability();

      // Normal home allows medium-space exercises.
      await notifier.saveProfile(
        generativeProfile(environment: TrainingEnvironment.normalHome),
      );
      final before = ExerciseEligibilityEngine.evaluate(
        spaceLimited,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(before.eligible, isTrue, reason: before.reasons.toString());

      // A small-room environment excludes them through existing rules.
      await notifier.saveProfile(
        generativeProfile(environment: TrainingEnvironment.smallRoom),
      );
      final after = ExerciseEligibilityEngine.evaluate(
        spaceLimited,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(after.eligible, isFalse);
      expect(
        after.reasons,
        contains(ExerciseExclusionReason.insufficientSpace),
      );
    });

    test('enabling No jumping excludes jumping exercises', () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);

      final jumpingExercise = ExerciseCatalog.all.firstWhere(
        (exercise) => exercise.active && exercise.tags.contains('jumping'),
      );
      final capability = maxCapability();

      // Without the preference the exercise is eligible.
      await notifier.saveProfile(generativeProfile());
      final before = ExerciseEligibilityEngine.evaluate(
        jumpingExercise,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(before.eligible, isTrue, reason: before.reasons.toString());

      // Enabling No jumping excludes it.
      await notifier.saveProfile(
        generativeProfile(
          preferences: const {WorkoutPreference.noJumping},
        ),
      );
      final after = ExerciseEligibilityEngine.evaluate(
        jumpingExercise,
        ExerciseEligibilityContext.fromProfiles(
          userProfile: container.read(userFitnessProfileProvider).value!,
          capabilityProfile: capability,
        ),
      );
      expect(after.eligible, isFalse);
      expect(
        after.reasons,
        contains(ExerciseExclusionReason.jumpingRestricted),
      );
    });
  });

  group('M19 §14–16 — programs see the updated profile, state stays intact',
      () {
    test('goal change re-points the recommendation only', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);

      await notifier.saveProfile(generativeProfile(
        goal: FitnessGoal.generalFitness,
      ));
      var goal = container.read(userFitnessProfileProvider).value!.goal;
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(goal),
        AdaptiveProgramCatalog.balancedFoundationsId,
      );
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedFor(goal).name,
        'Balanced Foundations',
      );

      await notifier.saveProfile(generativeProfile(
        goal: FitnessGoal.buildStrength,
      ));
      goal = container.read(userFitnessProfileProvider).value!.goal;
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(goal),
        AdaptiveProgramCatalog.strengthFoundationsId,
      );
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedFor(goal).name,
        'Strength Foundations',
      );

      await notifier.saveProfile(generativeProfile(
        goal: FitnessGoal.improveMobility,
      ));
      goal = container.read(userFitnessProfileProvider).value!.goal;
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(goal),
        'mobility_movement',
      );
      expect(
        AdaptiveProgramRecommendationPolicy.recommendedFor(goal).name,
        'Mobility & Movement',
      );

      // Active program, progress, and completions are untouched.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AdaptiveProgramsStorage.key),
        seeded[AdaptiveProgramsStorage.key],
      );
      final state = await const AdaptiveProgramsStorage().load();
      expect(
        state.activeProgramId,
        fullBackupData().adaptivePrograms.activeProgramId,
      );
      expect(
        state.progressByProgram,
        fullBackupData().adaptivePrograms.progressByProgram,
      );
    });

    test('future program sessions resolve from the updated profile without '
        'persisting plans', () async {
      final seeded = await seedEverything();
      final definition = AdaptiveProgramCatalog.byId(
        AdaptiveProgramCatalog.balancedFoundationsId,
      )!;
      final session = definition.weeks.first.sessions.first;
      final capability = maxCapability();

      final profile10 = generativeProfile(
        duration: WorkoutDuration.tenMinutes,
      );
      final before = AdaptiveProgramWorkoutResolver.resolve(
        definition: definition,
        session: session,
        userProfile: profile10,
        capabilityProfile: capability,
      );
      expect(before.plan, isNotNull);
      expect(before.plan!.timeBudget.target, const Duration(minutes: 10));

      // Edited setup: duration, environment, and preferences flow through.
      final edited = profile10.copyWith(
        workoutDuration: WorkoutDuration.thirtyMinutes,
        environment: TrainingEnvironment.outdoor,
        preferences: const {WorkoutPreference.lowImpact},
      );
      final after = AdaptiveProgramWorkoutResolver.resolve(
        definition: definition,
        session: session,
        userProfile: edited,
        capabilityProfile: capability,
      );
      expect(after.plan, isNotNull);
      expect(after.plan!.timeBudget.target, const Duration(minutes: 30));
      expect(after.generationProfile.workoutDuration,
          WorkoutDuration.thirtyMinutes);
      expect(after.generationProfile.environment, TrainingEnvironment.outdoor);
      expect(after.generationProfile.preferences,
          {WorkoutPreference.lowImpact});

      // Resolving never persists program state.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AdaptiveProgramsStorage.key),
        seeded[AdaptiveProgramsStorage.key],
      );
    });
  });

  group('M19 §17 — M15 skill tree setup fit recalculates', () {
    test('removing required equipment flips Fits your setup to Needs setup '
        'change', () async {
      final capability = maxCapability();
      final benchExercise = ExerciseCatalog.all.firstWhere(
        (exercise) =>
            exercise.active &&
            exercise.requiredEquipment.contains(WorkoutEquipment.bench),
      );

      ExerciseSkillTreeNode nodeFor(ExerciseSkillTreeCatalog catalog) {
        for (final tree in catalog.trees) {
          for (final node in tree.nodes) {
            if (node.exercise.id == benchExercise.id) {
              return node;
            }
          }
        }
        fail('bench exercise node not found in skill tree catalog');
      }

      final withBench = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: generativeProfile(
          equipment: const {WorkoutEquipment.bench},
        ),
        capabilityProfile: capability,
      );
      expect(
        nodeFor(withBench).setupStatus,
        ExerciseSkillTreeSetupStatus.fitsSetup,
      );

      final withoutBench = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: generativeProfile(
          equipment: const {WorkoutEquipment.none},
        ),
        capabilityProfile: capability,
      );
      expect(
        nodeFor(withoutBench).setupStatus,
        ExerciseSkillTreeSetupStatus.needsSetupChange,
      );
    });
  });

  group('M19 §18 — custom workouts stay stored and resolve truthfully', () {
    test('templates remain byte-identical after profile edits', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);

      await notifier.saveProfile(generativeProfile(
        equipment: const {WorkoutEquipment.none},
        preferences: const {
          WorkoutPreference.noJumping,
          WorkoutPreference.standingOnly,
        },
      ));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(CustomWorkoutStorage.key),
        seeded[CustomWorkoutStorage.key],
      );
      expect(
        await const CustomWorkoutStorage().loadAll(),
        fullBackupData().customWorkouts,
      );
    });

    test('an incompatible template is truthfully flagged, never auto-fixed',
        () async {
      final benchExercise = ExerciseCatalog.all.firstWhere(
        (exercise) =>
            exercise.active &&
            exercise.requiredEquipment.contains(WorkoutEquipment.bench),
      );
      // A fully valid custom template (warmup + main + cooldown) built from
      // real catalog exercises, with a bench-dependent main exercise.
      final template = CustomWorkoutTemplate(
        id: 'bench_day',
        name: 'Bench day',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: testNow.subtract(const Duration(days: 1)),
        updatedAt: testNow,
        warmup: const [
          CustomWorkoutExerciseEntry(
            exerciseId: 'march_in_place',
            sets: 1,
            workDuration: Duration(seconds: 30),
            restBetweenSets: Duration(seconds: 15),
          ),
        ],
        main: [
          CustomWorkoutExerciseEntry(
            exerciseId: benchExercise.id,
            sets: 3,
            repsPerSet: 8,
            restBetweenSets: const Duration(seconds: 45),
          ),
        ],
        cooldown: const [
          CustomWorkoutExerciseEntry(
            exerciseId: 'figure_four_stretch',
            sets: 1,
            workDuration: Duration(seconds: 30),
            restBetweenSets: Duration(seconds: 15),
          ),
        ],
      );
      final catalogById = {
        for (final exercise in ExerciseCatalog.all) exercise.id: exercise,
      };
      final capability = maxCapability();

      final withBench = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: generativeProfile(
          equipment: const {WorkoutEquipment.bench},
        ),
        capabilityProfile: capability,
      );
      expect(withBench.plan, isNotNull);

      final withoutBench = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: generativeProfile(
          equipment: const {WorkoutEquipment.none},
        ),
        capabilityProfile: capability,
      );
      expect(withoutBench.plan, isNull);
      expect(withoutBench.issues, isNotEmpty);
    });
  });

  group('M19 §19–21 — capability and evidence protection', () {
    test('editing every profile field leaves CapabilityProfile identical',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      final before = fullBackupData().capabilityProfile!;

      await notifier.saveProfile(UserFitnessProfile(
        goal: FitnessGoal.improveMobility,
        experience: ExperienceLevel.experienced,
        workoutDuration: WorkoutDuration.fortyFiveMinutes,
        environment: TrainingEnvironment.outdoor,
        equipment: const {WorkoutEquipment.kettlebell},
        preferences: const {
          WorkoutPreference.standingOnly,
          WorkoutPreference.avoidDeepKneeBending,
        },
      ));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(CapabilityProfileStorage.profileKey),
        seeded[CapabilityProfileStorage.profileKey],
      );
      final after = CapabilityProfileStorage(prefs).load()!;
      for (final pattern in CapabilityProfile.trainablePatterns) {
        expect(after.capabilityFor(pattern)?.level,
            before.capabilityFor(pattern)?.level,
            reason: 'level for $pattern');
        expect(after.capabilityFor(pattern)?.source,
            before.capabilityFor(pattern)?.source,
            reason: 'source for $pattern');
        expect(after.capabilityFor(pattern)?.updatedAt,
            before.capabilityFor(pattern)?.updatedAt,
            reason: 'updatedAt for $pattern');
        expect(after.capabilityFor(pattern)?.anchorExerciseId,
            before.capabilityFor(pattern)?.anchorExerciseId,
            reason: 'anchor for $pattern');
      }
    });

    test('changing goal alone does not change movement capability', () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      final current = await container.read(userFitnessProfileProvider.future);

      await notifier.saveProfile(
        current!.copyWith(goal: FitnessGoal.loseWeight),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(CapabilityProfileStorage.profileKey),
        seeded[CapabilityProfileStorage.profileKey],
      );
    });

    test('changing experience alone does not change movement capability',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      final current = await container.read(userFitnessProfileProvider.future);

      await notifier.saveProfile(
        current!.copyWith(experience: ExperienceLevel.regularTraining),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(CapabilityProfileStorage.profileKey),
        seeded[CapabilityProfileStorage.profileKey],
      );
    });

    test('progression evidence is byte-identical after profile edits',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      await notifier.saveProfile(generativeProfile(
        goal: FitnessGoal.buildMuscle,
        preferences: const {WorkoutPreference.lowImpact},
      ));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AdaptiveProgressionEvidenceStorage.evidenceKey),
        seeded[AdaptiveProgressionEvidenceStorage.evidenceKey],
      );
    });
  });

  group('M19 §22–24 — history, analytics, and reminders protection', () {
    test('history stays identical and analytics derive the same metrics',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      final historyBefore = WorkoutHistoryStorage(
        await SharedPreferences.getInstance(),
      ).load();
      final analyticsBefore = TrainingAnalyticsEngine.calculate(
        history: historyBefore,
        now: testNow,
      );

      await notifier.saveProfile(generativeProfile(
        duration: WorkoutDuration.fiveMinutes,
        preferences: const {WorkoutPreference.noFloorExercises},
      ));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(WorkoutHistoryStorage.key),
        seeded[WorkoutHistoryStorage.key],
      );
      final historyAfter = WorkoutHistoryStorage(prefs).load();
      expect(historyAfter, historyBefore);

      // History-derived metrics are unchanged by profile edits alone
      // (TrainingAnalytics itself has no ==; compare every derived field).
      final analyticsAfter = TrainingAnalyticsEngine.calculate(
        history: historyAfter,
        now: testNow,
      );
      expect(analyticsAfter.savedWorkoutsCount, analyticsBefore.savedWorkoutsCount);
      expect(analyticsAfter.currentPeriod, analyticsBefore.currentPeriod);
      expect(analyticsAfter.previousPeriod, analyticsBefore.previousPeriod);
      expect(analyticsAfter.last28Days, analyticsBefore.last28Days);
      expect(analyticsAfter.activeWeeksCount, analyticsBefore.activeWeeksCount);
      expect(analyticsAfter.trendBuckets, analyticsBefore.trendBuckets);
      expect(
        analyticsAfter.movementAnalytics,
        analyticsBefore.movementAnalytics,
      );
    });

    test('reminders stay identical after profile and appearance edits',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      await notifier.saveProfile(generativeProfile(
        environment: TrainingEnvironment.hotel,
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppearanceStorage.appearanceKey, 'dark');

      expect(
        prefs.getString(WorkoutReminderStorage.key),
        seeded[WorkoutReminderStorage.key],
      );
    });
  });

  group('M19 §25 — M18 backup captures the edited profile', () {
    test('snapshot → encode → strict decode round-trips the M19 edit at '
        'schema 1', () async {
      await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      final edited = generativeProfile(
        goal: FitnessGoal.buildMuscle,
        duration: WorkoutDuration.fortyFiveMinutes,
        equipment: const {WorkoutEquipment.dumbbells},
        preferences: const {WorkoutPreference.avoidWristHeavy},
      );
      expect(await notifier.saveProfile(edited), isTrue);

      final snapshot = await const BackupSnapshotReader().read();
      expect(snapshot.userFitnessProfile, edited);

      final envelope = envelopeOf(snapshot);
      final decoded = BackupCodec.decode(BackupCodec.encode(envelope));

      expect(decoded.isSuccess, isTrue, reason: decoded.detail);
      expect(decoded.envelope!.schemaVersion, BackupFormat.schemaVersion);
      expect(BackupFormat.schemaVersion, 1);
      expect(decoded.envelope!.data.userFitnessProfile, edited);
    });
  });

  group('M19 — persisted profile remains the single source of truth', () {
    test('only the user_fitness_profile key changes across mixed edits',
        () async {
      final seeded = await seedEverything();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(userFitnessProfileProvider.notifier);
      await container.read(userFitnessProfileProvider.future);

      await notifier.saveProfile(generativeProfile(
        goal: FitnessGoal.stayActive,
        duration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.largeRoom,
        equipment: const {WorkoutEquipment.resistanceBands},
        preferences: const {WorkoutPreference.lowImpact},
      ));

      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        CapabilityProfileStorage.profileKey,
        AdaptiveProgressionEvidenceStorage.evidenceKey,
        WorkoutHistoryStorage.key,
        CustomWorkoutStorage.key,
        AdaptiveProgramsStorage.key,
        WorkoutReminderStorage.key,
      ]) {
        expect(prefs.getString(key), seeded[key], reason: key);
      }
      expect(
        UserFitnessProfileStorage(prefs).load()!.goal,
        FitnessGoal.stayActive,
      );
    });
  });
}
