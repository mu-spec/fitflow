import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_controls.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_progress_header.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_rest_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_section_break_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_transition_view.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_empty.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Workout Player screen - core non-voice player for Part 1.
class WorkoutPlayerScreen extends ConsumerWidget {
  const WorkoutPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);

    if (userProfileAsync is AsyncLoading || capabilityProfileAsync is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: const HomeLoadingState(),
      );
    }

    if (userProfileAsync.hasError || capabilityProfileAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: HomeErrorState(
          onRetry: () {
            ref.invalidate(userFitnessProfileProvider);
            ref.invalidate(capabilityProfileProvider);
          },
        ),
      );
    }

    final UserFitnessProfile? userProfile = userProfileAsync.value;
    final CapabilityProfile? capabilityProfile = capabilityProfileAsync.value;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }

    if (capabilityProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: HomeEmptyStates.missingCapabilityProfile(
          context,
          onAction: () => context.go(AppRoutes.capabilityAssessment),
        ),
      );
    }

    final generationContext = WorkoutGenerationContext(
      userProfile: userProfile,
      capabilityProfile: capabilityProfile,
    );

    final WorkoutPlan? plan = WorkoutGenerator.generateCatalog(generationContext);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: const WorkoutPreviewEmpty(),
      );
    }

    return _WorkoutPlayerContent(plan: plan);
  }
}

class _WorkoutPlayerContent extends ConsumerWidget {
  const _WorkoutPlayerContent({required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutPlayerControllerProvider(plan));
    final controller = ref.read(workoutPlayerControllerProvider(plan).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout player'),
        actions: [
          if (state.phase != WorkoutPlayerPhase.ready &&
              state.phase != WorkoutPlayerPhase.completed &&
              state.phase != WorkoutPlayerPhase.sectionBreak)
            IconButton(
              tooltip: state.isPaused ? 'Resume' : 'Pause',
              onPressed: () {
                if (state.isPaused) {
                  controller.resume();
                } else {
                  controller.pause();
                }
              },
              icon: Icon(state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                children: [
                  WorkoutPlayerProgressHeader(state: state),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildPhaseBody(context, state, controller),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WorkoutPlayerControls(state: state, controller: controller),
                  const SizedBox(height: 8),
                ],
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
        return _ReadyView(state: state);
      case WorkoutPlayerPhase.work:
        return WorkoutPlayerExerciseCenter(state: state);
      case WorkoutPlayerPhase.rest:
        return WorkoutPlayerRestView(state: state);
      case WorkoutPlayerPhase.transition:
        return WorkoutPlayerTransitionView(state: state);
      case WorkoutPlayerPhase.sectionBreak:
        return WorkoutPlayerSectionBreakView(state: state);
      case WorkoutPlayerPhase.completed:
        return const WorkoutPlayerCompletedView();
    }
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});

  final WorkoutPlayerState state;

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
        const SizedBox(height: 16),
        Text(
          prescription.exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
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
