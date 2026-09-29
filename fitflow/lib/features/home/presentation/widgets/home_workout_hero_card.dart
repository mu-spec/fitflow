import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';

/// Hero card showing today's generated workout summary.
/// M12: shows effective duration target and mode indicator.
class HomeWorkoutHeroCard extends StatelessWidget {
  const HomeWorkoutHeroCard({
    super.key,
    required this.plan,
    required this.userProfile,
    this.effectiveDuration,
    this.sessionMode = WorkoutSessionMode.standard,
  });

  final WorkoutPlan plan;
  final UserFitnessProfile userProfile;
  final WorkoutDuration? effectiveDuration;
  final WorkoutSessionMode sessionMode;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) {
      return '< 1 min';
    }
    final minutes = (totalSeconds / 60).ceil();
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetMinutes = (effectiveDuration ?? userProfile.workoutDuration).minutes;
    final estimated = plan.estimatedDuration;
    final estimatedFormatted = _formatDuration(estimated);
    final targetFormatted = '$targetMinutes min';

    final isTemporary = sessionMode != WorkoutSessionMode.standard;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined, size: 18, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  "TODAY'S WORKOUT",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                if (isTemporary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sessionMode.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Adaptive Full Session',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$targetFormatted target • ~$estimatedFormatted planned',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.totalExerciseCount} exercises • ${userProfile.goal.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
              ),
            ),
            if (isTemporary) ...[
              const SizedBox(height: 8),
              Text(
                'Temporary for this workout',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildSectionCount(context, 'Warm-up', plan.warmup.exerciseCount, Icons.self_improvement_outlined),
                  const SizedBox(width: 8),
                  _buildDivider(context),
                  const SizedBox(width: 8),
                  _buildSectionCount(context, 'Main', plan.main.exerciseCount, Icons.fitness_center_outlined),
                  const SizedBox(width: 8),
                  _buildDivider(context),
                  const SizedBox(width: 8),
                  _buildSectionCount(context, 'Cooldown', plan.cooldown.exerciseCount, Icons.spa_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildSectionCount(BuildContext context, String label, int count, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
