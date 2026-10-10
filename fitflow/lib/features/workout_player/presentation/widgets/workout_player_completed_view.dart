import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
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
      useSafeArea: true,
      constraints:
          const BoxConstraints(maxWidth: FitFlowLayout.maxReadableWidth),
      sheetAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.micro(context)),
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
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    final t = FitFlowTheme.of(context);
    final isTemporary = sessionOrigin == WorkoutSessionOrigin.adaptive &&
        sessionMode != WorkoutSessionMode.standard;
    final isCustom = sessionOrigin == WorkoutSessionOrigin.custom;
    final isProgram = sessionOrigin == WorkoutSessionOrigin.program;
    final note = completionNote == programCompletedCopy
        ? l.flowProgramComplete
        : completionNote ?? (isProgram ? l.flowProgramComplete : null);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: t.success, shape: BoxShape.circle),
                  child: Padding(
                      padding: const EdgeInsets.all(FitFlowSpace.md),
                      child: ExcludeSemantics(
                          child: Icon(Icons.check_rounded,
                              size: 32, color: t.onSuccess))))),
          const SizedBox(height: FitFlowSpace.lg),
          Semantics(
              header: true,
              child: Text(l.flowComplete,
                  style: text.headlineMedium, textAlign: TextAlign.center)),
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowFinished,
              style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xl),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 16,
              children: [
                Column(children: [
                  Text('${plan.totalExerciseCount}', style: text.displayMedium),
                  Text(l.flowExercises, style: text.labelLarge)
                ]),
                Column(children: [
                  Text('${state.completedSets} / ${state.totalSets}',
                      style: text.displayMedium),
                  Text(l.flowSets, style: text.labelLarge)
                ]),
              ]),
          const SizedBox(height: FitFlowSpace.lg),
          const Divider(),
          const SizedBox(height: FitFlowSpace.sm),
          _StatRow(
              label: l.flowTargetLabel,
              value: plannedDuration(l, plan.targetDuration)),
          const SizedBox(height: FitFlowSpace.xs),
          _StatRow(
              label: l.flowEstimateLabel,
              value: plannedDuration(l, plan.estimatedDuration)),
          const SizedBox(height: FitFlowSpace.sm),
          if (isTemporary)
            Text(l.flowTemporaryNote(sessionModeLabel(l, sessionMode)),
                style: text.bodyMedium, textAlign: TextAlign.center),
          if (isCustom)
            Text(l.flowCustomNote,
                style: text.bodyMedium, textAlign: TextAlign.center),
          if (note != null)
            Text(note, style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.sm),
          Text(l.flowHistory,
              style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xl),
          _OnceDoneButton(
              onPressed: () => _handleDone(context, ref), child: Text(l.done)),
          if (!isTemporary && !isCustom) ...[
            const SizedBox(height: FitFlowSpace.xs),
            OutlinedButton(
                onPressed: () => _openTuneSheet(context, ref),
                child: Text(l.flowTune)),
          ],
        ]));
  }
}

/// Ignores repeat presses so a rapid double-tap cannot run Done twice.
class _OnceDoneButton extends StatefulWidget {
  const _OnceDoneButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_OnceDoneButton> createState() => _OnceDoneButtonState();
}

class _OnceDoneButtonState extends State<_OnceDoneButton> {
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
      child: FilledButton(
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
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: FitFlowSpace.xs),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
