import 'package:fitflow/features/onboarding/presentation/onboarding_design.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// One complete, accessible choice on a light card.
///
/// Unselected options sit on a light grey surface with a hairline border.
/// Selection is carried by the icon-green border and wash plus a filled glyph,
/// so the state is visible without relying on colour alone.
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
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(14);
    final glyph = icon;

    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MergeSemantics(
            child: Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: !multiSelect,
          label: selected
              ? context.l10n.choiceSelected
              : context.l10n.choiceNotSelected,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: selected
                      ? OnboardingColors.surfaceSelected
                      : OnboardingColors.surface,
                  borderRadius: radius,
                  border: Border.all(
                      width: 1.5,
                      color: selected
                          ? OnboardingColors.accent
                          : OnboardingColors.border)),
              child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onSelected,
                    borderRadius: radius,
                    child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          if (glyph != null) ...[
                            ExcludeSemantics(
                                child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: OnboardingColors
                                                .borderSoft)),
                                    child: Icon(glyph,
                                        size: 19,
                                        color: selected
                                            ? OnboardingColors.accentDeep
                                            : OnboardingColors.muted))),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(label,
                                    style: text.bodyMedium?.copyWith(
                                        color: OnboardingColors.title,
                                        fontWeight: FontWeight.w600)),
                                if (helperText != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(helperText!,
                                          style: text.bodySmall?.copyWith(
                                              color: OnboardingColors.muted,
                                              height: 1.35))),
                              ])),
                          const SizedBox(width: 10),
                          ExcludeSemantics(
                              child: Icon(
                                  multiSelect
                                      ? (selected
                                          ? Icons.check_box_rounded
                                          : Icons
                                              .check_box_outline_blank_rounded)
                                      : (selected
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded),
                                  size: 23,
                                  color: selected
                                      ? OnboardingColors.accentDeep
                                      : OnboardingColors.disabledInk)),
                        ])),
                  ))),
        )));
  }
}
