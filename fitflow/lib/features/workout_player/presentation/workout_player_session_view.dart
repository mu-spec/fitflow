import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_replacement_picker.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_controls.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_progress_header.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_rest_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_section_break_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_transition_view.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reusable session view for adaptive (generated), custom and program workouts.
/// Single execution engine – timers, sets, rest, transitions, section breaks, TTS, pause, lifecycle, exit confirmation, M9, history.
class WorkoutPlayerSessionView extends ConsumerStatefulWidget {
  const WorkoutPlayerSessionView({
    super.key,
    required this.plan,
    required this.sessionMode,
    required this.sessionOrigin,
    this.onDone,
    this.doneRoute,
    this.onWorkoutCompleted,
    this.completionNote,
  });

  final WorkoutPlan plan;
  final WorkoutSessionMode sessionMode;
  final WorkoutSessionOrigin sessionOrigin;
  final VoidCallback? onDone;
  final String? doneRoute;

  /// Optional completion hook (M16). Fired only when the phase becomes
  /// `completed` — never on Done, Tune, rebuilds or exit. Independent of the
  /// M11 history save: neither waits for, nor depends on, the other.
  final WorkoutCompletionCallback? onWorkoutCompleted;

  /// Optional small factual line shown on the completion screen.
  final String? completionNote;

  @override
  ConsumerState<WorkoutPlayerSessionView> createState() =>
      _WorkoutPlayerSessionViewState();
}

class _WorkoutPlayerSessionViewState
    extends ConsumerState<WorkoutPlayerSessionView> {
  late final AppLifecycleListener _lifecycleListener;
  bool _allowPop = false;
  final _phasePresentationKey = GlobalKey();
  late final WorkoutPlan _stablePlan;
  late final WorkoutSessionMode _stableMode;
  late final WorkoutSessionOrigin _stableOrigin;
  final Set<String> _recordedSessionIds = {};
  final Set<String> _notifiedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _stablePlan = widget.plan;
    _stableMode = widget.sessionMode;
    _stableOrigin = widget.sessionOrigin;
    _lifecycleListener = AppLifecycleListener(
      onInactive: _handleAppInactive,
      onPause: _handleAppInactive,
      onHide: _handleAppInactive,
      onStateChange: (state) {
        if (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) {
          _handleAppInactive();
        }
      },
    );
  }

  void _maybeRecordHistory(WorkoutPlayerState state) {
    if (state.phase != WorkoutPlayerPhase.completed) return;
    try {
      final controller =
          ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
      final sessionId = controller.sessionId;
      if (_recordedSessionIds.contains(sessionId)) return;
      _recordedSessionIds.add(sessionId);

      final completedWorkout =
          controller.createCompletedWorkoutSnapshot(plan: _stablePlan);

      // ignore: discarded_futures
      ref
          .read(workoutHistoryProvider.notifier)
          .addWorkout(completedWorkout)
          .then((success) {
        if (!mounted) return;
        if (!success) {
          _recordedSessionIds.remove(sessionId);
        }
      }, onError: (_) {
        if (!mounted) return;
        _recordedSessionIds.remove(sessionId);
      });
    } catch (_) {
      // History failure must not break Player
    }
  }

  /// Fires [WorkoutPlayerSessionView.onWorkoutCompleted] at most once per
  /// Player session. A `false` result or an exception releases the guard so a
  /// later rebuild can retry; a `true` result is final for this session.
  void _maybeNotifyCompletion(WorkoutPlayerState state) {
    if (state.phase != WorkoutPlayerPhase.completed) return;
    final callback = widget.onWorkoutCompleted;
    if (callback == null) return;
    try {
      final controller =
          ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
      final sessionId = controller.sessionId;
      if (_notifiedSessionIds.contains(sessionId)) return;
      _notifiedSessionIds.add(sessionId);

      final completion = WorkoutPlayerCompletion(
        playerSessionId: sessionId,
        completedWorkout:
            controller.createCompletedWorkoutSnapshot(plan: _stablePlan),
        plan: _stablePlan,
        origin: _stableOrigin,
      );

      // ignore: discarded_futures
      callback(completion).then((handled) {
        if (!mounted) return;
        if (!handled) {
          _notifiedSessionIds.remove(sessionId);
        }
      }, onError: (_) {
        if (!mounted) return;
        _notifiedSessionIds.remove(sessionId);
      });
    } catch (_) {
      // Completion hook failure must not break Player
    }
  }

  @override
  void didUpdateWidget(covariant WorkoutPlayerSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep session stable – ignore new plan/mode/origin to prevent reset
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _handleAppInactive() {
    final playerState = ref.read(workoutPlayerControllerProvider(_stablePlan));
    if (playerState.isPaused) return;
    if (playerState.phase == WorkoutPlayerPhase.work ||
        playerState.phase == WorkoutPlayerPhase.rest ||
        playerState.phase == WorkoutPlayerPhase.transition) {
      ref
          .read(workoutPlayerControllerProvider(_stablePlan).notifier)
          .pauseForLifecycle();
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      animationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.micro(context)),
      builder: (ctx) => FitFlowConfirmDialog(
        title: context.l10n.flowExitTitle,
        message: context.l10n.flowExitBody,
        cancelLabel: context.l10n.flowKeepGoing,
        confirmLabel: context.l10n.flowExit,
        destructive: true,
      ),
    );
    return result ?? false;
  }

  Future<void> _handleReplaceExercise() async {
    final controller =
        ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
    final state = ref.read(workoutPlayerControllerProvider(_stablePlan));

    if (!controller.canReplaceCurrentExercise) return;

    if (state.isTimedExercise &&
        state.phase == WorkoutPlayerPhase.work &&
        !state.isPaused) {
      controller.pause();
    }

    final options = controller.getReplacementOptions();

    if (!mounted) return;

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
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return WorkoutReplacementPicker(
              currentPrescription: state.currentPrescription,
              originalExerciseName: state.originalExerciseName,
              options: options,
              scrollController: scrollController,
              onSelect: (option) {
                final success = controller.replaceCurrentExercise(option);
                if (success) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutPlayerControllerProvider(_stablePlan));
    final controller =
        ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);

    if (state.phase == WorkoutPlayerPhase.completed) {
      Future.microtask(() {
        if (mounted) {
          _maybeRecordHistory(state);
          _maybeNotifyCompletion(state);
        }
      });
    }

    final isActiveSession = state.phase == WorkoutPlayerPhase.work ||
        state.phase == WorkoutPlayerPhase.rest ||
        state.phase == WorkoutPlayerPhase.transition ||
        state.isPaused ||
        state.phase == WorkoutPlayerPhase.sectionBreak;

    final canPop = !_allowPop
        ? (state.phase == WorkoutPlayerPhase.ready ||
            state.phase == WorkoutPlayerPhase.completed)
        : true;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!isActiveSession) {
          if (context.mounted) {
            setState(() => _allowPop = true);
            Future.microtask(() {
              if (context.mounted) {
                context.pop();
              }
            });
          }
          return;
        }
        final shouldEnd = await _showExitDialog();
        if (!shouldEnd) return;
        if (context.mounted) {
          setState(() => _allowPop = true);
          Future.microtask(() {
            if (context.mounted) {
              context.pop();
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle(context.l10n, _stableOrigin)),
          actions: [
            IconButton(
              tooltip: state.voiceEnabled
                  ? context.l10n.flowMute
                  : context.l10n.flowVoice,
              onPressed: () => controller.toggleVoice(),
              icon: Icon(state.voiceEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded),
            ),
          ],
        ),
        body: SafeArea(
            child: FitFlowMaxWidth(
                child: Padding(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360
              ? FitFlowSpace.md
              : FitFlowSpace.xl),
          child: LayoutBuilder(builder: (context, constraints) {
            // Entry is keyed by phase/exercise only, not countdown, set or pause.
            // No outgoing subtree is retained, and controller ownership stays above.
            final phase = KeyedSubtree(
                key: _phasePresentationKey,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                      'phase_${state.phase}_${state.sectionIndex}_${state.exerciseIndex}_${state.currentPrescription.exercise.id}'),
                  tween: Tween(begin: 0, end: 1),
                  duration: SystemMotion.standard(context),
                  curve: FitFlowMotion.standardCurve,
                  builder: (context, value, child) => Opacity(
                      opacity: value,
                      alwaysIncludeSemantics: true,
                      child: child),
                  child: _buildPhaseBody(context, state, controller),
                ));
            final controls = WorkoutPlayerControls(
                state: state, controller: controller, plan: _stablePlan);
            final actions = <Widget>[
              controls,
              if (controller.canReplaceCurrentExercise) ...[
                const SizedBox(height: FitFlowSpace.xs),
                TextButton.icon(
                    onPressed: _handleReplaceExercise,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(context.l10n.flowReplace)),
              ],
              if (state.phase == WorkoutPlayerPhase.ready || state.isPaused)
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.exerciseDetail(
                      state.currentPrescription.exercise.id)),
                  icon: const Icon(Icons.info_outline_rounded),
                  label: Text(context.l10n.flowDetails),
                ),
            ];
            final header = <Widget>[
              PlayerPhaseAnnouncement(
                  message: playerPhaseAnnouncement(state, context.l10n)),
              if (state.phase != WorkoutPlayerPhase.completed) ...[
                WorkoutPlayerProgressHeader(state: state),
                const SizedBox(height: FitFlowSpace.md),
                if (_stableOrigin == WorkoutSessionOrigin.adaptive &&
                    _stableMode != WorkoutSessionMode.standard) ...[
                  Text(
                      context.l10n.flowModeTemporary(
                          sessionModeLabel(context.l10n, _stableMode)),
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: FitFlowSpace.sm),
                ],
              ],
            ];
            // Width changes presentation only; session/provider ownership stays
            // above this layout, with no width-based session keys.
            final wide = constraints.maxWidth >= 600 &&
                state.phase != WorkoutPlayerPhase.completed;
            if (wide) {
              return SingleChildScrollView(
                  child: Column(children: [
                ...header,
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: phase),
                  const SizedBox(width: FitFlowSpace.xl),
                  Expanded(
                      flex: 2,
                      child: Padding(
                          padding: const EdgeInsets.only(top: FitFlowSpace.xl),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: actions))),
                ]),
              ]));
            }
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
            if (constraints.maxHeight < 400 ||
                (largeText && constraints.maxHeight < 640)) {
              return SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    ...header,
                    phase,
                    const SizedBox(height: FitFlowSpace.md),
                    ...actions
                  ]));
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  Expanded(child: SingleChildScrollView(child: phase)),
                  const SizedBox(height: FitFlowSpace.sm),
                  ...actions,
                ]);
          }),
        ))),
      ),
    );
  }

  Widget _buildPhaseBody(
    BuildContext context,
    WorkoutPlayerState state,
    WorkoutPlayerController controller,
  ) {
    switch (state.phase) {
      case WorkoutPlayerPhase.ready:
        return _ReadyView(
            state: state,
            sessionMode: _stableMode,
            sessionOrigin: _stableOrigin);
      case WorkoutPlayerPhase.work:
        return WorkoutPlayerExerciseCenter(state: state);
      case WorkoutPlayerPhase.rest:
        return WorkoutPlayerRestView(state: state);
      case WorkoutPlayerPhase.transition:
        return WorkoutPlayerTransitionView(state: state);
      case WorkoutPlayerPhase.sectionBreak:
        return WorkoutPlayerSectionBreakView(state: state);
      case WorkoutPlayerPhase.completed:
        return WorkoutPlayerCompletedView(
          plan: _stablePlan,
          state: state,
          sessionMode: _stableMode,
          sessionOrigin: _stableOrigin,
          onDone: widget.onDone,
          doneRoute: widget.doneRoute,
          completionNote: widget.completionNote,
        );
    }
  }
}

String _appBarTitle(AppLocalizations l, WorkoutSessionOrigin origin) =>
    switch (origin) {
      WorkoutSessionOrigin.custom => l.flowCustom,
      WorkoutSessionOrigin.program => l.flowProgram,
      WorkoutSessionOrigin.adaptive => l.flowPlayer,
    };

class _ReadyView extends StatelessWidget {
  const _ReadyView(
      {required this.state,
      required this.sessionMode,
      required this.sessionOrigin});
  final WorkoutPlayerState state;
  final WorkoutSessionMode sessionMode;
  final WorkoutSessionOrigin sessionOrigin;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xl),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.flowReady,
              style: text.labelLarge, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.md),
          Semantics(
              header: true,
              child: Text(state.currentPrescription.exercise.name,
                  style: text.headlineMedium, textAlign: TextAlign.center)),
          if (state.isCurrentReplaced &&
              state.originalExerciseName != null) ...[
            const SizedBox(height: FitFlowSpace.xs),
            Text(l.flowReplaced(state.originalExerciseName!),
                style: text.bodySmall, textAlign: TextAlign.center),
          ],
          const SizedBox(height: FitFlowSpace.md),
          Text(workloadLabel(l, state.currentPrescription),
              style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xs),
          Text(equipmentSummary(l, state.currentPrescription),
              style: text.bodyMedium, textAlign: TextAlign.center),
          if (sessionOrigin == WorkoutSessionOrigin.custom ||
              sessionOrigin == WorkoutSessionOrigin.program) ...[
            const SizedBox(height: FitFlowSpace.md),
            Text(
                sessionOrigin == WorkoutSessionOrigin.custom
                    ? l.flowReadyCustom
                    : l.flowReadyProgram,
                style: text.bodySmall,
                textAlign: TextAlign.center),
          ],
        ]));
  }
}
