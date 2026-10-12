import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_v2_setup.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Integrated into the existing welcome step; no extra route or setup action.
class OnboardingIntro extends StatelessWidget {
  const OnboardingIntro({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    Widget benefit(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(child: Icon(icon, color: colors.brand, size: 22)),
          const SizedBox(width: FitFlowSpace.sm),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: FitFlowSpace.xxs),
                Text(body,
                    style:
                        text.bodyMedium?.copyWith(color: colors.textSecondary)),
              ])),
        ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitFlowV2HeroSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.onboardingIntroEyebrow,
            style: text.labelSmall?.copyWith(color: v.action)),
        const SizedBox(height: FitFlowSpace.sm),
        if (MediaQuery.textScalerOf(context).scale(16) > 22)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.onboardingIntroTitle,
                style: text.headlineMedium?.copyWith(color: v.onHero)),
            const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FitFlowV2AdaptiveMotif(size: 56)),
          ])
        else
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Text(l.onboardingIntroTitle,
                    style: text.headlineMedium?.copyWith(color: v.onHero))),
            const SizedBox(width: FitFlowSpace.xs),
            const FitFlowV2AdaptiveMotif(size: 88),
          ]),
        const SizedBox(height: FitFlowSpace.sm),
        Text(l.onboardingIntroSimple,
            style: text.labelLarge?.copyWith(color: v.heroSecondary)),
      ])),
      const SizedBox(height: FitFlowSpace.sm),
      benefit(Icons.tune_rounded, l.onboardingIntroLevel,
          l.onboardingIntroLevelBody),
      benefit(Icons.schedule_outlined, l.onboardingIntroTime,
          l.onboardingIntroTimeBody),
    ]);
  }
}
