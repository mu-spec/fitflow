import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:flutter/material.dart';

/// Utility headings and disclosures use the established Material/theme tokens.
class UtilityHeading extends StatelessWidget {
  const UtilityHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
      );
}

class UtilityDisclosure extends StatelessWidget {
  const UtilityDisclosure(
      {super.key,
      required this.title,
      required this.summary,
      required this.children,
      this.initiallyExpanded = false});
  final String title;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(title),
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
