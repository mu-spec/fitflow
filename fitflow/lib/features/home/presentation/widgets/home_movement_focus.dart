import 'package:fitflow/features/home/presentation/widgets/home_detail_row.dart';
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
    return HomeDetailRow(
        label: context.l10n.homeFocus,
        value: patterns
            .take(5)
            .map((p) => movementPatternLabel(context.l10n, p))
            .join(' · '));
  }
}
