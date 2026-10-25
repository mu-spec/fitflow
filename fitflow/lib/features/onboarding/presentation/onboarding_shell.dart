import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
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
      WorkoutsTheme(child: Builder(builder: (context) {
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
        final photo = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FitFlowExerciseImage.hero(
                exerciseId: _photos[(step - 1).clamp(0, 7)],
                width: 112,
                height: 84));
        Widget body() =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (step == 1 || step == totalSteps) ...[
                LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth.clamp(0.0, 340.0);
                  return Center(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FitFlowExerciseImage.hero(
                              exerciseId: _photos[step - 1],
                              width: width,
                              height: width * .75)));
                }),
                const SizedBox(height: 16),
                Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge)),
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: Semantics(
                          header: true,
                          child:
                              Text(title, style: theme.textTheme.titleLarge))),
                  const SizedBox(width: 12),
                  photo,
                ]),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              content,
              if (error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                    liveRegion: true,
                    child: Text(error!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error))),
              ],
              const SizedBox(height: 8),
            ]);
        return Scaffold(body: SafeArea(child: FitFlowMaxWidth(
          child: LayoutBuilder(builder: (context, constraints) {
            final progress = Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: OnboardingProgress(step: step, totalSteps: totalSteps));
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: constraints.maxHeight < 400
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
                                    key: ValueKey('step_$step'),
                                    child: body())),
                            actions,
                          ]));
          }),
        )));
      }));
}
