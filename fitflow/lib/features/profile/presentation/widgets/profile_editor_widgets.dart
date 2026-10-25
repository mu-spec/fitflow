import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
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
              child: LayoutBuilder(builder: (context, constraints) {
                final save = FilledButton.icon(
                  onPressed: enabled && !saving ? onSave : null,
                  icon: Icon(saving ? Icons.hourglass_top : Icons.check),
                  label: Text(saving ? l.utilitySaving : l.utilitySave),
                );
                final cancel = TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(context).maybePop(),
                  child: Text(l.utilityCancel),
                );
                if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    constraints.maxWidth < 280) {
                  return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [save, cancel]);
                }
                return Row(children: [
                  cancel,
                  const SizedBox(width: 12),
                  Expanded(child: save)
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile-only expandable group. It follows system motion and keeps all
/// existing profile choices in a compact expandable section.
class ProfileDisclosure extends StatefulWidget {
  const ProfileDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? summary;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ProfileDisclosure> createState() => _ProfileDisclosureState();
}

class _ProfileDisclosureState extends State<ProfileDisclosure> {
  late bool _expanded = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) => ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        minTileHeight: 56,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 0,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          0,
          FitFlowSpace.xs,
          0,
          FitFlowSpace.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Semantics(
          header: true,
          child: Text(widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
        subtitle: _expanded || widget.summary == null
            ? null
            : Text(widget.summary!,
                style: Theme.of(context).textTheme.bodySmall),
        expansionAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
        ),
        children: widget.children,
      );
}

/// Compact editor-only selection row; drafts remain editor-owned.
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
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 4,
        minTileHeight: 48,
        enabled: enabled,
        selected: selected,
        onTap: enabled ? onSelected : null,
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: helperText == null ? null : Text(helperText!),
        trailing: ExcludeSemantics(
            child: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ));
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
