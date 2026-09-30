import 'package:fitflow/features/backup/domain/backup_reminder_preferences.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds [FitFlowBackupData] from PERSISTED data using the existing storage
/// loaders (never from possibly stale widget/provider state).
class BackupSnapshotReader {
  const BackupSnapshotReader({Future<SharedPreferences> Function()? getPrefs})
      : _getPrefs = getPrefs;

  final Future<SharedPreferences> Function()? _getPrefs;

  Future<SharedPreferences> _prefs() =>
      _getPrefs != null ? _getPrefs!() : SharedPreferences.getInstance();

  Future<FitFlowBackupData> read() async {
    final prefs = await _prefs();
    Future<SharedPreferences> samePrefs() async => prefs;

    final reminders = await WorkoutReminderStorage(getPrefs: samePrefs).load();
    return FitFlowBackupData(
      userFitnessProfile: UserFitnessProfileStorage(prefs).load(),
      capabilityProfile: CapabilityProfileStorage(prefs).load(),
      adaptiveProgressionEvidence:
          AdaptiveProgressionEvidenceStorage(prefs).load(),
      workoutHistory: WorkoutHistoryStorage(prefs).load(),
      customWorkouts: await CustomWorkoutStorage(getPrefs: samePrefs).loadAll(),
      adaptivePrograms:
          await AdaptiveProgramsStorage(getPrefs: samePrefs).load(),
      workoutReminders: BackupReminderPreferences.fromPreferences(reminders),
      appearance: await AppearanceStorage(prefs).load(),
    );
  }
}
