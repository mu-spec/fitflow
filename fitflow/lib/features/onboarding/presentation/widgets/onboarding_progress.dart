import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_design.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Brand row plus the step count and one segment per step.
///
/// The count stays a live-region label, so progress is announced in words; the
/// segments are decorative and use light grey for steps not reached yet and the
/// icon green for the steps completed so far.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress(
      {super.key, required this.step, required this.totalSteps});
  final int step, totalSteps;
  @override
  Widget build(BuildContext context) {
    final label = context.l10n.onboardingProgress(step, totalSteps);
    final text = Theme.of(context).textTheme;
    return Semantics(
        label: label,
        liveRegion: true,
        excludeSemantics: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(context.l10n.homeBrand,
                    style: text.labelLarge?.copyWith(
                        color: OnboardingColors.heading,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5))),
            Text(label,
                style: text.labelMedium?.copyWith(
                    color: OnboardingColors.muted,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: FitFlowSpace.sm),
          Row(children: [
            for (var i = 0; i < totalSteps; i++) ...[
              if (i > 0) const SizedBox(width: FitFlowSpace.xxs),
              Expanded(
                  child: AnimatedContainer(
                key: ValueKey('setup_segment_$i'),
                duration: SystemMotion.micro(context),
                height: 4,
                decoration: BoxDecoration(
                    borderRadius: FitFlowRadius.pillBorder,
                    color: i < step
                        ? OnboardingColors.accent
                        : OnboardingColors.track),
              )),
            ],
          ]),
        ]));
  }
}
