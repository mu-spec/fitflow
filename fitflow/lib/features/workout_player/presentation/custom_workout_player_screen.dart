import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomWorkoutPlayerScreen extends ConsumerWidget {
  const CustomWorkoutPlayerScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);
    final customAsync = ref.watch(customWorkoutControllerProvider);

    if (userProfileAsync is AsyncLoading ||
        capabilityProfileAsync is AsyncLoading ||
        customAsync is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom workout')),
        body: const HomeLoadingState(),
      );
    }

    if (userProfileAsync.hasError || capabilityProfileAsync.hasError || customAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom workout')),
        body: HomeErrorState(
          onRetry: () {
            ref.invalidate(userFitnessProfileProvider);
            ref.invalidate(capabilityProfileProvider);
            ref.read(customWorkoutControllerProvider.notifier).refresh();
          },
        ),
      );
    }

    final UserFitnessProfile? userProfile = userProfileAsync.value;
    final CapabilityProfile? capabilityProfile = capabilityProfileAsync.value;
    final templates = customAsync.value ?? [];

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom workout')),
        body: HomeEmptyStates.missingUserProfile(
          context,
          onAction: () => context.go(AppRoutes.onboarding),
        ),
      );
    }

    if (capabilityProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom workout')),
        body: HomeEmptyStates.missingCapabilityProfile(
          context,
          onAction: () => context.go(AppRoutes.capabilityAssessment),
        ),
      );
    }

    final template = templates.where((t) => t.id == workoutId).firstOrNull;
    if (template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom workout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Workout not found.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.workouts),
                child: const Text('Back to workouts'),
              ),
            ],
          ),
        ),
      );
    }

    final catalogById = {for (final Exercise e in ExerciseCatalog.all) e.id: e};

    final resolution = CustomWorkoutPlanResolver.resolve(
      template: template,
      catalogById: catalogById,
      userFitnessProfile: userProfile,
      capabilityProfile: capabilityProfile,
    );

    if (resolution.plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(template.name)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This workout needs updates for your current setup.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...resolution.issues.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(i.message)),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.customWorkoutEdit(workoutId)),
                  child: const Text('Edit workout'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Custom workouts ignore M12 modes – use standard as source of truth, do NOT mutate sets/reps
    return WorkoutPlayerSessionView(
      plan: resolution.plan!,
      sessionMode: WorkoutSessionMode.standard,
      sessionOrigin: WorkoutSessionOrigin.custom,
      doneRoute: AppRoutes.workouts,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final e in this) {
      return e;
    }
    return null;
  }
}
