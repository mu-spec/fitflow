import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:flutter/material.dart';

/// Settings section headings use a quiet, branded role and remain headings to
/// assistive technology.
class UtilityHeading extends StatelessWidget {
  const UtilityHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFlowSpace.md,
          FitFlowSpace.lg,
          FitFlowSpace.md,
          FitFlowSpace.xs,
        ),
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FitFlowTheme.of(context).brand,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
}

/// Settings disclosures use one restrained V2 surface per coherent group.
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
  Widget build(BuildContext context) => FitFlowV2InfoSurface(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: FitFlowSpace.md,
            vertical: FitFlowSpace.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            FitFlowSpace.md,
            FitFlowSpace.xs,
            FitFlowSpace.md,
            FitFlowSpace.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Semantics(
            header: true,
            child: Text(title),
          ),
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
