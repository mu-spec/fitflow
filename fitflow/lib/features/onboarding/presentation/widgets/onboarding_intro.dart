import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Integrated into the existing welcome step; not another onboarding screen.
class OnboardingIntro extends StatelessWidget {
  const OnboardingIntro({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    Widget benefit(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExcludeSemantics(child: Icon(icon, color: colors.brand)),
            const SizedBox(width: FitFlowSpace.md),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: FitFlowSpace.xxs),
                  Text(body,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.textSecondary)),
                ])),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.onboardingIntroEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(color: colors.brand)),
      const SizedBox(height: FitFlowSpace.sm),
      Text(l10n.onboardingIntroTitle, style: theme.textTheme.displaySmall),
      const SizedBox(height: FitFlowSpace.lg),
      benefit(Icons.tune_rounded, l10n.onboardingIntroLevel,
          l10n.onboardingIntroLevelBody),
      benefit(Icons.schedule_outlined, l10n.onboardingIntroTime,
          l10n.onboardingIntroTimeBody),
      const SizedBox(height: FitFlowSpace.sm),
      Text(l10n.onboardingIntroSimple, style: theme.textTheme.labelLarge),
    ]);
  }
}
