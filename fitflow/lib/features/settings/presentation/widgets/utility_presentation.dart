import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Settings section headings use a quiet, branded role and remain headings to
/// assistive technology.
class UtilityHeading extends StatelessWidget {
  const UtilityHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          FitFlowSpace.sm,
          0,
          FitFlowSpace.xs,
        ),
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FitFlowTheme.of(context).brand,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      );
}

/// Compact settings disclosures retain native expansion semantics.
class UtilityDisclosure extends StatefulWidget {
  const UtilityDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.children,
    this.initiallyExpanded = false,
    this.icon,
    this.hideSummaryWhenExpanded = false,
  });

  final String title;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? icon;
  final bool hideSummaryWhenExpanded;

  @override
  State<UtilityDisclosure> createState() => _UtilityDisclosureState();
}

class _UtilityDisclosureState extends State<UtilityDisclosure> {
  late bool _expanded = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) => ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        minTileHeight: 56,
        leading: widget.icon == null
            ? null
            : ExcludeSemantics(
                child: Icon(widget.icon,
                    size: 24, color: Theme.of(context).colorScheme.primary)),
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
        subtitle: widget.hideSummaryWhenExpanded && _expanded
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final line in widget.summary.split('\n'))
                  Text(line, style: Theme.of(context).textTheme.bodySmall)
              ]),
        expansionAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
        ),
        children: widget.children,
      );
}
