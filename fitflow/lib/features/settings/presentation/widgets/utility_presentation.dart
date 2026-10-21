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
          FitFlowSpace.md,
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
class UtilityDisclosure extends StatelessWidget {
  const UtilityDisclosure({
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
  Widget build(BuildContext context) => ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: FitFlowSpace.xs,
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
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final line in summary.split('\n'))
            Text(line, style: Theme.of(context).textTheme.bodySmall)
        ]),
        expansionAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
        ),
        children: children,
      );
}
