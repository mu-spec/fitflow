import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_design.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Readable questions and stable actions on a clean white surface.
///
/// The step is one white page: progress, heading, description, the step's own
/// options, then Back/Continue. Short windows scroll as a whole, tall ones keep
/// the actions pinned. No photography, scrim or darkened overlay is involved.
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
    final text = Theme.of(context).textTheme;

    final backStyle = TextButton.styleFrom(
      foregroundColor: OnboardingColors.heading,
      disabledForegroundColor: OnboardingColors.disabledInk,
      minimumSize: const Size(64, 52),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    final continueStyle = FilledButton.styleFrom(
      backgroundColor: OnboardingColors.accentDeep,
      foregroundColor: Colors.white,
      disabledBackgroundColor: OnboardingColors.disabledSurface,
      disabledForegroundColor: OnboardingColors.disabledInk,
      minimumSize: const Size(0, 52),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final actions = Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(children: [
          TextButton(
              style: backStyle,
              onPressed: canGoBack && !saving ? onBack : null,
              child: Text(context.l10n.back)),
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton(
                  style: continueStyle,
                  onPressed: canContinue && !saving ? onContinue : null,
                  child: Text(
                      saving ? context.l10n.onboardingSaving : trailingLabel,
                      textAlign: TextAlign.center))),
        ]));

    Widget body() =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
              header: true,
              child: Text(title,
                  style: text.headlineSmall?.copyWith(
                      color: OnboardingColors.heading,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -.3))),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(description!,
                style: text.bodyMedium?.copyWith(
                    color: OnboardingColors.body, height: 1.45)),
          ],
          const SizedBox(height: 20),
          content,
          if (error != null) ...[
            const SizedBox(height: 12),
            Semantics(
                liveRegion: true,
                child: OnboardingSurface(
                    background: OnboardingColors.errorSurface,
                    borderColor: OnboardingColors.errorBorder,
                    child: Text(error!,
                        style: text.bodyMedium
                            ?.copyWith(color: OnboardingColors.error)))),
          ],
          const SizedBox(height: 8),
        ]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: OnboardingColors.page,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: OnboardingColors.border),
        child: Scaffold(
            backgroundColor: OnboardingColors.page,
            body: SafeArea(
              child: FitFlowMaxWidth(
                child: LayoutBuilder(builder: (context, constraints) {
                  final progress = Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      child: OnboardingProgress(
                          step: step, totalSteps: totalSteps));
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: constraints.maxHeight < 400
                          ? SingleChildScrollView(
                              key: ValueKey('short_$step'),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [progress, body(), actions]))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                progress,
                                Expanded(
                                    child: SingleChildScrollView(
                                        key: ValueKey('step_$step'),
                                        child: body())),
                                actions,
                              ]));
                }),
              ),
            )));
  }
}
