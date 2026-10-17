import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_variation_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Progression section for Exercise Detail.
///
/// Shows step context (e.g. Step 4 of 6) and easier/harder variation cards.
/// Only rendered when progression info exists.
class ExerciseProgressionSection extends StatelessWidget {
  const ExerciseProgressionSection({
    super.key,
    required this.progression,
    this.skillTreeFamilyId,
  });

  final ExerciseProgressionInfo progression;
  final String? skillTreeFamilyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: FitFlowSpace.lg),
        Semantics(
          header: true,
          child: Text(
            context.l10n.trainingProgression,
            style: theme.textTheme.titleLarge?.copyWith(
              color: visual.onTint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: FitFlowSpace.sm),
        TrainingFact(
            context.l10n.trainingStep(progression.step, progression.total)),
        const SizedBox(height: FitFlowSpace.md),
        // Variation cards: easier, current, harder
        if (progression.easier != null) ...[
          ExerciseVariationCard(
            key: ValueKey('exercise_variation_${progression.easier!.id}'),
            exercise: progression.easier!,
            directionLabel: context.l10n.trainingEasier,
            directionIcon: Icons.arrow_back,
            onTap: () => context.push(
              AppRoutes.exerciseDetail(progression.easier!.id),
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
        ],
        // Current
        ExerciseVariationCard(
          key: ValueKey('exercise_variation_${progression.current.id}'),
          exercise: progression.current,
          directionLabel: context.l10n.trainingCurrent,
          directionIcon: Icons.my_location,
          isCurrent: true,
        ),
        if (progression.harder != null) ...[
          const SizedBox(height: FitFlowSpace.xs),
          ExerciseVariationCard(
            key: ValueKey('exercise_variation_${progression.harder!.id}'),
            exercise: progression.harder!,
            directionLabel: context.l10n.trainingHarder,
            directionIcon: Icons.arrow_forward,
            onTap: () => context.push(
              AppRoutes.exerciseDetail(progression.harder!.id),
            ),
          ),
        ],
        if (skillTreeFamilyId != null) ...[
          const SizedBox(height: FitFlowSpace.md),
          FilledButton.icon(
            key: const ValueKey('exercise_skill_tree_button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () => context.push(
              AppRoutes.skillTreeFamily(skillTreeFamilyId!),
            ),
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(context.l10n.trainingViewTree),
          ),
        ],
      ],
    );
  }
}
