import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
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
    final theme = FitFlowTheme.of(context);
    final mediaSize =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ? 64.0 : 72.0;
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
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: FitFlowRadius.mediumBorder,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xs),
              child: Row(
                children: [
                  FitFlowExerciseImage.thumbnail(
                    exerciseId: exercise.id,
                    width: mediaSize,
                    height: mediaSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (focus.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            focus,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: theme.textSecondary),
                          ),
                        ],
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
