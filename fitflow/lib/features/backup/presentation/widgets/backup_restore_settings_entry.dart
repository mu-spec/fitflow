import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compact "Backup & restore" section on the Settings screen. The full
/// workflow lives on its own route so Settings stays lightweight.
class BackupRestoreSettingsEntry extends StatelessWidget {
  const BackupRestoreSettingsEntry({super.key});

  static const Key tileKey = Key('backup_restore_settings_tile');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          BackupCopy.settingsTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimens.itemGap),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          ),
          child: ListTile(
            key: tileKey,
            leading: const Icon(Icons.save_alt_rounded),
            title: const Text(BackupCopy.settingsTitle),
            subtitle: const Text(BackupCopy.settingsSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go(AppRoutes.backupRestore),
          ),
        ),
      ],
    );
  }
}
