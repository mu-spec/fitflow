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
  });

  final ExerciseProgressionInfo progression;

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
              'Progression',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Family context: Step X of Y
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${progression.step} of ${progression.total}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${progression.step} / ${progression.total}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Simple horizontal step indicator
            _StepIndicator(
              total: progression.total,
              currentIndex: progression.currentIndex,
            ),
            const SizedBox(height: 16),
            // Variation cards: easier, current, harder
            if (progression.easier != null) ...[
              ExerciseVariationCard(
                exercise: progression.easier!,
                directionLabel: 'Easier variation',
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
              directionLabel: 'Current',
              directionIcon: Icons.my_location,
              isCurrent: true,
            ),
            if (progression.harder != null) ...[
              const SizedBox(height: 10),
              ExerciseVariationCard(
                exercise: progression.harder!,
                directionLabel: 'Harder variation',
                directionIcon: Icons.arrow_forward,
                onTap: () => context.push(
                  AppRoutes.exerciseDetail(progression.harder!.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.total, required this.currentIndex});

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (index) {
        final isCurrent = index == currentIndex;
        final isPast = index < currentIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: isCurrent
                  ? colorScheme.primary
                  : isPast
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
