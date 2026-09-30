import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = AdaptiveProgramCatalog.byId(programId);
    if (definition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(ProgramCopy.programNotFound)),
        body: const ProgramNotFoundBody(
          title: ProgramCopy.programNotFound,
          body: ProgramCopy.programNotFoundBody,
        ),
      );
    }
    final session = definition.sessionById(sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(definition.name)),
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

    final appBar = AppBar(title: const Text(ProgramCopy.previewTitle));

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

    // Always Standard mode; the Home session-mode provider is never read here.
    final resolution = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: userProfile,
      capabilityProfile: capability,
    );

    final plan = resolution.plan;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: [
                _ProgramSessionSummaryCard(
                  definition: definition,
                  session: session,
                  status: status.statusOf(session),
                  targetMinutes: userProfile.workoutDuration.minutes,
                  plan: plan,
                ),
                const SizedBox(height: 12),
                _NoteCard(
                  icon: Icons.info_outline,
                  lines: const [
                    ProgramCopy.adaptationNote,
                    ProgramCopy.goalUnchangedNote,
                  ],
                ),
                const SizedBox(height: 24),
                if (plan == null)
                  _GenerationFailedCard(
                    message: resolution.issue?.message ??
                        ProgramCopy.generationFailed,
                  )
                else ...[
                  WorkoutPreviewSectionHeader(
                    title: 'Warm-up',
                    exerciseCount: plan.warmup.exerciseCount,
                    planned: plan.warmupEstimate,
                    budget: plan.timeBudget.warmup,
                  ),
                  const SizedBox(height: 8),
                  _exerciseList(plan.warmup.exercises),
                  const SizedBox(height: 24),
                  WorkoutPreviewSectionHeader(
                    title: 'Main workout',
                    exerciseCount: plan.main.exerciseCount,
                    planned: plan.mainEstimate,
                    budget: plan.timeBudget.main,
                  ),
                  const SizedBox(height: 8),
                  _exerciseList(plan.main.exercises),
                  const SizedBox(height: 24),
                  WorkoutPreviewSectionHeader(
                    title: 'Cooldown',
                    exerciseCount: plan.cooldown.exerciseCount,
                    planned: plan.cooldownEstimate,
                    budget: plan.timeBudget.cooldown,
                  ),
                  const SizedBox(height: 8),
                  _exerciseList(plan.cooldown.exercises),
                  const SizedBox(height: 24),
                  // Part 2: Start opens the shared Player for this planned
                  // session. The Player generates its own frozen plan from
                  // the current profile/capability at open time.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.programSessionPlayer(
                            definition.id, session.id),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(ProgramCopy.startWorkout),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: WorkoutPreviewExerciseRow(prescription: pres),
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
    final colors = theme.colorScheme;
    final p = plan;
    return Card(
      elevation: 0,
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              definition.name,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              session.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Focus: ${session.focus}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onPrimaryContainer),
                ),
                ProgramSessionStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Session goal: ${session.generationGoal.label}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _metric(context, Icons.timer_outlined, '$targetMinutes min target'),
                if (p != null) ...[
                  _metric(context, Icons.timelapse_outlined,
                      '~${_formatDuration(p.estimatedDuration)} planned'),
                  _metric(context, Icons.fitness_center_outlined,
                      '${p.totalExerciseCount} exercises'),
                  _metric(context, Icons.repeat, '${_totalSets(p)} sets'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onPrimaryContainer),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.lines});

  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Text(
                    lines[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_outlined,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your current environment, equipment, or workout preferences leave too few compatible exercises for a complete session.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
