import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// A representative family member, never a recommendation or unlock state.
class SkillTreeFamilyCard extends StatelessWidget {
  const SkillTreeFamilyCard(
      {super.key, required this.tree, required this.onTap});
  final ExerciseSkillTree tree;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final level = tree.currentMovementLevel;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitFlowExerciseImage.hero(
              exerciseId: tree.easiest.exercise.id, width: 88, height: 66),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tree.displayName,
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(l.trainingSteps(tree.nodeCount), style: text.bodySmall),
              const SizedBox(height: 4),
              Text(
                  level == null
                      ? l.trainingLevelUnavailable
                      : l.trainingMovementLevel(
                          tree.movementName, trainingLevelLabel(l, level)),
                  style: text.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ]),
      ),
    );
  }
}
