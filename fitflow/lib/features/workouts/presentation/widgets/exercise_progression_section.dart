import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
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
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.trainingProgression,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TrainingFact(
                context.l10n.trainingStep(progression.step, progression.total)),
            const SizedBox(height: 16),
            // Variation cards: easier, current, harder
            if (progression.easier != null) ...[
              ExerciseVariationCard(
                exercise: progression.easier!,
                directionLabel: context.l10n.trainingEasier,
                directionIcon: Icons.arrow_back,
                onTap: () => context.push(
                  AppRoutes.exerciseDetail(progression.easier!.id),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Current
            ExerciseVariationCard(
              exercise: progression.current,
              directionLabel: context.l10n.trainingCurrent,
              directionIcon: Icons.my_location,
              isCurrent: true,
            ),
            if (progression.harder != null) ...[
              const SizedBox(height: 10),
              ExerciseVariationCard(
                exercise: progression.harder!,
                directionLabel: context.l10n.trainingHarder,
                directionIcon: Icons.arrow_forward,
                onTap: () => context.push(
                  AppRoutes.exerciseDetail(progression.harder!.id),
                ),
              ),
            ],
            if (skillTreeFamilyId != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.skillTreeFamily(skillTreeFamilyId!),
                ),
                icon: const Icon(Icons.account_tree_outlined),
                label: Text(context.l10n.trainingViewTree),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
