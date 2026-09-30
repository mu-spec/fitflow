import 'package:fitflow/features/backup/domain/backup_reminder_preferences.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:flutter/foundation.dart';

/// The logical, user-owned FitFlow data carried by a backup.
///
/// Built from PERSISTED data (never widget state) and consumed by the
/// restore transaction. Collections are unmodifiable.
@immutable
class FitFlowBackupData {
  FitFlowBackupData({
    required this.userFitnessProfile,
    required this.capabilityProfile,
    required this.adaptiveProgressionEvidence,
    required List<CompletedWorkout> workoutHistory,
    required List<CustomWorkoutTemplate> customWorkouts,
    required this.adaptivePrograms,
    required this.workoutReminders,
    required this.appearance,
  })  : workoutHistory = List<CompletedWorkout>.unmodifiable(workoutHistory),
        customWorkouts =
            List<CustomWorkoutTemplate>.unmodifiable(customWorkouts);

  /// `null` when the device has no (valid) profile.
  final UserFitnessProfile? userFitnessProfile;

  /// `null` when the device has no complete capability profile.
  final CapabilityProfile? capabilityProfile;
  final AdaptiveProgressionEvidence adaptiveProgressionEvidence;

  /// Newest first; bounded by the app's retained history (max 100).
  final List<CompletedWorkout> workoutHistory;

  /// Most recently updated first.
  final List<CustomWorkoutTemplate> customWorkouts;

  /// Program progress only — never built-in definitions.
  final AdaptiveProgramsState adaptivePrograms;
  final BackupReminderPreferences workoutReminders;
  final AppearanceMode appearance;

  FitFlowBackupData copyWith({
    UserFitnessProfile? userFitnessProfile,
    bool clearProfile = false,
    CapabilityProfile? capabilityProfile,
    bool clearCapabilityProfile = false,
    AdaptiveProgressionEvidence? adaptiveProgressionEvidence,
    List<CompletedWorkout>? workoutHistory,
    List<CustomWorkoutTemplate>? customWorkouts,
    AdaptiveProgramsState? adaptivePrograms,
    BackupReminderPreferences? workoutReminders,
    AppearanceMode? appearance,
  }) {
    return FitFlowBackupData(
      userFitnessProfile:
          clearProfile ? null : (userFitnessProfile ?? this.userFitnessProfile),
      capabilityProfile: clearCapabilityProfile
          ? null
          : (capabilityProfile ?? this.capabilityProfile),
      adaptiveProgressionEvidence:
          adaptiveProgressionEvidence ?? this.adaptiveProgressionEvidence,
      workoutHistory: workoutHistory ?? this.workoutHistory,
      customWorkouts: customWorkouts ?? this.customWorkouts,
      adaptivePrograms: adaptivePrograms ?? this.adaptivePrograms,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      appearance: appearance ?? this.appearance,
    );
  }

  int get startedProgramCount => adaptivePrograms.progressByProgram.length;

  int get completedProgramSessionCount =>
      adaptivePrograms.progressByProgram.values
          .fold(0, (sum, p) => sum + p.completions.length);
}

/// Versioned file envelope around [FitFlowBackupData].
@immutable
class FitFlowBackupEnvelope {
  FitFlowBackupEnvelope({
    required DateTime createdAtUtc,
    required this.data,
    this.schemaVersion = 1,
  }) : createdAtUtc = createdAtUtc.toUtc();

  final int schemaVersion;
  final DateTime createdAtUtc;
  final FitFlowBackupData data;
}
