import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Lazy, media-led library row: name, movement/focus, and equipment only.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({super.key, required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = FitFlowVisualV2.of(context);
    final theme = FitFlowTheme.of(context);
    final equipment = exercise.requiredEquipment;
    final equipmentText =
        equipment.isEmpty || equipment.contains(WorkoutEquipment.none)
            ? l.trainingNoEquipment
            : equipment.map((e) => equipmentLabel(l, e)).join(' · ');
    final focus = exercise.movementPattern == null
        ? exercise.primaryMuscles.map((m) => m.label).join(' · ')
        : movementPatternLabel(l, exercise.movementPattern!);

    return MergeSemantics(
      child: Material(
        color: v.support,
        shape: RoundedRectangleBorder(
          borderRadius: FitFlowRadius.mediumBorder,
          side: BorderSide(color: v.subtleBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: FitFlowRadius.mediumBorder,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FitFlowV2ExerciseMedia.forExercise(
                    exercise: exercise,
                    width: 56,
                    height: 56,
                    borderRadius: FitFlowRadius.smallBorder,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (focus.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            focus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: theme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            text: equipmentText,
                            semanticsLabel: equipmentText,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: theme.textSecondary),
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    ExcludeSemantics(
                      child: Icon(Icons.chevron_right_rounded,
                          color: theme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
