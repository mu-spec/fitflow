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
    required this.onViewExercise,
  });

  final ExerciseSkillTreeNode node;
  final int totalSteps;
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.trainingStep(node.position, totalSteps),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              node.exercise.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _DetailChip(label: levelLabel),
                _DetailChip(label: node.exercise.exerciseType.label),
                if (node.exercise.movementPattern != null)
                  _DetailChip(label: node.exercise.movementPattern!.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.trainingEquipmentFor(equipmentText),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: _levelStatusLabel(context),
                  background: node.fitsCurrentLevel == true
                      ? colors.primaryContainer
                      : colors.tertiaryContainer,
                  foreground: node.fitsCurrentLevel == true
                      ? colors.onPrimaryContainer
                      : colors.onTertiaryContainer,
                ),
                _StatusChip(
                  label: _setupStatusLabel(context),
                  background: node.fitsSetup == false
                      ? colors.errorContainer
                      : colors.secondaryContainer,
                  foreground: node.fitsSetup == false
                      ? colors.onErrorContainer
                      : colors.onSecondaryContainer,
                ),
              ],
            ),
            if (node.setupIssueLabels.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final issue in node.setupIssueLabels) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onViewExercise,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(context.l10n.trainingViewExercise),
            ),
          ],
        ),
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

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TrainingFact(label);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return TrainingFact(label, icon: Icons.info_outline);
  }
}
