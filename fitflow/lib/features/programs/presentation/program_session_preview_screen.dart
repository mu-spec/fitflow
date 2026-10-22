import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_copy.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_section_header.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Program session preview — generated at load from the CURRENT profile and
/// capability through the existing generator. Never persisted.
///
/// Start navigates to the program Player route (Part 2).
class ProgramSessionPreviewScreen extends ConsumerWidget {
  const ProgramSessionPreviewScreen({
    super.key,
    required this.programId,
    required this.sessionId,
  });

  final String programId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkoutsTheme(
      child: _ProgramSessionPreviewContent(
          programId: programId, sessionId: sessionId));
}

class _ProgramSessionPreviewContent extends ConsumerWidget {
  const _ProgramSessionPreviewContent({
    required this.programId,
    required this.sessionId,
  });

  final String programId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = FitFlowVisualV2.of(context);
    final definition = AdaptiveProgramCatalog.byId(programId);
    if (definition == null) {
      return Scaffold(
        backgroundColor: visual.page,
        appBar: AppBar(
          title: const Text(ProgramCopy.programNotFound),
          backgroundColor: visual.page,
          scrolledUnderElevation: 0,
        ),
        body: const ProgramNotFoundBody(
          title: ProgramCopy.programNotFound,
          body: ProgramCopy.programNotFoundBody,
        ),
      );
    }
    final session = definition.sessionById(sessionId);
    if (session == null) {
      return Scaffold(
        backgroundColor: visual.page,
        appBar: AppBar(
          title: Text(definition.name),
          backgroundColor: visual.page,
          scrolledUnderElevation: 0,
        ),
        body: const ProgramNotFoundBody(
          title: ProgramCopy.sessionNotFound,
          body: ProgramCopy.sessionNotFoundBody,
        ),
      );
    }

    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityAsync = ref.watch(capabilityProfileProvider);
    final programsState = ref.watch(adaptiveProgramsControllerProvider).value ??
        AdaptiveProgramsState.empty;
    final status = AdaptiveProgramStatus(
      definition: definition,
      progress: programsState.progressFor(definition.id),
    );

    final appBar = AppBar(
      title: const Text(ProgramCopy.previewTitle),
      backgroundColor: visual.page,
      scrolledUnderElevation: 0,
    );

    if (userProfileAsync.isLoading || capabilityAsync.isLoading) {
      return Scaffold(
        backgroundColor: visual.page,
        appBar: appBar,
        body: const HomeLoadingState(),
      );
    }
    if (userProfileAsync.hasError || capabilityAsync.hasError) {
      return Scaffold(
        backgroundColor: visual.page,
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
        backgroundColor: visual.page,
        appBar: appBar,
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }
    if (capability == null) {
      return Scaffold(
        backgroundColor: visual.page,
        appBar: appBar,
        body: HomeEmptyStates.missingCapabilityProfile(
          context,
          onAction: () => context.go(AppRoutes.capabilityAssessment),
        ),
      );
    }

    // Always Standard mode; the Home session-mode provider is never read here.
    final resolution = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: userProfile,
      capabilityProfile: capability,
    );

    final plan = resolution.plan;

    return Scaffold(
      backgroundColor: visual.page,
      appBar: appBar,
      body: SafeArea(
        child: FitFlowMaxWidth(
          maxWidth: FitFlowLayout.maxContentWidth,
          child: ListView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 360
                  ? FitFlowSpace.md
                  : FitFlowSpace.xl,
            ),
            children: [
              _ProgramSessionSummaryCard(
                definition: definition,
                session: session,
                status: status.statusOf(session),
                targetMinutes: userProfile.workoutDuration.minutes,
                plan: plan,
              ),
              const SizedBox(height: FitFlowSpace.sm),
              _NoteCard(
                icon: Icons.info_outline,
                lines: const [
                  ProgramCopy.adaptationNote,
                  ProgramCopy.goalUnchangedNote,
                ],
              ),
              const SizedBox(height: FitFlowSpace.xl),
              if (plan == null)
                _GenerationFailedCard(
                  message:
                      resolution.issue?.message ?? ProgramCopy.generationFailed,
                )
              else ...[
                WorkoutPreviewSectionHeader(
                  title: 'Warm-up',
                  visualV2: true,
                  exerciseCount: plan.warmup.exerciseCount,
                  planned: plan.warmupEstimate,
                  budget: plan.timeBudget.warmup,
                ),
                const SizedBox(height: FitFlowSpace.xs),
                _exerciseList(plan.warmup.exercises),
                const SizedBox(height: FitFlowSpace.xl),
                WorkoutPreviewSectionHeader(
                  title: 'Main workout',
                  visualV2: true,
                  exerciseCount: plan.main.exerciseCount,
                  planned: plan.mainEstimate,
                  budget: plan.timeBudget.main,
                ),
                const SizedBox(height: FitFlowSpace.xs),
                _exerciseList(plan.main.exercises),
                const SizedBox(height: FitFlowSpace.xl),
                WorkoutPreviewSectionHeader(
                  title: 'Cooldown',
                  visualV2: true,
                  exerciseCount: plan.cooldown.exerciseCount,
                  planned: plan.cooldownEstimate,
                  budget: plan.timeBudget.cooldown,
                ),
                const SizedBox(height: FitFlowSpace.xs),
                _exerciseList(plan.cooldown.exercises),
                const SizedBox(height: FitFlowSpace.xl),
                // Part 2: Start opens the shared Player for this planned
                // session. The Player generates its own frozen plan from
                // the current profile/capability at open time.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 56),
                    ),
                    onPressed: () => context.push(
                      AppRoutes.programSessionPlayer(definition.id, session.id),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(ProgramCopy.startWorkout),
                  ),
                ),
              ],
              const SizedBox(height: FitFlowSpace.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseList(List<WorkoutExercisePrescription> prescriptions) {
    return Column(
      children: [
        for (final pres in prescriptions)
          Padding(
            padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
            child: WorkoutPreviewExerciseRow(
              prescription: pres,
              visualV2: true,
            ),
          ),
      ],
    );
  }
}

class _ProgramSessionSummaryCard extends StatelessWidget {
  const _ProgramSessionSummaryCard({
    required this.definition,
    required this.session,
    required this.status,
    required this.targetMinutes,
    required this.plan,
  });

  final AdaptiveProgramDefinition definition;
  final AdaptiveProgramSession session;
  final AdaptiveProgramSessionStatus status;
  final int targetMinutes;
  final WorkoutPlan? plan;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) return '< 1 min';
    return '${(totalSeconds / 60).ceil()} min';
  }

  int _totalSets(WorkoutPlan p) =>
      p.allPrescriptions.fold<int>(0, (sum, pres) => sum + pres.sets);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fitFlowTheme = FitFlowTheme.of(context);
    final p = plan;
    return FitFlowV2InfoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            definition.name,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: .8,
              fontWeight: FontWeight.w500,
              color: FitFlowTheme.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Semantics(
            header: true,
            child: Text(
              session.title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Wrap(
            spacing: FitFlowSpace.sm,
            runSpacing: FitFlowSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Focus: ${session.focus}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: fitFlowTheme.textSecondary),
              ),
              ProgramSessionStatusChip(status: status),
            ],
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            'Session goal: ${session.generationGoal.label}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: fitFlowTheme.textSecondary),
          ),
          const SizedBox(height: FitFlowSpace.md),
          Wrap(
            spacing: FitFlowSpace.xs,
            runSpacing: FitFlowSpace.xs,
            children: [
              _metric(Icons.timer_outlined, '$targetMinutes min target'),
              if (p != null) ...[
                _metric(Icons.timelapse_outlined,
                    '~${_formatDuration(p.estimatedDuration)} planned'),
                _metric(Icons.fitness_center_outlined,
                    '${p.totalExerciseCount} exercises'),
                _metric(Icons.repeat, '${_totalSets(p)} sets'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return FitFlowV2Tag(text, icon: icon);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.lines});

  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fitFlowTheme = FitFlowTheme.of(context);
    return FitFlowV2InfoSurface(
      tonal: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 18, color: fitFlowTheme.textSecondary),
          ),
          const SizedBox(width: FitFlowSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: FitFlowSpace.xs),
                  Text(
                    lines[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fitFlowTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationFailedCard extends StatelessWidget {
  const _GenerationFailedCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FitFlowErrorState(
      title: message,
      message:
          'Your current environment, equipment, or workout preferences leave too few compatible exercises for a complete session.',
    );
  }
}
