import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/adaptive_progression_feedback_sheet.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Completed phase view - truthful data only, no calories/XP/streaks/history.
/// M12: Tune disabled for temporary modes, reset mode on Done.
class WorkoutPlayerCompletedView extends ConsumerWidget {
  const WorkoutPlayerCompletedView({
    super.key,
    required this.plan,
    required this.state,
    this.sessionMode = WorkoutSessionMode.standard,
  });

  final WorkoutPlan plan;
  final WorkoutPlayerState state;
  final WorkoutSessionMode sessionMode;

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  Future<void> _openTuneSheet(BuildContext context, WidgetRef ref) async {
    List<WorkoutExercisePrescription> effectiveMain;
    try {
      final notifier = ref.read(workoutPlayerControllerProvider(plan).notifier);
      effectiveMain = notifier.effectiveMainPrescriptions;
    } catch (_) {
      effectiveMain = plan.main.exercises;
    }

    final capabilityAsync = ref.read(capabilityProfileProvider);
    final capabilityProfile = capabilityAsync.value;
    if (capabilityProfile == null) {
      if (context.mounted) {
        try {
          context.go(AppRoutes.home);
        } catch (_) {
          ref.read(appRouterProvider).go(AppRoutes.home);
        }
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return AdaptiveProgressionFeedbackSheet(
              effectiveMainPrescriptions: effectiveMain,
              currentProfile: capabilityProfile,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  void _handleDone(BuildContext context, WidgetRef ref) {
    // Reset to standard when leaving completion after non-standard
    if (sessionMode != WorkoutSessionMode.standard) {
      try {
        ref.read(workoutSessionModeProvider.notifier).reset();
      } catch (_) {}
    }
    if (context.mounted) {
      try {
        context.go(AppRoutes.home);
      } catch (_) {
        ref.read(appRouterProvider).go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalExercises = plan.totalExerciseCount;
    final completedSets = state.completedSets;
    final totalSets = state.totalSets;
    final isTemporary = sessionMode != WorkoutSessionMode.standard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 56,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Workout complete',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Great job! You finished all sets.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (isTemporary) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'This was a temporary ${sessionMode.label} workout. Your movement levels stay unchanged.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(label: 'Exercises', value: '$totalExercises'),
                const Divider(),
                _StatRow(label: 'Sets', value: '$completedSets / $totalSets'),
                const Divider(),
                _StatRow(label: 'Target duration', value: _formatDuration(plan.targetDuration)),
                const SizedBox(height: 8),
                _StatRow(label: 'Estimated duration', value: _formatDuration(plan.estimatedDuration)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Session progress is not saved in this version.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (!isTemporary)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openTuneSheet(context, ref),
              child: const Text('Tune next workout'),
            ),
          ),
        if (!isTemporary) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleDone(context, ref),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
