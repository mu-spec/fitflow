import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:flutter/material.dart';

/// Primary action. Uses the themed [FilledButton] so pressed, focused,
/// and disabled states stay consistent with the rest of the app.
class FitFlowPrimaryButton extends StatelessWidget {
  const FitFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? Semantics(
            label: '$label, loading',
            liveRegion: true,
            excludeSemantics: true,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FitFlowSpace.xs,
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: SystemMotion.reduced(context)
                      ? const Icon(Icons.hourglass_top, size: 18)
                      : const CircularProgressIndicator(strokeWidth: 2),
                ),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          )
        : icon == null
            ? Text(label)
            : _LabeledIcon(icon: icon!, label: label);

    final button = FilledButton(
      onPressed: enabled ? onPressed : null,
      child: child,
    );
    return _wrap(
      button,
      expand: expand,
    );
  }
}

class FitFlowSecondaryButton extends StatelessWidget {
  const FitFlowSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child =
        icon == null ? Text(label) : _LabeledIcon(icon: icon!, label: label);
    return _wrap(
      OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      expand: expand,
    );
  }
}

class FitFlowTertiaryButton extends StatelessWidget {
  const FitFlowTertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _wrap(
      TextButton(onPressed: onPressed, child: Text(label)),
      expand: expand,
    );
  }
}

/// Icon-only action. [label] is required so the control is never unlabeled.
class FitFlowIconAction extends StatelessWidget {
  const FitFlowIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      isSelected: selected,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(
          SystemMotion.minTouchTarget,
          SystemMotion.minTouchTarget,
        ),
        foregroundColor: selected ? theme.brand : theme.textPrimary,
        backgroundColor: selected ? theme.brand.withValues(alpha: 0.12) : null,
      ),
    );
  }
}

class _LabeledIcon extends StatelessWidget {
  const _LabeledIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: FitFlowSpace.xs,
      children: [
        Icon(icon, size: 18),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

// Keep native button semantics, including screen-reader tap and focus actions.
// Excluding the button's subtree would leave a named but inoperable control.
Widget _wrap(Widget button, {required bool expand}) {
  if (!expand) return button;
  return SizedBox(width: double.infinity, child: button);
}
