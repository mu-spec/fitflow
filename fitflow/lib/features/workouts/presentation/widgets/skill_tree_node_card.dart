import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
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
    final levelLabel =
        CapabilityLevel.fromExerciseDifficulty(node.difficulty).label;
    final equipment = node.exercise.requiredEquipment
        .where((item) => item != WorkoutEquipment.none)
        .map((item) => item.label)
        .toList()
      ..sort();
    final equipmentLabel =
        equipment.isEmpty ? 'No equipment required' : equipment.join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${node.position} of $totalSteps',
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
              'Equipment: $equipmentLabel',
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
                  label: _levelStatusLabel,
                  background: node.fitsCurrentLevel == true
                      ? colors.primaryContainer
                      : colors.tertiaryContainer,
                  foreground: node.fitsCurrentLevel == true
                      ? colors.onPrimaryContainer
                      : colors.onTertiaryContainer,
                ),
                _StatusChip(
                  label: _setupStatusLabel,
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
              label: const Text('View exercise'),
            ),
          ],
        ),
      ),
    );
  }

  String get _levelStatusLabel {
    switch (node.status) {
      case ExerciseSkillTreeNodeStatus.fitsCurrentLevel:
        return 'Fits your current level';
      case ExerciseSkillTreeNodeStatus.aboveCurrentLevel:
        return 'Above your current level';
      case ExerciseSkillTreeNodeStatus.movementLevelUnavailable:
        return 'Movement level unavailable';
    }
  }

  String get _setupStatusLabel {
    switch (node.setupStatus) {
      case ExerciseSkillTreeSetupStatus.fitsSetup:
        return 'Fits your setup';
      case ExerciseSkillTreeSetupStatus.needsSetupChange:
        return 'Needs setup change';
      case ExerciseSkillTreeSetupStatus.setupDetailsUnavailable:
        return 'Setup details unavailable';
    }
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
    return Chip(
      label: Text(label),
      backgroundColor: background,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
