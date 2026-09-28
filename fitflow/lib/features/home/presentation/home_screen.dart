import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_adaptive_explanation.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_header.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_movement_focus.dart';
import 'package:fitflow/features/home/presentation/widgets/home_personalization_card.dart';
import 'package:fitflow/features/home/presentation/widgets/home_workout_hero_card.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Real Home dashboard powered by profile, capability, and adaptive generator.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);

    // Loading state: either provider loading
    if (userProfileAsync is AsyncLoading || capabilityProfileAsync is AsyncLoading) {
      return const HomeLoadingState();
    }

    // Error state: either has error
    if (userProfileAsync.hasError || capabilityProfileAsync.hasError) {
      return HomeErrorState(
        onRetry: () {
          ref.invalidate(userFitnessProfileProvider);
          ref.invalidate(capabilityProfileProvider);
        },
      );
    }

    final UserFitnessProfile? userProfile = userProfileAsync.value;
    final CapabilityProfile? capabilityProfile = capabilityProfileAsync.value;

    // Missing user profile
    if (userProfile == null) {
      return HomeEmptyStates.missingUserProfile(
        context,
        onAction: () {
          // Navigate to onboarding if routing supports it
          context.go(AppRoutes.onboarding);
        },
      );
    }

    // Missing capability profile
    if (capabilityProfile == null) {
      return HomeEmptyStates.missingCapabilityProfile(
        context,
        onAction: () {
          context.go(AppRoutes.capabilityAssessment);
        },
      );
    }

    // Both profiles valid -> generate workout
    final generationContext = WorkoutGenerationContext(
      userProfile: userProfile,
      capabilityProfile: capabilityProfile,
    );

    final WorkoutPlan? plan = WorkoutGenerator.generateCatalog(generationContext);

    // No complete workout available
    if (plan == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: 24),
                    HomeEmptyStates.noWorkoutAvailable(context, userProfile: userProfile),
                    const SizedBox(height: 24),
                    HomePersonalizationCard(userProfile: userProfile),
                    const SizedBox(height: 16),
                    _buildLibraryShortcut(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Successful dashboard
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 24),
                  HomeWorkoutHeroCard(
                    plan: plan,
                    userProfile: userProfile,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.workoutPreview);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View workout'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  HomeMovementFocus(plan: plan),
                  const SizedBox(height: 16),
                  HomePersonalizationCard(userProfile: userProfile),
                  const SizedBox(height: 16),
                  const HomeAdaptiveExplanation(),
                  const SizedBox(height: 24),
                  _buildLibraryShortcut(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryShortcut(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(AppRoutes.exerciseLibrary);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.library_books_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse exercises',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explore the full exercise library',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
