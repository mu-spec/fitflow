import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerSectionBreakView extends StatelessWidget {
  const WorkoutPlayerSectionBreakView({super.key, required this.state});
  final WorkoutPlayerState state;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final warmup = state.sectionType == WorkoutSectionType.warmup;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xl),
        child: Column(children: [
          ExcludeSemantics(
              child: Icon(Icons.check_circle_outline_rounded,
                  color: FitFlowTheme.of(context).success, size: 48)),
          const SizedBox(height: FitFlowSpace.md),
          Semantics(
              header: true,
              child: Text(warmup ? l.flowWarmupComplete : l.flowMainComplete,
                  style: text.headlineMedium, textAlign: TextAlign.center)),
          const SizedBox(height: FitFlowSpace.sm),
          Text(warmup ? l.flowMainNext : l.flowCooldownNext,
              style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowContinueHelp,
              style: text.bodyMedium, textAlign: TextAlign.center),
        ]));
  }
}
