import 'package:fitflow/core/design/fitflow_typography.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Phase identity is text + icon, never color alone. No tick-driven animation.
class WorkoutPhaseLabel extends StatelessWidget {
  const WorkoutPhaseLabel(
      {super.key,
      required this.label,
      required this.icon,
      this.rest = false,
      this.paused = false});
  final String label;
  final IconData icon;
  final bool rest;
  final bool paused;
  @override
  Widget build(BuildContext context) {
    final t = FitFlowTheme.of(context);
    final background = paused
        ? t.subtleSurface
        : rest
            ? t.workoutRest
            : t.workoutActive;
    final foreground = paused
        ? t.textPrimary
        : rest
            ? t.onWorkoutRest
            : t.onWorkoutActive;
    return Align(
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: SystemMotion.micro(context),
          curve: FitFlowMotion.standardCurve,
          decoration: BoxDecoration(
              color: background, borderRadius: FitFlowRadius.mediumBorder),
          child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: FitFlowSpace.md, vertical: FitFlowSpace.xs),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ExcludeSemantics(
                    child: Icon(paused ? Icons.pause_rounded : icon,
                        size: 20, color: foreground)),
                const SizedBox(width: FitFlowSpace.xs),
                Flexible(
                    child: Text(paused ? context.l10n.flowPaused : label,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: foreground))),
              ])),
        ));
  }
}

class WorkoutCountdown extends StatelessWidget {
  const WorkoutCountdown(
      {super.key, required this.remaining, required this.semanticLabel});
  final Duration remaining;
  final String semanticLabel;
  @override
  Widget build(BuildContext context) => PlayerTimerSemantics(
      label: semanticLabel,
      child: LayoutBuilder(builder: (context, constraints) {
        // Choose an existing type role, never clamp the user's text scaling.
        final text = Theme.of(context).textTheme;
        final roomy = constraints.maxWidth >=
            MediaQuery.textScalerOf(context)
                    .scale(FitFlowTypography.timer.fontSize!) *
                3.5;
        return Text(countdown(remaining),
            textAlign: TextAlign.center,
            style: roomy ? text.displayLarge : text.displayMedium);
      }));
}
