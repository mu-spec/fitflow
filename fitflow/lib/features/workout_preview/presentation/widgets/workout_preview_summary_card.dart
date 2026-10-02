import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';

/// Summary card showing truthful data from WorkoutPlan + M12 mode.
class WorkoutPreviewSummaryCard extends StatelessWidget {
  const WorkoutPreviewSummaryCard({
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
    if (totalSeconds < 60) return '< 1 min';
    final minutes = (totalSeconds / 60).ceil();
    return '$minutes min';
  }

  int _uniqueMainMovementCount() {
    final seen = <MovementPattern>{};
    for (final pres in plan.main.exercises) {
      final pattern = pres.exercise.movementPattern;
      if (pattern == null) continue;
      if (pattern == MovementPattern.warmup || pattern == MovementPattern.cooldown) continue;
      seen.add(pattern);
    }
    return seen.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetMinutes = (effectiveDuration ?? userProfile.workoutDuration).minutes;
    final estimated = plan.estimatedDuration;
    final uniqueFocus = _uniqueMainMovementCount();
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
                Expanded(
                  child: Text(
                    'Today\'s session',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            Text(
              userProfile.goal.label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetric(context, Icons.timer_outlined, '$targetMinutes min target'),
                _buildMetric(context, Icons.timelapse_outlined, '~${_formatDuration(estimated)} planned'),
                _buildMetric(context, Icons.fitness_center_outlined, '${plan.totalExerciseCount} exercises'),
                if (uniqueFocus > 0)
                  _buildMetric(context, Icons.center_focus_strong_outlined, '$uniqueFocus focus areas'),
              ],
            ),
            if (isTemporary) ...[
              const SizedBox(height: 8),
              Text(
                'Temporary for this workout',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
