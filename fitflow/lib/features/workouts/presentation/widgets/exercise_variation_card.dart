import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:flutter/material.dart';

/// Compact tappable card for an easier/harder variation.
///
/// Shows name, difficulty, primary muscles or movement, and directional label.
class ExerciseVariationCard extends StatelessWidget {
  const ExerciseVariationCard({
    super.key,
    required this.exercise,
    required this.directionLabel,
    required this.directionIcon,
    this.onTap,
    this.isCurrent = false,
  });

  final Exercise exercise;
  final String directionLabel;
  final IconData directionIcon;
  final VoidCallback? onTap;
  final bool isCurrent;

  String _metaLine(BuildContext context) {
    final parts = <String>[];
    parts.add(trainingDifficultyLabel(context.l10n, exercise.difficulty));
    if (exercise.movementPattern != null) {
      parts.add(movementPatternLabel(context.l10n, exercise.movementPattern!));
    }
    if (exercise.primaryMuscles.isNotEmpty) {
      // Show up to 2 primary muscles for compactness
      final muscles =
          exercise.primaryMuscles.take(2).map((m) => m.label).join(' • ');
      parts.add(muscles);
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final card = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(
          color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                directionIcon,
                size: 18,
                color: isCurrent
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    directionLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metaLine(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrent) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    if (isCurrent || onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: card,
      ),
    );
  }
}
