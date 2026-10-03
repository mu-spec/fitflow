import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dedicated Manual Local Backup & Restore screen (M18).
///
/// Presentation only: file access and persistence go through
/// [BackupRestoreController]; this widget never touches `FilePicker` or
/// `SharedPreferences`.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  static const Key createButtonKey = Key('backup_create_button');
  static const Key chooseFileButtonKey = Key('backup_choose_file_button');

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  Future<void> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(BackupCopy.confirmTitle),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(BackupCopy.confirmBody),
            SizedBox(height: 12),
            Text(BackupCopy.confirmNoMerge),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(BackupCopy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(BackupCopy.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(backupRestoreControllerProvider.notifier).confirmRestore();
  }

  void _handleStateChange(
      BackupRestoreState? previous, BackupRestoreState next) {
    if (!mounted) return;
    final message = next.message;
    if (message != null && message != previous?.message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(backupRestoreControllerProvider.notifier).clearMessage();
    }
    final outcome = next.outcome;
    if (outcome != null && outcome != previous?.outcome) {
      ref.read(backupRestoreControllerProvider.notifier).clearOutcome();
      if (outcome == BackupRestoreOutcome.success ||
          outcome == BackupRestoreOutcome.successRemindersNeedAttention) {
        // Re-enter through the normal start gates (onboarding / assessment /
        // home) instead of forcing Home.
        context.go(AppRoutes.splash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupRestoreControllerProvider, _handleStateChange);
    final state = ref.watch(backupRestoreControllerProvider);
    final controller = ref.read(backupRestoreControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.backupScreenTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(BackupCopy.storageNote,
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  _SectionCard(
                    icon: Icons.save_alt_rounded,
                    title: BackupCopy.createTitle,
                    description: BackupCopy.createDescription,
                    action: Semantics(
                      button: true,
                      enabled: !state.isBusy,
                      label: state.phase == BackupRestorePhase.creating
                          ? 'Creating backup'
                          : BackupCopy.createButton,
                      hint: BackupCopy.createDescription,
                      child: FilledButton.icon(
                      key: BackupRestoreScreen.createButtonKey,
                      onPressed: state.isBusy ? null : controller.createBackup,
                      icon: state.phase == BackupRestorePhase.creating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(context.l10n.backupCreate),
                    ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    icon: Icons.restore_rounded,
                    title: BackupCopy.restoreTitle,
                    description: BackupCopy.restoreDescription,
                    action: Semantics(
                      button: true,
                      enabled: !state.isBusy,
                      label: BackupCopy.chooseFileButton,
                      hint: BackupCopy.restoreDescription,
                      child: OutlinedButton.icon(
                      key: BackupRestoreScreen.chooseFileButtonKey,
                      onPressed:
                          state.isBusy ? null : controller.pickAndValidate,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(context.l10n.backupChooseFile),
                    ),
                    ),
                  ),
                  if (state.preview != null) ...[
                    const SizedBox(height: AppDimens.itemGap),
                    BackupPreviewCard(
                      preview: state.preview!,
                      isBusy: state.phase == BackupRestorePhase.restoring,
                      onRestore: _confirmRestore,
                      onDiscard: controller.discardPending,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          BackupCopy.privacyNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppDimens.itemGap),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppDimens.itemGap),
            action,
          ],
        ),
      ),
    );
  }
}
