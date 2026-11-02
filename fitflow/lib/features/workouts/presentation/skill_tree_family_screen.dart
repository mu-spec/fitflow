import 'exercise_library_screen.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
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
  Widget build(BuildContext context, WidgetRef ref) =>
      WorkoutsTheme(child: _SkillTreeFamilyContent(familyId: familyId));
}

class _SkillTreeFamilyContent extends ConsumerWidget {
  const _SkillTreeFamilyContent({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exerciseSkillTreeCatalogProvider);
    final tree = catalog.treeForFamilyId(familyId);
    if (tree == null) {
      return _SkillTreeNotFoundScreen();
    }

    return ExerciseLibraryScreen(
        initialSkills: true, initialFamilyId: tree.familyId);
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
