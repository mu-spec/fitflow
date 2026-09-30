import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:flutter/foundation.dart';

/// Read-only summary shown after validation and BEFORE any restore write.
@immutable
class FitFlowBackupPreview {
  const FitFlowBackupPreview({
    required this.createdAtUtc,
    required this.hasProfile,
    required this.hasCapabilityProfile,
    required this.evidencePatternCount,
    required this.historyCount,
    required this.customWorkoutCount,
    required this.startedProgramCount,
    required this.completedProgramSessionCount,
    required this.remindersEnabled,
    required this.appearance,
  });

  factory FitFlowBackupPreview.fromEnvelope(FitFlowBackupEnvelope envelope) {
    final d = envelope.data;
    return FitFlowBackupPreview(
      createdAtUtc: envelope.createdAtUtc,
      hasProfile: d.userFitnessProfile != null,
      hasCapabilityProfile: d.capabilityProfile != null,
      evidencePatternCount: d.adaptiveProgressionEvidence.counts.values
          .where((c) => c > 0)
          .length,
      historyCount: d.workoutHistory.length,
      customWorkoutCount: d.customWorkouts.length,
      startedProgramCount: d.startedProgramCount,
      completedProgramSessionCount: d.completedProgramSessionCount,
      remindersEnabled: d.workoutReminders.enabled,
      appearance: d.appearance,
    );
  }

  final DateTime createdAtUtc;
  final bool hasProfile;
  final bool hasCapabilityProfile;

  /// Number of movement patterns with a recorded progression-evidence session.
  final int evidencePatternCount;

  /// Count of saved workouts in the backup (FitFlow keeps at most the 100
  /// most recent — this is NOT a lifetime total).
  final int historyCount;
  final int customWorkoutCount;
  final int startedProgramCount;
  final int completedProgramSessionCount;
  final bool remindersEnabled;
  final AppearanceMode appearance;
}
