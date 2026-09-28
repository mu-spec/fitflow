import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/material.dart';

/// Section break UI: Warm-up complete / Main complete, manual Continue.
class WorkoutPlayerSectionBreakView extends StatelessWidget {
  const WorkoutPlayerSectionBreakView({super.key, required this.state});

  final WorkoutPlayerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isWarmupComplete = state.sectionType == WorkoutSectionType.warmup;
    final title = isWarmupComplete ? 'Warm-up complete' : 'Main workout complete';
    final nextLabel = isWarmupComplete ? 'Main workout is next' : 'Cooldown is next';
    final icon = isWarmupComplete ? Icons.local_fire_department_outlined : Icons.fitness_center_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          nextLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Text(
            state.progressLabel,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: state.progressFraction,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: colorScheme.primary,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
