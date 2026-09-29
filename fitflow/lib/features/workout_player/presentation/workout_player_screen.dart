import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';

class WorkoutPlayerScreen extends ConsumerWidget {
  const WorkoutPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);
    final sessionMode = ref.watch(workoutSessionModeProvider);

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
      sessionMode: sessionMode,
    );

    final WorkoutPlan? plan = WorkoutGenerator.generateCatalog(generationContext);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout player')),
        body: const Center(child: Text('No workout available.')),
      );
    }

    return WorkoutPlayerSessionView(
      plan: plan,
      sessionMode: sessionMode,
      sessionOrigin: WorkoutSessionOrigin.adaptive,
      doneRoute: AppRoutes.home,
    );
  }
}
