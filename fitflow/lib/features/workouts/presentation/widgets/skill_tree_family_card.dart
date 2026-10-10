import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// The resolver's factual endpoints and fit counts, not unlock progress.
class SkillTreeFamilyCard extends StatelessWidget {
  const SkillTreeFamilyCard(
      {super.key, required this.tree, required this.onTap});
  final ExerciseSkillTree tree;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final level = tree.currentMovementLevel;
    final setupCount = tree.nodes.where((n) => n.fitsSetup == true).length;
    final setupKnown = tree.nodes.every((n) => n.fitsSetup != null);
    return Card(
        child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(tree.displayName,
                              style: theme.textTheme.titleMedium)),
                      const Icon(Icons.chevron_right)
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        '${tree.movementName} · ${l.trainingSteps(tree.nodeCount)}',
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Text(
                        '${tree.easiest.exercise.name} → ${tree.hardest.exercise.name}',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text(level == null
                        ? l.trainingLevelUnavailable
                        : l.trainingMovementLevel(
                            tree.movementName, trainingLevelLabel(l, level))),
                    if (level != null) ...[
                      const SizedBox(height: 4),
                      Text(l.trainingFitCount(tree.fitsCurrentLevelCount),
                          style: theme.textTheme.bodySmall),
                      Text(l.trainingAboveCount(tree.aboveCurrentLevelCount),
                          style: theme.textTheme.bodySmall),
                    ],
                    if (setupKnown)
                      Text(l.trainingSetupCount(setupCount),
                          style: theme.textTheme.bodySmall),
                  ]),
            )));
  }
}
