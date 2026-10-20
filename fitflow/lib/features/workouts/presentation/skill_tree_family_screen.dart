import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
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
      backgroundColor: FitFlowVisualV2.of(context).page,
      appBar: AppBar(
          backgroundColor: FitFlowVisualV2.of(context).page,
          scrolledUnderElevation: 0,
          title: Text(tree.displayName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500))),
      body: SafeArea(
          top: false,
          child: FitFlowMaxWidth(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${tree.movementName} \u00b7 ${context.l10n.trainingSteps(tree.nodeCount)}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                    level == null
                        ? context.l10n.trainingLevelUnavailable
                        : context.l10n.trainingMovementLevel(tree.movementName,
                            trainingLevelLabel(context.l10n, level)),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(context.l10n.trainingSkillPathTruth,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                TrainingDisclosure(
                  title: context.l10n.trainingProgression,
                  children: [
                    Text(
                        '${tree.easiest.exercise.name} \u2192 ${tree.hardest.exercise.name}',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(context.l10n.trainingSkillTruth,
                        style: theme.textTheme.bodyMedium),
                    if (level != null) ...[
                      const SizedBox(height: 8),
                      Text(context.l10n.trainingSkillFitHelp,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(context.l10n
                          .trainingFitCount(tree.fitsCurrentLevelCount)),
                      Text(context.l10n
                          .trainingAboveCount(tree.aboveCurrentLevelCount)),
                    ],
                    if (tree.nodes.every((node) => node.fitsSetup != null))
                      Text(context.l10n.trainingSetupCount(tree.nodes
                          .where((node) => node.fitsSetup == true)
                          .length)),
                  ],
                ),
                const SizedBox(height: 20),
                for (var index = 0; index < tree.nodes.length; index++) ...[
                  SkillTreeNodeCard(
                    node: tree.nodes[index],
                    totalSteps: tree.nodeCount,
                    familyNodes: tree.nodes,
                    onViewExercise: () => context.push(
                      AppRoutes.exerciseDetail(tree.nodes[index].exercise.id),
                    ),
                  ),
                  if (index < tree.nodes.length - 1) const Divider(height: 24),
                ],
              ],
            ),
          ))),
    );
  }
}

class _SkillTreeNotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trainingSkillTree)),
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
                context.l10n.trainingSkillMissing,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.trainingSkillMissingHelp,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.skillTrees),
                icon: const Icon(Icons.arrow_back),
                label: Text(context.l10n.trainingBackSkills),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
