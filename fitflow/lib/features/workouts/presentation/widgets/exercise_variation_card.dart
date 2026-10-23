import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:flutter/material.dart';

/// Compact canonical variation row with its existing directional context.
///
/// Shows the same factual metadata as before, alongside the shared decorative
/// exercise visual. The current exercise remains non-interactive.
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
    final visual = FitFlowVisualV2.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact =
        viewport.width < 400 || viewport.height <= 400 || textScale >= 1.4;
    final mediaWidth = compact ? 56.0 : 68.0;
    final mediaHeight = mediaWidth;
    final radius = BorderRadius.circular(FitFlowRadius.medium);

    return Material(
      color: isCurrent ? visual.tint : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FitFlowExerciseImage.thumbnail(
                  key: ValueKey('exercise_variation_media_${exercise.id}'),
                  exerciseId: exercise.id,
                  width: mediaWidth,
                  height: mediaHeight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        directionLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: FitFlowTheme.of(context).brand,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: FitFlowTheme.of(context).textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metaLine(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: FitFlowTheme.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrent) ...[
                  const SizedBox(width: 4),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: FitFlowTheme.of(context).textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
