import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import '../exercise_detail_screen.dart';
import '../../state/exercise_skill_tree_provider.dart';
import 'skill_tree_node_card.dart';
import 'training_presentation.dart';

/// One family picker and inline steps: no intermediate family route.
class SkillPathsPanel extends ConsumerStatefulWidget {
  const SkillPathsPanel(
      {super.key, this.initialFamilyId, this.onFamilySelected});
  final String? initialFamilyId;
  final ValueChanged<String>? onFamilySelected;
  @override
  ConsumerState<SkillPathsPanel> createState() => _SkillPathsPanelState();
}

class _SkillPathsPanelState extends ConsumerState<SkillPathsPanel> {
  String? _family;
  @override
  void initState() {
    super.initState();
    _family = widget.initialFamilyId;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseSkillTreeCatalogProvider);
    if (catalog.trees.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.l10n.trainingSkillEmpty));
    }
    final tree = catalog.treeForFamilyId(_family ?? '') ?? catalog.trees.first;
    final level = tree.currentMovementLevel;
    return SingleChildScrollView(
      key: const ValueKey('skill_paths_scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final family in catalog.trees)
            ChoiceChip(
              key: ValueKey('skill_family_${family.familyId}'),
              label: Text(family.displayName),
              selected: family.familyId == tree.familyId,
              onSelected: (_) {
                setState(() => _family = family.familyId);
                widget.onFamilySelected?.call(family.familyId);
              },
            ),
        ]),
        const SizedBox(height: 20),
        Text(tree.displayName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(level == null
            ? context.l10n.trainingLevelUnavailable
            : context.l10n.trainingMovementLevel(
                tree.movementName, trainingLevelLabel(context.l10n, level))),
        const SizedBox(height: 16),
        for (final node in tree.nodes)
          SkillTreeNodeCard(
            key: ValueKey('skill_node_${tree.familyId}_${node.exercise.id}'),
            node: node,
            totalSteps: tree.nodeCount,
            familyNodes: tree.nodes,
            onViewExercise: () => showExerciseGuide(context, node.exercise.id),
          ),
        TrainingDisclosure(title: context.l10n.trainingProgression, children: [
          Text(context.l10n.trainingSkillPathTruth),
          const SizedBox(height: 8),
          Text(context.l10n.trainingSkillTruth),
        ]),
      ]),
    );
  }
}
