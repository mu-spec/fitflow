/// All user-facing strings for Manual Local Backup & Restore (M18).
///
/// No cloud, sync, encryption or automatic-backup claims — FitFlow only
/// writes/reads a file wherever the user chooses.
class BackupCopy {
  BackupCopy._();

  // Settings entry
  static const settingsTitle = 'Backup & restore';
  static const settingsSubtitle =
      'Save a copy of your FitFlow data or restore it on this device.';

  // Screen
  static const screenTitle = 'Backup & restore';
  static const storageNote =
      'Your backup is stored wherever you choose. FitFlow does not upload it '
      'to a FitFlow server.';
  static const createTitle = 'Create backup';
  static const createDescription =
      'Includes your profile, movement levels, saved workout history, custom '
      'workouts, program progress, reminder preferences, and appearance.';
  static const createButton = 'Create backup';
  static const restoreTitle = 'Restore from backup';
  static const restoreDescription =
      'Replace the FitFlow data on this device with data from a backup file.';
  static const chooseFileButton = 'Choose backup file';
  static const privacyNote =
      'Backup files contain personal workout and preference data. Store them '
      'somewhere you trust.';

  // Create outcomes
  static const backupSaved = 'Backup saved.';
  static const backupSaveFailed = "Couldn't save the backup. Try again.";

  // Import validation
  static const fileTooLarge = 'This backup file is too large to import.';
  static const fileUnreadable =
      "This file couldn't be read as a FitFlow backup.";
  static const notFitFlowBackup = "This isn't a FitFlow backup file.";
  static const newerVersion =
      "This backup was created by a newer FitFlow version and can't be "
      'restored here.';
  static const unsupportedVersion = "This backup format isn't supported.";
  static const invalidData =
      "This backup contains data FitFlow can't restore safely.";

  // Preview
  static const previewTitle = 'Backup contents';
  static const previewCreated = 'Created';
  static const previewProfile = 'Profile';
  static const previewCapability = 'Movement levels';
  static const previewEvidence = 'Progression evidence';
  static const previewHistory = 'Saved workouts';
  static const previewCustom = 'Custom workouts';
  static const previewProgramsStarted = 'Programs started';
  static const previewProgramSessions = 'Program sessions completed';
  static const previewReminders = 'Reminders';
  static const previewAppearance = 'Appearance';
  static const included = 'Included';
  static const notIncluded = 'Not included';
  static const on = 'On';
  static const off = 'Off';
  static const restoreButton = 'Restore this backup';
  static const chooseDifferentFile = 'Choose a different file';

  // Confirmation dialog
  static const confirmTitle = 'Restore FitFlow backup?';
  static const confirmBody =
      'This will replace FitFlow data currently stored on this device with '
      'the data in this backup.';
  static const confirmNoMerge =
      'This restore does not merge the two sets of data.';
  static const cancel = 'Cancel';
  static const restore = 'Restore';

  // Restore outcomes
  static const restoreSucceeded = 'Backup restored.';
  static const restoreSucceededRemindersAttention =
      'Your data was restored, but workout reminders need attention.';
  static const restoreFailedRolledBack =
      'Restore failed. Your previous FitFlow data was kept.';
  static const restoreFailedRollbackIncomplete =
      "Restore couldn't be completed. Some local data may need to be restored "
      'again from a backup.';
  static const restoring = 'Restoring…';
}
