import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Stable progress/actions; only the question content enters. On short windows
/// actions join the scroll view so large text never consumes the content viewport.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell(
      {super.key,
      required this.step,
      required this.totalSteps,
      required this.title,
      required this.content,
      required this.canGoBack,
      required this.canContinue,
      required this.trailingLabel,
      required this.onBack,
      required this.onContinue,
      this.description,
      this.instruction,
      this.error,
      this.saving = false});
  final int step, totalSteps;
  final String title, trailingLabel;
  final String? description, instruction, error;
  final Widget content;
  final bool canGoBack, canContinue, saving;
  final VoidCallback onBack, onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final actions = Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: Row(children: [
        FitFlowTertiaryButton(
            label: context.l10n.back,
            onPressed: canGoBack && !saving ? onBack : null),
        const SizedBox(width: FitFlowSpace.sm),
        Expanded(
            child: FilledButton(
          onPressed: canContinue && !saving ? onContinue : null,
          child: Text(saving ? context.l10n.onboardingSaving : trailingLabel,
              textAlign: TextAlign.center),
        )),
      ]),
    );
    Widget body() => TweenAnimationBuilder<double>(
          key: ValueKey(step),
          tween: Tween(begin: 0, end: 1),
          duration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium)),
            if (description != null) ...[
              const SizedBox(height: FitFlowSpace.xs),
              Text(description!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary)),
            ],
            if (instruction != null) ...[
              const SizedBox(height: FitFlowSpace.sm),
              Text(instruction!,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.textSecondary)),
            ],
            const SizedBox(height: FitFlowSpace.xl),
            content,
            if (error != null) ...[
              const SizedBox(height: FitFlowSpace.md),
              Semantics(
                  liveRegion: true,
                  child: Text(error!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.error))),
            ],
          ]),
        );
    return Scaffold(
        body: SafeArea(
            child: FitFlowMaxWidth(
      maxWidth: FitFlowLayout.maxReadableWidth,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final padding =
            compact ? FitFlowSpace.md : FitFlowSpace.screenHorizontal;
        final short = constraints.maxHeight < 400;
        final progress = Padding(
          padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
          child: OnboardingProgress(step: step, totalSteps: totalSteps),
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: short
              ? SingleChildScrollView(
                  key: ValueKey('short_$step'),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [progress, body(), actions]))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      progress,
                      Expanded(
                          child: SingleChildScrollView(
                              key: ValueKey('step_$step'), child: body())),
                      actions,
                    ]),
        );
      }),
    )));
  }
}
