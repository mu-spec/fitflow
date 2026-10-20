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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitFlowExerciseImage.thumbnail(exerciseId: node.exercise.id),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.trainingStep(node.position, totalSteps),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.primary)),
              const SizedBox(height: 4),
              Semantics(
                  header: true,
                  child: Text(node.exercise.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500))),
            ],
          )),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          Text(levelLabel, style: theme.textTheme.bodySmall),
          Text(node.exercise.exerciseType.label,
              style: theme.textTheme.bodySmall),
          if (node.exercise.movementPattern != null)
            Text(node.exercise.movementPattern!.label,
                style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: 6),
        Text(context.l10n.trainingEquipmentFor(equipmentText),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 8),
        _SuitabilityLine(
            icon: Icons.fitness_center_outlined,
            label: _levelStatusLabel(context)),
        const SizedBox(height: 4),
        _SuitabilityLine(
            icon: Icons.tune_rounded, label: _setupStatusLabel(context)),
        for (final issue in node.setupIssueLabels)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 26),
            child: Text(issue,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ),
        if (easier != null || harder != null) ...[
          const SizedBox(height: 8),
          if (easier != null)
            Text('${context.l10n.trainingEasier}: ${easier.exercise.name}',
                style: theme.textTheme.bodySmall),
          if (harder != null)
            Text('${context.l10n.trainingHarder}: ${harder.exercise.name}',
                style: theme.textTheme.bodySmall),
        ],
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: onViewExercise,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(context.l10n.trainingViewExercise),
        ),
      ]),
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

class _SuitabilityLine extends StatelessWidget {
  const _SuitabilityLine({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
              child: Icon(icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}
