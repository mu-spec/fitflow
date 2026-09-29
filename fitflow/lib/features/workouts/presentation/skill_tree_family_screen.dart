import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/presentation/widgets/skill_tree_node_card.dart';
import 'package:fitflow/features/workouts/state/exercise_skill_tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ordered, readable progression pathway for one catalog family.
class SkillTreeFamilyScreen extends ConsumerWidget {
  const SkillTreeFamilyScreen({
    super.key,
    required this.familyId,
  });

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exerciseSkillTreeCatalogProvider);
    final tree = catalog.treeForFamilyId(familyId);
    if (tree == null) {
      return _SkillTreeNotFoundScreen();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final level = tree.currentMovementLevel;

    return Scaffold(
      appBar: AppBar(title: Text(tree.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tree.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(tree.movementName),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Chip(
                          label: Text('${tree.nodeCount} steps'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level == null
                          ? 'Movement level unavailable'
                          : 'Your ${tree.movementName} level: ${level.label}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Exercises at or below this difficulty fit your current movement level.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'This pathway shows exercise difficulty and setup fit, not exercise mastery.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < tree.nodes.length; index++) ...[
              _NodePathRow(
                node: tree.nodes[index],
                totalSteps: tree.nodeCount,
                onViewExercise: () => context.push(
                  AppRoutes.exerciseDetail(tree.nodes[index].exercise.id),
                ),
              ),
              if (index < tree.nodes.length - 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      width: 2,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NodePathRow extends StatelessWidget {
  const _NodePathRow({
    required this.node,
    required this.totalSteps,
    required this.onViewExercise,
  });

  final ExerciseSkillTreeNode node;
  final int totalSteps;
  final VoidCallback onViewExercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(
              child: Semantics(
                label: 'Progression step ${node.position} of $totalSteps',
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SkillTreeNodeCard(
            node: node,
            totalSteps: totalSteps,
            onViewExercise: onViewExercise,
          ),
        ),
      ],
    );
  }
}

class _SkillTreeNotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Skill tree')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Skill tree not found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This progression is not available in the current exercise catalog.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.skillTrees),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Skill Trees'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
