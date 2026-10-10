import 'package:fitflow/l10n/fitflow_l10n.dart';
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
      appBar: AppBar(title: Text(context.l10n.trainingSkills)),
      body: FitFlowMaxWidth(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.trainingSkillIntro,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const _TruthfulnessNote(),
            const SizedBox(height: 20),
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
                const SizedBox(height: 12),
              ],
          ],
        ),
      )),
    );
  }
}

class _TruthfulnessNote extends StatelessWidget {
  const _TruthfulnessNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colors.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.trainingSkillTruth,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
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
