import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress(
      {super.key, required this.step, required this.totalSteps});
  final int step, totalSteps;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.onboardingProgress(step, totalSteps);
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: FitFlowSpace.xs),
        TweenAnimationBuilder<double>(
          tween: Tween(end: step / totalSteps),
          duration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
          builder: (context, value, _) =>
              LinearProgressIndicator(value: value, minHeight: 4),
        ),
      ]),
    );
  }
}
