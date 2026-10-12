import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_v2_setup.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// V2 presentation only. Profile's legacy option card remains unchanged.
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
    final v = FitFlowVisualV2.of(context);
    final colors = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    final ink = selected ? v.onHero : colors.textPrimary;
    final secondary = selected ? v.heroSecondary : colors.textSecondary;
    final accent = selected ? v.action : colors.brand;
    final title = Text(label, style: text.titleSmall?.copyWith(color: ink));
    final subtitle = helperText == null
        ? null
        : Text(helperText!, style: text.bodySmall?.copyWith(color: secondary));
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
        child: FitFlowV2SelectionSurface(
          selected: selected,
          child: multiSelect
              ? CheckboxListTile(
                  dense: true,
                  value: selected,
                  onChanged: (_) => onSelected(),
                  title: title,
                  subtitle: subtitle,
                  activeColor: v.action,
                  checkColor: v.onAction,
                  side: BorderSide(
                      color: selected ? v.action : colors.textMuted,
                      width: 1.5),
                  shape: const RoundedRectangleBorder(
                      borderRadius: FitFlowRadius.mediumBorder),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: FitFlowSpace.sm),
                  visualDensity: VisualDensity.standard,
                )
              : InkWell(
                  onTap: onSelected,
                  borderRadius: FitFlowRadius.mediumBorder,
                  focusColor: accent.withValues(alpha: .20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: FitFlowSpace.sm,
                          vertical: FitFlowSpace.xs),
                      child: Row(children: [
                        if (icon != null) ...[
                          ExcludeSemantics(
                              child: Container(
                                  padding:
                                      const EdgeInsets.all(FitFlowSpace.xs),
                                  decoration: BoxDecoration(
                                      color: selected
                                          ? v.onHero.withValues(alpha: .08)
                                          : v.tint,
                                      borderRadius: FitFlowRadius.smallBorder),
                                  child: Icon(icon, color: accent, size: 20))),
                          const SizedBox(width: FitFlowSpace.sm),
                        ],
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              title,
                              if (subtitle != null) ...[
                                const SizedBox(height: FitFlowSpace.xxs),
                                subtitle,
                              ]
                            ])),
                        const SizedBox(width: FitFlowSpace.xs),
                        ExcludeSemantics(
                            child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: selected ? v.action : colors.textMuted,
                                size: 22)),
                      ]),
                    ),
                  ),
                ),
        ),
      )),
    );
  }
}
