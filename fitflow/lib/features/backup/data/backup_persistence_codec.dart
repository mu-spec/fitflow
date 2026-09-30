import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';

/// Maps validated backup data onto the exact raw SharedPreferences values the
/// existing app storages read — using each storage's own encoder, so restore
/// never invents a second persistence format.
///
/// `null` means "the key must be absent after restore" (REPLACE semantics).
class BackupPersistenceCodec {
  BackupPersistenceCodec._();

  static Map<String, String?> rawValuesFor(FitFlowBackupData data) => {
        UserFitnessProfileStorage.profileKey: data.userFitnessProfile == null
            ? null
            : UserFitnessProfileStorage.encode(data.userFitnessProfile!),
        CapabilityProfileStorage.profileKey: data.capabilityProfile == null
            ? null
            : CapabilityProfileStorage.encode(data.capabilityProfile!),
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            AdaptiveProgressionEvidenceStorage.encode(
                data.adaptiveProgressionEvidence),
        WorkoutHistoryStorage.key:
            WorkoutHistoryStorage.encode(data.workoutHistory),
        CustomWorkoutStorage.key:
            CustomWorkoutStorage.encode(data.customWorkouts),
        AdaptiveProgramsStorage.key:
            AdaptiveProgramsStorage.encode(data.adaptivePrograms),
        // Reminder USER intent only; timezone id intentionally absent so M17
        // reconciles against the current device timezone.
        WorkoutReminderStorage.key: WorkoutReminderStorage.encode(
            data.workoutReminders.toPreferences()),
        AppearanceStorage.appearanceKey: data.appearance.name,
      };

  /// Sanity guard: the codec must cover exactly the owned keys.
  static bool coversOwnedKeys(Map<String, String?> values) =>
      values.length == BackupFormat.ownedPreferenceKeys.length &&
      BackupFormat.ownedPreferenceKeys.every(values.containsKey);
}
