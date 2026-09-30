import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/programs/presentation/program_copy.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Program Player (M16 Part 2).
///
/// Resolves the program definition + planned session, generates the workout
/// ONCE from the CURRENT profile and capability via the Part 1 resolver, then
/// freezes the plan and delegates execution to the shared
/// [WorkoutPlayerSessionView]. There is no second execution engine.
///
/// Stable session: once the plan is frozen, profile/capability/provider
/// changes during the workout never regenerate it. The next program session
/// reads the latest state because it opens a new screen.
///
/// M12 independence: always [WorkoutSessionMode.standard]; the Home
/// session-mode provider is never read or reset here.
class ProgramSessionPlayerScreen extends ConsumerStatefulWidget {
  const ProgramSessionPlayerScreen({
    super.key,
    required this.programId,
    required this.sessionId,
  });

  final String programId;
  final String sessionId;

  @override
  ConsumerState<ProgramSessionPlayerScreen> createState() =>
      _ProgramSessionPlayerScreenState();
}

class _ProgramSessionPlayerScreenState
    extends ConsumerState<ProgramSessionPlayerScreen> {
  /// Frozen at first successful generation; never replaced afterwards.
  WorkoutPlan? _frozenPlan;
  String? _generationIssue;

  /// Last completion handed to us by the Player. Kept so Done can make one
  /// final, idempotent save attempt if the first attempt failed.
  WorkoutPlayerCompletion? _lastCompletion;
  bool _progressSaved = false;

  Future<bool> _handleWorkoutCompleted(WorkoutPlayerCompletion c) async {
    _lastCompletion = c;
    return _saveProgress(c);
  }

  /// Marks the planned session complete. Idempotent at the controller level
  /// (planned session ID + Player session ID), so retries are safe. Returns
  /// false when persistence failed — the session then stays incomplete.
  Future<bool> _saveProgress(WorkoutPlayerCompletion c) async {
    if (_progressSaved) return true;
    try {
      final ok = await ref
          .read(adaptiveProgramsControllerProvider.notifier)
          .markSessionCompleted(
            programId: widget.programId,
            plannedSessionId: widget.sessionId,
            playerSessionId: c.playerSessionId,
            completedAt: c.completedWorkout.completedAt,
          );
      if (ok) _progressSaved = true;
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleDone() async {
    final pending = _lastCompletion;
    if (pending != null && !_progressSaved) {
      // One final safe retry; failure is reported truthfully by the detail
      // screen (session remains "Next", not "Completed").
      await _saveProgress(pending);
    }
    if (!mounted) return;
    context.go(AppRoutes.programDetail(widget.programId));
  }

  @override
  Widget build(BuildContext context) {
    final definition = AdaptiveProgramCatalog.byId(widget.programId);
    if (definition == null) {
      return _NotFoundScaffold(
        appBarTitle: ProgramCopy.programNotFound,
        title: ProgramCopy.programNotFound,
        body: ProgramCopy.programNotFoundBody,
        actionLabel: ProgramCopy.backToPrograms,
        onAction: () => context.go(AppRoutes.programs),
      );
    }
    final session = definition.sessionById(widget.sessionId);
    if (session == null) {
      return _NotFoundScaffold(
        appBarTitle: definition.name,
        title: ProgramCopy.playerWorkoutNotFound,
        body: ProgramCopy.playerWorkoutNotFoundBody,
        actionLabel: ProgramCopy.backToProgram,
        onAction: () => context.go(AppRoutes.programDetail(definition.id)),
      );
    }

    final frozen = _frozenPlan;
    if (frozen != null) {
      return _buildPlayer(frozen, definition);
    }
    if (_generationIssue != null) {
      return _buildGenerationFailed(definition, _generationIssue!);
    }

    final appBar = AppBar(title: const Text(ProgramCopy.playerTitle));
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityAsync = ref.watch(capabilityProfileProvider);

    if (userProfileAsync.isLoading || capabilityAsync.isLoading) {
      return Scaffold(appBar: appBar, body: const HomeLoadingState());
    }
    if (userProfileAsync.hasError || capabilityAsync.hasError) {
      return Scaffold(
        appBar: appBar,
        body: HomeErrorState(onRetry: () {
          ref.invalidate(userFitnessProfileProvider);
          ref.invalidate(capabilityProfileProvider);
        }),
      );
    }
    final userProfile = userProfileAsync.value;
    final capability = capabilityAsync.value;
    if (userProfile == null) {
      return Scaffold(
        appBar: appBar,
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }
    if (capability == null) {
      return Scaffold(
        appBar: appBar,
        body: HomeEmptyStates.missingCapabilityProfile(
          context,
          onAction: () => context.go(AppRoutes.capabilityAssessment),
        ),
      );
    }

    // Generate exactly once through the Part 1 resolver, then freeze.
    final resolution = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: userProfile,
      capabilityProfile: capability,
    );
    final plan = resolution.plan;
    if (plan == null) {
      final message =
          resolution.issue?.message ?? ProgramCopy.generationFailed;
      _generationIssue = message;
      return _buildGenerationFailed(definition, message);
    }
    _frozenPlan = plan;
    return _buildPlayer(plan, definition);
  }

  Widget _buildPlayer(WorkoutPlan plan, AdaptiveProgramDefinition definition) {
    return WorkoutPlayerSessionView(
      plan: plan,
      sessionMode: WorkoutSessionMode.standard,
      sessionOrigin: WorkoutSessionOrigin.program,
      onDone: _handleDone,
      doneRoute: AppRoutes.programDetail(definition.id),
      onWorkoutCompleted: _handleWorkoutCompleted,
      completionNote: ProgramCopy.programWorkoutCompleted,
    );
  }

  Widget _buildGenerationFailed(
      AdaptiveProgramDefinition definition, String message) {
    return Scaffold(
      appBar: AppBar(title: const Text(ProgramCopy.playerTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.go(AppRoutes.programDetail(definition.id)),
                child: const Text(ProgramCopy.backToProgram),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundScaffold extends StatelessWidget {
  const _NotFoundScaffold({
    required this.appBarTitle,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String appBarTitle;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProgramNotFoundBody(title: title, body: body),
          const SizedBox(height: 8),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
