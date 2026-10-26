import 'package:fitflow/core/design/fitflow_layout.dart';
import 'setup_photo_background.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Readable questions and stable actions; short windows scroll as a whole.
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

  // Editorial imagery illustrates setup, never a promised workout prescription.
  static const _photos = [
    'squat_bodyweight',
    'lunge_reverse',
    'pushup_wall',
    'march_in_place',
    'squat_chair',
    'row_bent_over_dumbbell',
    'hamstring_stretch_standing',
    'single_leg_stand'
  ];

  @override
  Widget build(BuildContext context) =>
      SetupPhotoTheme(child: Builder(builder: (context) {
        final theme = Theme.of(context);
        final actions = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              TextButton(
                  onPressed: canGoBack && !saving ? onBack : null,
                  child: Text(context.l10n.back)),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: canContinue && !saving ? onContinue : null,
                      child: Text(
                          saving
                              ? context.l10n.onboardingSaving
                              : trailingLabel,
                          textAlign: TextAlign.center))),
            ]));
        Widget body() =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 16),
              SetupPhotoPanel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Semantics(
                        header: true,
                        child: Text(title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600))),
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ])),
              const SizedBox(height: 16),
              content,
              if (error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                    liveRegion: true,
                    child: SetupPhotoPanel(
                        child: Text(error!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.error)))),
              ],
              const SizedBox(height: 8),
            ]);
        return SetupPhotoBackground(
            exerciseId: _photos[(step - 1).clamp(0, 7)],
            child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(child: FitFlowMaxWidth(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final progress = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: SetupPhotoPanel(
                            child: OnboardingProgress(
                                step: step, totalSteps: totalSteps)));
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
                ))));
      }));
}
