import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/adaptive_progression_feedback_sheet.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Completed phase view - truthful data only, no calories/XP/streaks.
/// M12: Tune disabled for temporary modes, reset mode on Done.
/// M13: Custom origin – no Tune, protection copy, configurable Done destination.
/// M16: Program origin – normal Standard completion (Tune visible), optional
/// factual note, Done returns to the program (via [onDone]/[doneRoute]).
class WorkoutPlayerCompletedView extends ConsumerWidget {
  const WorkoutPlayerCompletedView({
    super.key,
    required this.plan,
    required this.state,
    this.sessionMode = WorkoutSessionMode.standard,
    this.sessionOrigin = WorkoutSessionOrigin.adaptive,
    this.onDone,
    this.doneRoute,
    this.completionNote,
  });

  /// Shared truthful copy for every origin (M11 local history only).
  static const String historySavedCopy =
      'Completed workouts are saved to your history on this device.';

  /// Default factual note for program sessions. Does not claim progress was
  /// saved — persistence is reported truthfully on the program detail screen.
  static const String programCompletedCopy = 'Program workout completed.';

  final WorkoutPlan plan;
  final WorkoutPlayerState state;
  final WorkoutSessionMode sessionMode;
  final WorkoutSessionOrigin sessionOrigin;
  final VoidCallback? onDone;
  final String? doneRoute;
  final String? completionNote;

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
              returnRoute: doneRoute,
            );
          },
        );
      },
    );
  }

  void _handleDone(BuildContext context, WidgetRef ref) {
    if (onDone != null) {
      onDone!.call();
      return;
    }

    if (doneRoute != null) {
      try {
        context.go(doneRoute!);
        return;
      } catch (_) {
        try {
          ref.read(appRouterProvider).go(doneRoute!);
          return;
        } catch (_) {}
      }
    }

    // Default handling based on origin
    if (sessionOrigin == WorkoutSessionOrigin.custom ||
        sessionOrigin == WorkoutSessionOrigin.program) {
      // Custom completion returns to Workouts tab. Program screens always
      // provide onDone/doneRoute; this is only a safe fallback that never
      // touches the Home session mode.
      try {
        context.go(AppRoutes.workouts);
      } catch (_) {
        ref.read(appRouterProvider).go(AppRoutes.workouts);
      }
      return;
    }

    // Adaptive: reset mode if temporary
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
    final isTemporary = sessionOrigin == WorkoutSessionOrigin.adaptive && sessionMode != WorkoutSessionMode.standard;
    final isCustom = sessionOrigin == WorkoutSessionOrigin.custom;
    final isProgram = sessionOrigin == WorkoutSessionOrigin.program;
    final note = completionNote ?? (isProgram ? programCompletedCopy : null);

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
        if (isCustom) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Custom workouts don't change your movement levels.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (note != null) ...[
          const SizedBox(height: 12),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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
          historySavedCopy,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (!isTemporary && !isCustom)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openTuneSheet(context, ref),
              child: const Text('Tune next workout'),
            ),
          ),
        if (!isTemporary && !isCustom) const SizedBox(height: 8),
        _OnceOutlinedButton(
          onPressed: () => _handleDone(context, ref),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Ignores repeat presses so a rapid double-tap cannot run Done twice.
class _OnceOutlinedButton extends StatefulWidget {
  const _OnceOutlinedButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_OnceOutlinedButton> createState() => _OnceOutlinedButtonState();
}

class _OnceOutlinedButtonState extends State<_OnceOutlinedButton> {
  bool _fired = false;

  void _press() {
    if (_fired) return;
    setState(() => _fired = true);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _fired ? null : _press,
        child: widget.child,
      ),
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
