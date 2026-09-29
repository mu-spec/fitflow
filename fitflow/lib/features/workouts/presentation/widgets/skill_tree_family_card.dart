import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:flutter/material.dart';

/// Overview card for one catalog-discovered progression family.
class SkillTreeFamilyCard extends StatelessWidget {
  const SkillTreeFamilyCard({
    super.key,
    required this.tree,
    required this.onTap,
  });

  final ExerciseSkillTree tree;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final level = tree.currentMovementLevel;
    final setupCount =
        tree.nodes.where((node) => node.fitsSetup == true).length;
    final setupKnown = tree.nodes.every((node) => node.fitsSetup != null);

    return Semantics(
      button: true,
      label: 'Open ${tree.displayName} skill tree, ${tree.nodeCount} steps',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tree.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MetadataChip(label: tree.movementName),
                    _MetadataChip(
                      label:
                          '${tree.nodeCount} ${tree.nodeCount == 1 ? 'step' : 'steps'}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tree.easiest.exercise.name}  →  ${tree.hardest.exercise.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  level == null
                      ? 'Movement level unavailable'
                      : 'Your ${tree.movementName} level: ${level.label}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (level != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label:
                            '${tree.fitsCurrentLevelCount} fit your current level',
                        background: colors.primaryContainer,
                        foreground: colors.onPrimaryContainer,
                      ),
                      _StatusChip(
                        label:
                            '${tree.aboveCurrentLevelCount} above your current level',
                        background: colors.tertiaryContainer,
                        foreground: colors.onTertiaryContainer,
                      ),
                    ],
                  ),
                ],
                if (setupKnown) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$setupCount fit your current setup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});

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
