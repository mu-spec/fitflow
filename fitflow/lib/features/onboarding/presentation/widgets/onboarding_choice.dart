import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Part 2 onboarding composition of canonical selectable/native controls.
/// The legacy option card remains unchanged for Profile editors.
class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice(
      {super.key,
      required this.label,
      this.helperText,
      this.multiSelect = false,
      required this.selected,
      required this.onSelected});
  final String label;
  final String? helperText;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FitFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
      child: MergeSemantics(
          child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: !multiSelect,
        label: selected
            ? context.l10n.choiceSelected
            : context.l10n.choiceNotSelected,
        child: multiSelect
            ? Material(
                color: selected
                    ? colors.palette.brandContainer
                    : colors.subtleSurface,
                borderRadius: FitFlowRadius.mediumBorder,
                child: CheckboxListTile(
                  dense: true,
                  value: selected,
                  onChanged: (_) => onSelected(),
                  title: Text(label,
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: helperText == null ? null : Text(helperText!),
                  shape: const RoundedRectangleBorder(
                      borderRadius: FitFlowRadius.mediumBorder),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: FitFlowSpace.md),
                ),
              )
            : FitFlowSelectableTile(
                label: label,
                subtitle: helperText,
                selected: selected,
                onTap: onSelected),
      )),
    );
  }
}
