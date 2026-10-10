import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_adaptive_note.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_empty.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_section_header.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_summary_card.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Workout Preview screen showing exact deterministic WorkoutPlan + M12 mode.
class WorkoutPreviewScreen extends ConsumerWidget {
  const WorkoutPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);
    final sessionMode = ref.watch(workoutSessionModeProvider);

    if (userProfileAsync is AsyncLoading ||
        capabilityProfileAsync is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.flowPreview)),
        body: const HomeLoadingState(),
      );
    }

    if (userProfileAsync.hasError || capabilityProfileAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.flowPreview)),
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
        appBar: AppBar(title: Text(context.l10n.flowPreview)),
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }

    if (capabilityProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.flowPreview)),
        body: HomeEmptyStates.missingCapabilityProfile(
          context,
          onAction: () => context.go(AppRoutes.capabilityAssessment),
        ),
      );
    }

    final generationContext = WorkoutGenerationContext(
      userProfile: userProfile,
      capabilityProfile: capabilityProfile,
      sessionMode: sessionMode,
    );

    final WorkoutPlan? plan =
        WorkoutGenerator.generateCatalog(generationContext);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.flowPreview)),
        body: const WorkoutPreviewEmpty(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.flowPreview)),
      body: SafeArea(
          child: FitFlowMaxWidth(
              child: Padding(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360
            ? FitFlowSpace.md
            : FitFlowSpace.xl),
        child: LayoutBuilder(builder: (context, constraints) {
          final start = SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('preview_start'),
                onPressed: () => context.push(AppRoutes.workoutPlayer),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.startWorkout),
              ));
          final content = <Widget>[
            WorkoutPreviewSummaryCard(
                plan: plan,
                userProfile: userProfile,
                effectiveDuration: generationContext.effectiveWorkoutDuration,
                sessionMode: sessionMode),
            const SizedBox(height: FitFlowSpace.md),
            Text(context.l10n.flowPreviewHelp,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: FitFlowSpace.xl),
            WorkoutPreviewSectionHeader(
                title: context.l10n.flowWarmup,
                exerciseCount: plan.warmup.exerciseCount,
                planned: plan.warmupEstimate,
                budget: plan.timeBudget.warmup),
            _buildExerciseList(context, plan.warmup.exercises),
            const SizedBox(height: FitFlowSpace.xl),
            WorkoutPreviewSectionHeader(
                title: context.l10n.flowMain,
                exerciseCount: plan.main.exerciseCount,
                planned: plan.mainEstimate,
                budget: plan.timeBudget.main),
            _buildExerciseList(context, plan.main.exercises),
            const SizedBox(height: FitFlowSpace.xl),
            WorkoutPreviewSectionHeader(
                title: context.l10n.flowCooldown,
                exerciseCount: plan.cooldown.exerciseCount,
                planned: plan.cooldownEstimate,
                budget: plan.timeBudget.cooldown),
            _buildExerciseList(context, plan.cooldown.exercises),
            const SizedBox(height: FitFlowSpace.xl),
            const WorkoutPreviewAdaptiveNote(),
            const SizedBox(height: FitFlowSpace.md),
          ];
          if (constraints.maxHeight < 320) {
            return SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...content, start]));
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: SingleChildScrollView(
                        key: const Key('preview_scroll'),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: content))),
                const SizedBox(height: FitFlowSpace.sm),
                start,
              ]);
        }),
      ))),
    );
  }

  Widget _buildExerciseList(BuildContext context,
          List<WorkoutExercisePrescription> prescriptions) =>
      Column(children: [
        for (final p in prescriptions)
          WorkoutPreviewExerciseRow(prescription: p)
      ]);
}
