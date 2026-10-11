import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';

/// Shows unique movement patterns from main section preserving first-appearance order.
class HomeMovementFocus extends StatelessWidget {
  const HomeMovementFocus({super.key, required this.plan});

  final WorkoutPlan plan;

  List<MovementPattern> _uniqueMainPatterns() {
    final seen = <MovementPattern>{};
    final ordered = <MovementPattern>[];
    for (final pres in plan.main.exercises) {
      final pattern = pres.exercise.movementPattern;
      if (pattern == null) continue;
      // Only trainable patterns are expected in main, but include any
      if (pattern == MovementPattern.warmup ||
          pattern == MovementPattern.cooldown) {
        continue;
      }
      if (!seen.contains(pattern)) {
        seen.add(pattern);
        ordered.add(pattern);
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final patterns = _uniqueMainPatterns();
    if (patterns.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          child: Text(context.l10n.homeFocus,
              style: Theme.of(context).textTheme.titleMedium)),
      const SizedBox(height: FitFlowSpace.xs),
      Wrap(spacing: FitFlowSpace.xs, runSpacing: FitFlowSpace.xs, children: [
        for (final pattern in patterns.take(5))
          FitFlowV2Tag(movementPatternLabel(context.l10n, pattern)),
      ]),
    ]);
  }
}
