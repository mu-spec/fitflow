import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
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
  ConsumerState<WorkoutPlayerSessionView> createState() => _WorkoutPlayerSessionViewState();
}

class _WorkoutPlayerSessionViewState extends ConsumerState<WorkoutPlayerSessionView> {
  late final AppLifecycleListener _lifecycleListener;
  bool _allowPop = false;
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
      final controller = ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
      final sessionId = controller.sessionId;
      if (_recordedSessionIds.contains(sessionId)) return;
      _recordedSessionIds.add(sessionId);

      final completedWorkout = controller.createCompletedWorkoutSnapshot(plan: _stablePlan);

      // ignore: discarded_futures
      ref.read(workoutHistoryProvider.notifier).addWorkout(completedWorkout).then((success) {
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
      final controller = ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
      final sessionId = controller.sessionId;
      if (_notifiedSessionIds.contains(sessionId)) return;
      _notifiedSessionIds.add(sessionId);

      final completion = WorkoutPlayerCompletion(
        playerSessionId: sessionId,
        completedWorkout: controller.createCompletedWorkoutSnapshot(plan: _stablePlan),
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
      ref.read(workoutPlayerControllerProvider(_stablePlan).notifier).pauseForLifecycle();
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('End workout?'),
        content: const Text("Your current session progress won't be saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End workout'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleReplaceExercise() async {
    final controller = ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);
    final state = ref.read(workoutPlayerControllerProvider(_stablePlan));

    if (!controller.canReplaceCurrentExercise) return;

    if (state.isTimedExercise && state.phase == WorkoutPlayerPhase.work && !state.isPaused) {
      controller.pause();
    }

    final options = controller.getReplacementOptions();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return _ReplacementPicker(
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
    final controller = ref.read(workoutPlayerControllerProvider(_stablePlan).notifier);

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
        ? (state.phase == WorkoutPlayerPhase.ready || state.phase == WorkoutPlayerPhase.completed)
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
          title: Text(_appBarTitle(_stableOrigin)),
          actions: [
            if (_stableOrigin == WorkoutSessionOrigin.adaptive && _stableMode != WorkoutSessionMode.standard)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(_stableMode.label),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            IconButton(
              tooltip: state.voiceEnabled ? 'Mute voice' : 'Enable voice',
              onPressed: () => controller.toggleVoice(),
              icon: Icon(
                state.voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                semanticLabel: state.voiceEnabled ? 'Mute voice' : 'Enable voice',
              ),
            ),
            if (state.phase != WorkoutPlayerPhase.ready &&
                state.phase != WorkoutPlayerPhase.completed &&
                state.phase != WorkoutPlayerPhase.sectionBreak)
              IconButton(
                tooltip: state.isPaused ? 'Resume workout' : 'Pause workout',
                onPressed: () {
                  if (state.isPaused) {
                    controller.resume();
                  } else {
                    controller.pause();
                  }
                },
                icon: Icon(
                  state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  semanticLabel: state.isPaused ? 'Resume workout' : 'Pause workout',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final phase = _buildPhaseBody(context, state, controller);
                    final actions = <Widget>[
                      const SizedBox(height: 8),
                      if (controller.canReplaceCurrentExercise)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleReplaceExercise,
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Replace exercise'),
                            ),
                          ),
                        ),
                      WorkoutPlayerControls(
                        state: state,
                        controller: controller,
                        plan: _stablePlan,
                      ),
                      const SizedBox(height: 8),
                    ];
                    final header = <Widget>[
                      PlayerPhaseAnnouncement(
                        message: playerPhaseAnnouncement(state),
                      ),
                      WorkoutPlayerProgressHeader(state: state),
                      const SizedBox(height: 16),
                      if (state.isCurrentReplaced)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            state.originalExerciseName != null
                                ? 'Replaced ${state.originalExerciseName}'
                                : 'Replaced',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ];
                    // Short landscape heights cannot pin the controls without
                    // overflowing. Taller layouts keep them on screen.
                    if (constraints.maxHeight < 360) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...header, phase, ...actions],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        ...header,
                        Expanded(child: SingleChildScrollView(child: phase)),
                        ...actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
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
        return _ReadyView(state: state, sessionMode: _stableMode, sessionOrigin: _stableOrigin);
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

String _appBarTitle(WorkoutSessionOrigin origin) {
  switch (origin) {
    case WorkoutSessionOrigin.custom:
      return 'Custom workout';
    case WorkoutSessionOrigin.program:
      return 'Program workout';
    case WorkoutSessionOrigin.adaptive:
      return 'Workout player';
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state, required this.sessionMode, required this.sessionOrigin});

  final WorkoutPlayerState state;
  final WorkoutSessionMode sessionMode;
  final WorkoutSessionOrigin sessionOrigin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prescription = state.currentPrescription;
    final isTimed = prescription.workDuration != null;
    final prescriptionText = isTimed
        ? '${prescription.sets} sets × ${prescription.workDuration!.inSeconds} sec'
        : '${prescription.sets} sets × ${prescription.repsPerSet} reps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.self_improvement_outlined,
          size: 64,
          color: theme.colorScheme.primary,
          semanticLabel: 'Warm-up',
        ),
        const SizedBox(height: 16),
        Text(
          'Ready to begin',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Text(
            state.sectionType.name.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (sessionOrigin == WorkoutSessionOrigin.adaptive && sessionMode != WorkoutSessionMode.standard) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            ),
            child: Text(
              '${sessionMode.label} • Temporary for this workout',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (sessionOrigin == WorkoutSessionOrigin.custom) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            ),
            child: Text(
              'Custom workout • Your prescription',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (sessionOrigin == WorkoutSessionOrigin.program) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            ),
            child: Text(
              'Program workout • ${WorkoutSessionMode.standard.label}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          prescription.exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        if (state.isCurrentReplaced && state.originalExerciseName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Replaced ${state.originalExerciseName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (prescription.exercise.movementPattern != null) ...[
          const SizedBox(height: 4),
          Text(
            prescription.exercise.movementPattern!.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          prescriptionText,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Total: ${state.totalSets} sets',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.progressLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          semanticsLabel: 'Progress ${state.completedSets} of ${state.totalSets} sets',
        ),
      ],
    );
  }
}

class _ReplacementPicker extends StatelessWidget {
  const _ReplacementPicker({
    required this.currentPrescription,
    required this.options,
    required this.scrollController,
    required this.onSelect,
    this.originalExerciseName,
  });

  final dynamic currentPrescription;
  final List<WorkoutReplacementOption> options;
  final ScrollController scrollController;
  final void Function(WorkoutReplacementOption) onSelect;
  final String? originalExerciseName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Replace exercise',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Current: ${currentPrescription.exercise.name}', style: theme.textTheme.bodyMedium),
          if (originalExerciseName != null) ...[
            const SizedBox(height: 4),
            Text('Original: $originalExerciseName', style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: options.isEmpty
                ? _NoAlternativesView(scrollController: scrollController)
                : ListView.separated(
                    controller: scrollController,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final exercise = option.exercise;
                      final prescription = option.prescription;
                      final isTimed = prescription.workDuration != null;
                      final workloadText = isTimed
                          ? '${prescription.sets} sets × ${prescription.workDuration!.inSeconds} sec'
                          : '${prescription.sets} sets × ${prescription.repsPerSet} reps';
                      final equipmentText = exercise.requiredEquipment.isEmpty ||
                              exercise.requiredEquipment.contains(
                                // ignore: avoid_dynamic_calls
                                exercise.requiredEquipment.firstWhere(
                                  (e) => e.toString().contains('none'),
                                  orElse: () => exercise.requiredEquipment.first,
                                ),
                              )
                          ? 'No equipment'
                          : exercise.requiredEquipment.map((e) => e.toString().split('.').last).join(', ');

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '${exercise.movementPattern?.label ?? ''} • Level ${exercise.difficulty.toString().split('.').last.replaceAll('level', '')} • $equipmentText',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(workloadText, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Text('Why this works:',
                                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              ...option.reasonLabels.map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• '),
                                      Expanded(child: Text(r, style: theme.textTheme.bodySmall)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Semantics(
                                  button: true,
                                  label: 'Replace with ${exercise.name}',
                                  hint: option.reasonLabels.join('. '),
                                  child: FilledButton(
                                    onPressed: () => onSelect(option),
                                    child: const Text('Use this exercise'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoAlternativesView extends StatelessWidget {
  const _NoAlternativesView({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      children: [
        const SizedBox(height: 32),
        Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('No suitable alternatives',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'No other exercise currently matches this movement, your ability, equipment, environment, and workout preferences.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
