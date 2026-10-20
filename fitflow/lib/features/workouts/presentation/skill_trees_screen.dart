import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/presentation/widgets/skill_tree_family_card.dart';
import 'package:fitflow/features/workouts/state/exercise_skill_tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Overview of progression families discovered from active catalog metadata.
class SkillTreesScreen extends ConsumerWidget {
  const SkillTreesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exerciseSkillTreeCatalogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: FitFlowVisualV2.of(context).page,
      appBar: AppBar(
          backgroundColor: FitFlowVisualV2.of(context).page,
          scrolledUnderElevation: 0,
          title: Text(context.l10n.trainingSkills,
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
                  context.l10n.trainingSkillIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (catalog.trees.isEmpty)
                  const _NoSkillTreesState()
                else
                  for (final tree in catalog.trees) ...[
                    SkillTreeFamilyCard(
                      tree: tree,
                      onTap: () => context.push(
                        AppRoutes.skillTreeFamily(tree.familyId),
                      ),
                    ),
                    if (tree != catalog.trees.last) const Divider(height: 1),
                  ],
              ],
            ),
          ))),
    );
  }
}

class _NoSkillTreesState extends StatelessWidget {
  const _NoSkillTreesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.trainingSkillEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.trainingSkillEmptyHelp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
