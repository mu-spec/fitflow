import 'dart:convert';
import 'dart:typed_data';

import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_reminder_preferences.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

// -----------------------------------------------------------------------------
// Fake file service
// -----------------------------------------------------------------------------

/// In-memory [BackupFileService]. Records what would have been saved and
/// serves a scripted pick result.
class FakeBackupFileService implements BackupFileService {
  BackupSaveOutcome saveOutcome = BackupSaveOutcome.saved;
  BackupPickResult pickResult = const BackupPickResult.cancelled();

  final List<({String fileName, Uint8List bytes})> saved = [];
  int saveCalls = 0;
  int pickCalls = 0;
  int? lastMaxBytes;

  Uint8List? get lastSavedBytes => saved.isEmpty ? null : saved.last.bytes;
  String? get lastSavedFileName => saved.isEmpty ? null : saved.last.fileName;

  @override
  Future<BackupSaveOutcome> saveBackup({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    saveCalls++;
    if (saveOutcome == BackupSaveOutcome.saved) {
      saved.add((fileName: suggestedFileName, bytes: bytes));
    }
    return saveOutcome;
  }

  @override
  Future<BackupPickResult> pickBackup(
      {int maxBytes = BackupFormat.maxImportBytes}) async {
    pickCalls++;
    lastMaxBytes = maxBytes;
    return pickResult;
  }
}

// -----------------------------------------------------------------------------
// Fixtures
// -----------------------------------------------------------------------------

final DateTime backupTestNow = DateTime.utc(2026, 9, 30, 7, 5, 9);

UserFitnessProfile backupProfile() => UserFitnessProfile(
      goal: FitnessGoal.buildStrength,
      experience: ExperienceLevel.someExperience,
      workoutDuration: WorkoutDuration.twentyMinutes,
      environment: TrainingEnvironment.normalHome,
      equipment: {WorkoutEquipment.resistanceBands, WorkoutEquipment.chair},
      preferences: {WorkoutPreference.lowImpact, WorkoutPreference.noJumping},
    );

CapabilityProfile backupCapabilityProfile({DateTime? updatedAt}) {
  final at = updatedAt ?? DateTime.utc(2026, 9, 1, 10);
  final map = <MovementPattern, MovementCapability>{};
  var i = 0;
  for (final pattern in CapabilityProfile.trainablePatterns) {
    map[pattern] = MovementCapability(
      movementPattern: pattern,
      level: CapabilityLevel.values[i % CapabilityLevel.values.length],
      source: i.isEven
          ? CapabilitySource.initialAssessment
          : CapabilitySource.progression,
      updatedAt: at.add(Duration(minutes: i)),
      anchorExerciseId: i % 3 == 0 ? 'anchor_${pattern.name}' : null,
    );
    i++;
  }
  return CapabilityProfile.fromMap(map);
}

AdaptiveProgressionEvidence backupEvidence() =>
    AdaptiveProgressionEvidence.fromMap({
      MovementPattern.push: 1,
      MovementPattern.squat: 1,
      MovementPattern.core: 0,
    });

CompletedWorkoutExercise backupExercise(
  String id, {
  WorkoutSectionType section = WorkoutSectionType.main,
  MovementPattern? pattern = MovementPattern.push,
  bool timed = false,
}) =>
    CompletedWorkoutExercise(
      exerciseId: id,
      exerciseName: 'Exercise $id',
      movementPattern: pattern,
      sectionType: section,
      sets: 3,
      repsPerSet: timed ? null : 10,
      workDuration: timed ? const Duration(seconds: 30) : null,
      restBetweenSets: const Duration(seconds: 45),
      difficulty: ExerciseDifficulty.level2,
    );

CompletedWorkout backupWorkout(String id, DateTime completedAt) =>
    CompletedWorkout(
      id: id,
      completedAt: completedAt,
      targetDuration: const Duration(minutes: 20),
      estimatedDuration: const Duration(minutes: 18),
      totalExerciseCount: 3,
      totalSetCount: 9,
      warmup: [
        backupExercise('w_$id',
            section: WorkoutSectionType.warmup,
            pattern: MovementPattern.warmup,
            timed: true),
      ],
      main: [backupExercise('m_$id')],
      cooldown: [
        backupExercise('c_$id',
            section: WorkoutSectionType.cooldown, pattern: null, timed: true),
      ],
    );

/// Newest first, like the app's history storage.
List<CompletedWorkout> backupHistory({int count = 3}) => [
      for (var i = count - 1; i >= 0; i--)
        backupWorkout('hist_$i', DateTime.utc(2026, 9, 1 + i, 8)),
    ];

CustomWorkoutTemplate backupTemplate(String id, DateTime updatedAt) =>
    CustomWorkoutTemplate(
      id: id,
      name: 'Custom $id',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: updatedAt.subtract(const Duration(days: 1)),
      updatedAt: updatedAt,
      warmup: const [
        CustomWorkoutExerciseEntry(
          exerciseId: 'arm_circles',
          sets: 1,
          workDuration: Duration(seconds: 30),
          restBetweenSets: Duration(seconds: 15),
        ),
      ],
      main: const [
        CustomWorkoutExerciseEntry(
          exerciseId: 'push_up',
          sets: 3,
          repsPerSet: 8,
          restBetweenSets: Duration(seconds: 45),
        ),
        CustomWorkoutExerciseEntry(
          exerciseId: 'bodyweight_squat',
          sets: 3,
          repsPerSet: 12,
          restBetweenSets: Duration(seconds: 45),
        ),
      ],
    );

/// Most recently updated first, like the app's custom workout storage.
List<CustomWorkoutTemplate> backupCustomWorkouts() => [
      backupTemplate('cw_b', DateTime.utc(2026, 9, 12, 12)),
      backupTemplate('cw_a', DateTime.utc(2026, 9, 10, 12)),
    ];

AdaptiveProgramsState backupPrograms() {
  final started = DateTime.utc(2026, 8, 20, 6);
  final balanced = AdaptiveProgramProgress(
    programId: AdaptiveProgramCatalog.balancedFoundationsId,
    startedAt: started,
    updatedAt: started.add(const Duration(days: 3)),
    completions: [
      AdaptiveProgramSessionCompletion(
        plannedSessionId: 'balanced_foundations_w1_s1',
        playerSessionId: 'session_a',
        completedAt: started.add(const Duration(days: 1)),
      ),
      AdaptiveProgramSessionCompletion(
        plannedSessionId: 'balanced_foundations_w1_s2',
        playerSessionId: 'session_b',
        completedAt: started.add(const Duration(days: 3)),
      ),
    ],
  );
  final strength = AdaptiveProgramProgress.fresh(
    programId: AdaptiveProgramCatalog.strengthFoundationsId,
    startedAt: started.add(const Duration(days: 5)),
  );
  return AdaptiveProgramsState(
    activeProgramId: AdaptiveProgramCatalog.balancedFoundationsId,
    progressByProgram: {
      strength.programId: strength,
      balanced.programId: balanced,
    },
  );
}

BackupReminderPreferences backupReminders({bool enabled = true}) =>
    BackupReminderPreferences(
      enabled: enabled,
      weekdays: const {1, 3, 5},
      time: const WorkoutReminderTime(hour: 7, minute: 30),
    );

/// A fully-populated backup payload.
FitFlowBackupData fullBackupData() => FitFlowBackupData(
      userFitnessProfile: backupProfile(),
      capabilityProfile: backupCapabilityProfile(),
      adaptiveProgressionEvidence: backupEvidence(),
      workoutHistory: backupHistory(),
      customWorkouts: backupCustomWorkouts(),
      adaptivePrograms: backupPrograms(),
      workoutReminders: backupReminders(),
      appearance: AppearanceMode.dark,
    );

/// A backup with nothing user-generated (fresh install).
FitFlowBackupData emptyBackupData() => FitFlowBackupData(
      userFitnessProfile: null,
      capabilityProfile: null,
      adaptiveProgressionEvidence: AdaptiveProgressionEvidence.zero(),
      workoutHistory: const [],
      customWorkouts: const [],
      adaptivePrograms: AdaptiveProgramsState.empty,
      workoutReminders: BackupReminderPreferences.defaults,
      appearance: AppearanceMode.system,
    );

FitFlowBackupEnvelope envelopeOf(FitFlowBackupData data,
        {DateTime? createdAt}) =>
    FitFlowBackupEnvelope(
      schemaVersion: BackupFormat.schemaVersion,
      createdAtUtc: (createdAt ?? backupTestNow).toUtc(),
      data: data,
    );

Uint8List fullBackupBytes() => BackupCodec.encode(envelopeOf(fullBackupData()));

/// Decoded JSON of a full backup, for mutation in validation tests.
Map<String, dynamic> fullBackupJson() =>
    jsonDecode(utf8.decode(fullBackupBytes())) as Map<String, dynamic>;

Map<String, dynamic> dataOf(Map<String, dynamic> root) =>
    root['data'] as Map<String, dynamic>;

Uint8List bytesOf(Object json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

/// Applies [mutate] to a full backup JSON tree and returns the bytes.
Uint8List mutatedBackup(void Function(Map<String, dynamic> root) mutate) {
  final root = fullBackupJson();
  mutate(root);
  return bytesOf(root);
}
