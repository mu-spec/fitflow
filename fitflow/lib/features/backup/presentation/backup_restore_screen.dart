import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
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
    final confirmed = await FitFlowConfirmDialog.show(
      context,
      title: BackupCopy.confirmTitle,
      message: '${BackupCopy.confirmBody}\n\n${BackupCopy.confirmNoMerge}',
      confirmLabel: BackupCopy.restore,
      cancelLabel: BackupCopy.cancel,
      destructive: true,
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
    final visual = FitFlowVisualV2.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final titleScale = MediaQuery.textScalerOf(context).scale(16);
    final largeText = titleScale > 20;

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        toolbarHeight: largeText ? (titleScale > 28 ? 120 : 104) : null,
        title: Semantics(
          header: true,
          child: Text(context.l10n.backupScreenTitle),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FitFlowLayout.maxReadableWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                viewportWidth < 360
                    ? FitFlowSpace.md
                    : FitFlowSpace.screenHorizontal,
                FitFlowSpace.md,
                viewportWidth < 360
                    ? FitFlowSpace.md
                    : FitFlowSpace.screenHorizontal,
                FitFlowSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FitFlowV2InfoSurface(
                    tonal: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: FitFlowSpace.sm),
                        Expanded(
                          child: Text(
                            BackupCopy.storageNote,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  _SectionCard(
                    icon: Icons.save_alt_rounded,
                    title: BackupCopy.createTitle,
                    description: BackupCopy.createDescription,
                    action: FilledButton.icon(
                      key: BackupRestoreScreen.createButtonKey,
                      onPressed: state.isBusy ? null : controller.createBackup,
                      icon: state.phase == BackupRestorePhase.creating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: ExcludeSemantics(
                                child: Icon(Icons.hourglass_top, size: 18),
                              ),
                            )
                          : const ExcludeSemantics(
                              child: Icon(Icons.download_rounded),
                            ),
                      label: Text(
                        state.phase == BackupRestorePhase.creating
                            ? context.l10n.utilitySaving
                            : context.l10n.backupCreate,
                      ),
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  _SectionCard(
                    icon: Icons.restore_rounded,
                    title: BackupCopy.restoreTitle,
                    description: BackupCopy.restoreDescription,
                    action: OutlinedButton.icon(
                      key: BackupRestoreScreen.chooseFileButtonKey,
                      onPressed:
                          state.isBusy ? null : controller.pickAndValidate,
                      icon: const ExcludeSemantics(
                        child: Icon(Icons.folder_open_rounded),
                      ),
                      label: Text(
                        state.phase == BackupRestorePhase.picking
                            ? context.l10n.utilityUpdating
                            : context.l10n.backupChooseFile,
                      ),
                    ),
                  ),
                  if (state.preview != null) ...[
                    const SizedBox(height: FitFlowSpace.md),
                    BackupPreviewCard(
                      preview: state.preview!,
                      isBusy: state.phase == BackupRestorePhase.restoring,
                      onRestore: _confirmRestore,
                      onDiscard: controller.discardPending,
                    ),
                  ],
                  const SizedBox(height: FitFlowSpace.md),
                  FitFlowV2InfoSurface(
                    tonal: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: FitFlowSpace.sm),
                        Expanded(
                          child: Text(
                            BackupCopy.privacyNote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
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
    return FitFlowV2InfoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: FitFlowSpace.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: FitFlowSpace.md),
          action,
        ],
      ),
    );
  }
}
