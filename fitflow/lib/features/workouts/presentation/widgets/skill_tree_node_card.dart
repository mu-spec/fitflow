import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:flutter/material.dart';

/// Readable, non-game-like exercise node with independent level and setup fit.
class SkillTreeNodeCard extends StatelessWidget {
  const SkillTreeNodeCard({
    super.key,
    required this.node,
    required this.totalSteps,
    required this.familyNodes,
    required this.onViewExercise,
  });

  final ExerciseSkillTreeNode node;
  final int totalSteps;
  final List<ExerciseSkillTreeNode> familyNodes;
  final VoidCallback onViewExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final levelLabel = trainingDifficultyLabel(context.l10n, node.difficulty);
    final equipment = node.exercise.requiredEquipment
        .where((item) => item != WorkoutEquipment.none)
        .map((item) => equipmentLabel(context.l10n, item))
        .toList()
      ..sort();
    final equipmentText = equipment.isEmpty
        ? context.l10n.trainingNoEquipment
        : equipment.join(', ');

    // Resolve only explicit catalog links within this family. Display order
    // alone is not evidence of an edge, especially for branching families.
    final byId = {for (final member in familyNodes) member.exercise.id: member};
    final easier = byId[node.exercise.easierVariationId];
    final harder = byId[node.exercise.harderVariationId];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('skill_step_${node.exercise.id}'),
        tilePadding: const EdgeInsets.all(12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurface,
          child: Text('${node.position}'),
        ),
        title: Text(node.exercise.name, style: theme.textTheme.titleMedium),
        subtitle:
            Text(_levelStatusLabel(context), style: theme.textTheme.bodySmall),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitFlowExerciseImage.thumbnail(
                exerciseId: node.exercise.id, width: 64, height: 64),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('$levelLabel · $equipmentText'),
                  const SizedBox(height: 6),
                  Text(_setupStatusLabel(context)),
                  for (final issue in node.setupIssueLabels)
                    Text(issue, style: theme.textTheme.bodySmall),
                ])),
          ]),
          if (easier != null || harder != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(spacing: 12, runSpacing: 6, children: [
                  if (easier != null)
                    Text(
                        '${context.l10n.trainingEasier}: ${easier.exercise.name}',
                        style: theme.textTheme.bodySmall),
                  if (harder != null)
                    Text(
                        '${context.l10n.trainingHarder}: ${harder.exercise.name}',
                        style: theme.textTheme.bodySmall),
                ])),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewExercise,
                child: Text(context.l10n.trainingViewExercise),
              )),
        ],
      ),
    );
  }

  String _levelStatusLabel(BuildContext context) {
    switch (node.status) {
      case ExerciseSkillTreeNodeStatus.fitsCurrentLevel:
        return context.l10n.trainingFitsLevel;
      case ExerciseSkillTreeNodeStatus.aboveCurrentLevel:
        return context.l10n.trainingAboveLevel;
      case ExerciseSkillTreeNodeStatus.movementLevelUnavailable:
        return context.l10n.trainingLevelUnavailable;
    }
  }

  String _setupStatusLabel(BuildContext context) {
    switch (node.setupStatus) {
      case ExerciseSkillTreeSetupStatus.fitsSetup:
        return context.l10n.trainingFitsSetup;
      case ExerciseSkillTreeSetupStatus.needsSetupChange:
        return context.l10n.trainingNeedsSetup;
      case ExerciseSkillTreeSetupStatus.setupDetailsUnavailable:
        return context.l10n.trainingSetupUnavailable;
    }
  }
}
