import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';

/// Versioned FitFlow backup file format constants (M18).
class BackupFormat {
  BackupFormat._();

  /// Root marker every FitFlow backup must carry.
  static const String marker = 'fitflow_backup';

  /// Highest schema version this app can read and write.
  static const int schemaVersion = 1;

  /// Conservative import ceiling checked BEFORE UTF-8/JSON decoding.
  static const int maxImportBytes = 5 * 1024 * 1024; // 5 MiB

  static const String mimeType = 'application/json';
  static const String fileExtension = 'json';

  // Root keys
  static const String keyFormat = 'format';
  static const String keySchemaVersion = 'schemaVersion';
  static const String keyCreatedAtUtc = 'createdAtUtc';
  static const String keyData = 'data';

  // Data section keys
  static const String sectionProfile = 'userFitnessProfile';
  static const String sectionCapability = 'capabilityProfile';
  static const String sectionEvidence = 'adaptiveProgressionEvidence';
  static const String sectionHistory = 'workoutHistory';
  static const String sectionCustomWorkouts = 'customWorkouts';
  static const String sectionPrograms = 'adaptivePrograms';
  static const String sectionReminders = 'workoutReminders';
  static const String sectionAppearance = 'appearance';

  static const List<String> sections = [
    sectionProfile,
    sectionCapability,
    sectionEvidence,
    sectionHistory,
    sectionCustomWorkouts,
    sectionPrograms,
    sectionReminders,
    sectionAppearance,
  ];

  /// The exact SharedPreferences keys the restore transaction owns. Nothing
  /// outside this list is ever read for rollback or written during restore.
  static const List<String> ownedPreferenceKeys = [
    UserFitnessProfileStorage.profileKey, // user_fitness_profile
    CapabilityProfileStorage.profileKey, // capability_profile
    AdaptiveProgressionEvidenceStorage
        .evidenceKey, // adaptive_progression_evidence_v1
    WorkoutHistoryStorage.key, // workout_history_v1
    CustomWorkoutStorage.key, // custom_workouts_v1
    AdaptiveProgramsStorage.key, // adaptive_programs_v1
    WorkoutReminderStorage.key, // workout_reminders_v1
    AppearanceStorage.appearanceKey, // appearance_mode
  ];

  /// Deterministic, filesystem-safe default filename, e.g.
  /// `FitFlow-backup-20260930-161500.json` (local wall-clock of [now]).
  static String defaultFileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year.toString().padLeft(4, '0')}${two(now.month)}'
        '${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'FitFlow-backup-$stamp.$fileExtension';
  }
}
