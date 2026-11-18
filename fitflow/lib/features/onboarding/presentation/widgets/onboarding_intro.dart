import 'package:fitflow/features/onboarding/presentation/onboarding_design.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Welcome overview: what the next steps will ask for.
///
/// Text and simple glyphs only - no photography, illustration or decorative
/// artwork. The copy reuses existing onboarding strings.
class OnboardingIntro extends StatelessWidget {
  const OnboardingIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;

    Widget feature(IconData glyph, String heading, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OnboardingSurface(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: OnboardingColors.accentTint,
                      borderRadius: BorderRadius.circular(11)),
                  child: Icon(glyph,
                      size: 20, color: OnboardingColors.accentDeep))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(heading,
                    style: text.titleSmall?.copyWith(
                        color: OnboardingColors.title,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: text.bodySmall
                        ?.copyWith(color: OnboardingColors.body, height: 1.4)),
              ])),
        ])));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.onboardingIntroEyebrow,
          style: text.labelSmall?.copyWith(
              color: OnboardingColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3)),
      const SizedBox(height: 12),
      feature(Icons.tune_rounded, l.onboardingIntroLevel,
          l.onboardingIntroLevelBody),
      feature(Icons.schedule_rounded, l.onboardingIntroTime,
          l.onboardingIntroTimeBody),
      const SizedBox(height: 4),
      Text(l.onboardingIntroSimple,
          style: text.bodySmall?.copyWith(color: OnboardingColors.muted)),
    ]);
  }
}
