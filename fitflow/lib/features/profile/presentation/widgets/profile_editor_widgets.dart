import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Failure message shown when a profile save could not be persisted. The
/// previously persisted profile stays authoritative in this case.
const String profileEditorSaveFailedMessage =
    "Couldn't save your changes. Try again.";

/// Shows the standard "Discard changes?" confirmation for profile editors.
///
/// Pops the current route when the user chooses Discard; resolves without
/// popping when the user chooses Keep editing or dismisses the dialog.
Future<void> confirmDiscardEditorChanges(BuildContext context) async {
  final l = context.l10n;
  final discard = await FitFlowConfirmDialog.show(context,
      title: l.utilityDiscardTitle,
      message: l.utilityDiscardBody,
      confirmLabel: l.utilityDiscard,
      cancelLabel: l.utilityKeepEditing,
      destructive: true);
  if (discard == true && context.mounted) {
    context.pop();
  }
}

/// Pinned bottom save bar shared by the M19 profile editors.
///
/// The button is disabled when there is nothing new to save ([enabled] is
/// false) and while a write is in flight ([saving] is true), which prevents
/// duplicate Save presses from starting a second write.
class ProfileEditorSaveBar extends StatelessWidget {
  const ProfileEditorSaveBar({
    super.key,
    required this.enabled,
    required this.saving,
    required this.onSave,
  });

  final bool enabled;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final visual = FitFlowVisualV2.of(context);
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.support,
          border: Border(top: BorderSide(color: visual.subtleBorder)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            FitFlowSpace.md,
            FitFlowSpace.xs,
            FitFlowSpace.md,
            FitFlowSpace.sm + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FitFlowLayout.maxReadableWidth - 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: enabled && !saving ? onSave : null,
                    icon: Icon(saving ? Icons.hourglass_top : Icons.check),
                    label: Text(saving ? l.utilitySaving : l.utilitySave),
                  ),
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(context).maybePop(),
                    child: Text(l.utilityCancel),
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

/// Profile-only expandable group. It follows system motion and keeps all
/// existing profile choices inside a single, readable V2 surface.
class ProfileDisclosure extends StatelessWidget {
  const ProfileDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => FitFlowV2InfoSurface(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: FitFlowSpace.md,
            vertical: FitFlowSpace.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            FitFlowSpace.md,
            FitFlowSpace.xs,
            FitFlowSpace.md,
            FitFlowSpace.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Semantics(
            header: true,
            child: Text(title),
          ),
          subtitle: Text(summary),
          expansionAnimationStyle: AnimationStyle(
            duration: SystemMotion.standard(context),
            reverseDuration: SystemMotion.standard(context),
            curve: FitFlowMotion.standardCurve,
          ),
          children: children,
        ),
      );
}

/// The same canonical choice surface as onboarding; drafts remain editor-owned.
class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile(
      {super.key,
      required this.label,
      this.helperText,
      required this.selected,
      required this.onSelected,
      this.enabled = true});
  final String label;
  final String? helperText;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
      child: FitFlowSelectableTile(
          label: label,
          subtitle: helperText,
          selected: selected,
          enabled: enabled,
          onTap: onSelected));
}

class ProfileEditorMissingState extends StatelessWidget {
  const ProfileEditorMissingState({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: FitFlowEmptyState(
          title: context.l10n.utilityProfileMissing,
          message: context.l10n.utilityProfileSetupBody,
          action: FilledButton(
              onPressed: () => context.go(AppRoutes.onboarding),
              child: Text(context.l10n.setUpProfile))));
}
