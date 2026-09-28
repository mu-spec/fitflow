import 'package:fitflow/app/config/app_dimensions.dart';
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
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Workout Preview screen showing exact deterministic WorkoutPlan.
class WorkoutPreviewScreen extends ConsumerWidget {
  const WorkoutPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);

    if (userProfileAsync is AsyncLoading || capabilityProfileAsync is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout preview')),
        body: const HomeLoadingState(),
      );
    }

    if (userProfileAsync.hasError || capabilityProfileAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout preview')),
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
        appBar: AppBar(title: const Text('Workout preview')),
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }

    if (capabilityProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout preview')),
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
        appBar: AppBar(title: const Text('Workout preview')),
        body: const WorkoutPreviewEmpty(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout preview'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkoutPreviewSummaryCard(plan: plan, userProfile: userProfile),
                  const SizedBox(height: 24),
                  // Warm-up
                  WorkoutPreviewSectionHeader(
                    title: 'Warm-up',
                    exerciseCount: plan.warmup.exerciseCount,
                    planned: plan.warmupEstimate,
                    budget: plan.timeBudget.warmup,
                  ),
                  const SizedBox(height: 8),
                  _buildExerciseList(context, plan.warmup.exercises),
                  const SizedBox(height: 24),
                  // Main
                  WorkoutPreviewSectionHeader(
                    title: 'Main workout',
                    exerciseCount: plan.main.exerciseCount,
                    planned: plan.mainEstimate,
                    budget: plan.timeBudget.main,
                  ),
                  const SizedBox(height: 8),
                  _buildExerciseList(context, plan.main.exercises),
                  const SizedBox(height: 24),
                  // Cooldown
                  WorkoutPreviewSectionHeader(
                    title: 'Cooldown',
                    exerciseCount: plan.cooldown.exerciseCount,
                    planned: plan.cooldownEstimate,
                    budget: plan.timeBudget.cooldown,
                  ),
                  const SizedBox(height: 8),
                  _buildExerciseList(context, plan.cooldown.exercises),
                  const SizedBox(height: 24),
                  const WorkoutPreviewAdaptiveNote(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, List<WorkoutExercisePrescription> prescriptions) {
    return Column(
      children: prescriptions.map<Widget>((pres) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WorkoutPreviewExerciseRow(prescription: pres),
        );
      }).toList(),
    );
  }
}
