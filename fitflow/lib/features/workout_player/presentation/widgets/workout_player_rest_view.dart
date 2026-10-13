import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_workout_media.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Recovery presentation only. Rest is between sets of the current effective
/// exercise: never infer a different upcoming exercise or own a timer here.
class WorkoutPlayerRestView extends StatelessWidget {
  const WorkoutPlayerRestView({super.key, required this.state});
  final WorkoutPlayerState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    final compact = WorkoutV2Layout.largeText(context) ||
        WorkoutV2Layout.viewport(context).height < 400;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FitFlowV2InfoSurface(
        key: const ValueKey('v2_rest_recovery'),
        tonal: true,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
            header: true,
            child: WorkoutPhaseLabel(
                label: l.flowRest,
                icon: Icons.spa_outlined,
                rest: true,
                paused: state.isPaused),
          ),
          if (state.isPaused)
            Padding(
              padding: const EdgeInsets.only(top: FitFlowSpace.xs),
              child: Text(l.flowRest,
                  style: text.bodyLarge, textAlign: TextAlign.center),
            ),
          SizedBox(height: compact ? FitFlowSpace.sm : FitFlowSpace.lg),
          _RestCountdownFrame(state: state, compact: compact),
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowRestSeconds,
              style: text.bodyMedium?.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: FitFlowSpace.md),
      FitFlowV2InfoSurface(
        key: const ValueKey('v2_rest_next_set'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              l.flowNextSet(
                  state.setNumber + 1, state.totalSetsForCurrentExercise),
              style: text.labelLarge?.copyWith(color: t.brand)),
          const SizedBox(height: FitFlowSpace.xs),
          Semantics(
            header: true,
            child: Text(state.currentPrescription.exercise.name,
                style: text.titleLarge),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(workloadLabel(l, state.currentPrescription),
              style: text.bodyMedium?.copyWith(color: t.textSecondary)),
        ]),
      ),
    ]);
  }
}

/// The outline is decoration, not a recovery score or invented progress arc.
/// Existing countdown/semantics stay outside any ExcludeSemantics. The ring
/// yields height first; selecting an existing type role never clamps scaling.
class _RestCountdownFrame extends StatelessWidget {
  const _RestCountdownFrame({required this.state, required this.compact});
  final WorkoutPlayerState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 272,
            minHeight: compact ? 128 : 216),
        child: Stack(
          key: const ValueKey('v2_rest_timer_frame'),
          alignment: Alignment.center,
          children: [
            Positioned.fill(
                child: ExcludeSemantics(
              key: const ValueKey('v2_rest_ring_decoration'),
              child: DecoratedBox(
                  decoration: BoxDecoration(
                color: v.support,
                borderRadius: FitFlowRadius.pillBorder,
                border: Border.all(color: v.subtleBorder, width: 1.5),
              )),
            )),
            Padding(
              padding: const EdgeInsets.all(FitFlowSpace.md),
              child: LayoutBuilder(builder: (context, constraints) {
                final roles = [
                  if (!compact) text.displayLarge,
                  text.displayMedium,
                  text.headlineMedium,
                  text.titleLarge,
                ].whereType<TextStyle>().toList();
                final scaler = MediaQuery.textScalerOf(context);
                final characters = countdown(state.remaining).length;
                var style = roles.last;
                for (final role in roles) {
                  if (scaler.scale(role.fontSize!) * characters <=
                      constraints.maxWidth) {
                    style = role;
                    break;
                  }
                }
                style = style.copyWith(color: t.textPrimary);
                return Center(
                  child: Theme(
                    data: theme.copyWith(
                        textTheme: text.copyWith(
                            displayLarge: style, displayMedium: style)),
                    child: WorkoutCountdown(
                      remaining: state.remaining,
                      semanticLabel: context.l10n
                          .flowRestRemaining(state.remaining.inSeconds),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
