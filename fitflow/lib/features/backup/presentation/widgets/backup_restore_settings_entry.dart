import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compact "Backup & restore" row within Settings' grouped data surface. The
/// full workflow lives on its own route so Settings stays lightweight.
class BackupRestoreSettingsEntry extends StatelessWidget {
  const BackupRestoreSettingsEntry({super.key});

  static const Key tileKey = Key('backup_restore_settings_tile');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: tileKey,
      minVerticalPadding: FitFlowSpace.xs,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FitFlowSpace.md,
      ),
      leading: ExcludeSemantics(
        child: Icon(
          Icons.save_alt_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
      title: const Text(BackupCopy.settingsTitle),
      subtitle: const Text(BackupCopy.settingsSubtitle),
      trailing: const ExcludeSemantics(
        child: Icon(Icons.chevron_right_rounded),
      ),
      onTap: () => context.go(AppRoutes.backupRestore),
    );
  }
}
