import 'package:fitflow/app/config/app_dimensions.dart';
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
      if (pattern == MovementPattern.warmup || pattern == MovementPattern.cooldown) continue;
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
    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayPatterns = patterns.take(5).toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.center_focus_strong_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Today's focus",
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayPatterns.map((pattern) {
                return Chip(
                  label: Text(pattern.label),
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
