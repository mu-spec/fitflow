import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// One complete, accessible choice without nested icon boxes or heavy borders.
class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice(
      {super.key,
      required this.label,
      this.helperText,
      this.multiSelect = false,
      this.icon,
      required this.selected,
      required this.onSelected});
  final String label;
  final String? helperText;
  final bool multiSelect, selected;
  final IconData? icon;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: MergeSemantics(
            child: Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: !multiSelect,
          label: selected
              ? context.l10n.choiceSelected
              : context.l10n.choiceNotSelected,
          child: Material(
              color: selected
                  ? colors.primaryContainer
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onSelected,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? colors.primary
                                : Colors.transparent)),
                    child: Row(children: [
                      if (icon != null) ...[
                        ExcludeSemantics(
                            child: Icon(icon, size: 20, color: colors.primary)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(label,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            if (helperText != null)
                              Text(helperText!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant)),
                          ])),
                      const SizedBox(width: 8),
                      ExcludeSemantics(
                          child: Icon(
                              multiSelect
                                  ? (selected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank)
                                  : (selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked),
                              size: 22,
                              color: selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant)),
                    ])),
              )),
        )));
  }
}
