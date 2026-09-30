import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_preview.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:flutter/material.dart';

/// Read-only summary of a validated backup, shown BEFORE any restore write.
class BackupPreviewCard extends StatelessWidget {
  const BackupPreviewCard({
    super.key,
    required this.preview,
    required this.onRestore,
    required this.onDiscard,
    required this.isBusy,
  });

  final FitFlowBackupPreview preview;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;
  final bool isBusy;

  static const Key restoreButtonKey = Key('backup_preview_restore_button');
  static const Key discardButtonKey = Key('backup_preview_discard_button');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localCreated = MaterialLocalizations.of(context)
        .formatMediumDate(preview.createdAtUtc.toLocal());
    final createdTime = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(preview.createdAtUtc.toLocal()));

    final rows = <(String, String)>[
      (BackupCopy.previewCreated, '$localCreated, $createdTime'),
      (
        BackupCopy.previewProfile,
        preview.hasProfile ? BackupCopy.included : BackupCopy.notIncluded
      ),
      (
        BackupCopy.previewCapability,
        preview.hasCapabilityProfile
            ? BackupCopy.included
            : BackupCopy.notIncluded
      ),
      (
        BackupCopy.previewEvidence,
        '${preview.evidencePatternCount} '
            '${preview.evidencePatternCount == 1 ? 'pattern' : 'patterns'}'
      ),
      (BackupCopy.previewHistory, '${preview.historyCount}'),
      (BackupCopy.previewCustom, '${preview.customWorkoutCount}'),
      (BackupCopy.previewProgramsStarted, '${preview.startedProgramCount}'),
      (
        BackupCopy.previewProgramSessions,
        '${preview.completedProgramSessionCount}'
      ),
      (
        BackupCopy.previewReminders,
        preview.remindersEnabled ? BackupCopy.on : BackupCopy.off
      ),
      (BackupCopy.previewAppearance, _appearanceLabel(preview.appearance)),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              BackupCopy.previewTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.itemGap),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimens.itemGap),
            FilledButton(
              key: restoreButtonKey,
              onPressed: isBusy ? null : onRestore,
              child: Text(
                  isBusy ? BackupCopy.restoring : BackupCopy.restoreButton),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: discardButtonKey,
              onPressed: isBusy ? null : onDiscard,
              child: const Text(BackupCopy.chooseDifferentFile),
            ),
          ],
        ),
      ),
    );
  }

  static String _appearanceLabel(AppearanceMode mode) => switch (mode) {
        AppearanceMode.system => 'System',
        AppearanceMode.light => 'Light',
        AppearanceMode.dark => 'Dark',
      };
}
