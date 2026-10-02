import 'package:fitflow/app/config/app_dimensions.dart';
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
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('Your unsaved changes will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep editing'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          8,
          AppDimens.screenPadding,
          16,
        ),
        child: FilledButton.icon(
          onPressed: enabled && !saving ? onSave : null,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Save changes'),
        ),
      ),
    );
  }
}
