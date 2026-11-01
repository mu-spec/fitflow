import 'package:fitflow/features/home/presentation/widgets/home_discovery_sections.dart';
import 'package:fitflow/features/home/presentation/home_theme.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/widgets/home_empty_states.dart';
import 'package:fitflow/features/home/presentation/widgets/home_error_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_header.dart';
import 'package:fitflow/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitflow/features/home/presentation/widgets/home_personalization_card.dart';
import 'package:fitflow/features/home/presentation/widgets/home_session_mode_widgets.dart';
import 'package:fitflow/features/home/presentation/widgets/home_workout_hero_card.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/session/comeback_suggestion_policy.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Real Home dashboard powered by profile, capability, and adaptive generator + M12 session modes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeTheme(child: _HomeContent());
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);
    final sessionMode = ref.watch(workoutSessionModeProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    // Loading state: either provider loading
    if (userProfileAsync is AsyncLoading ||
        capabilityProfileAsync is AsyncLoading) {
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

    // Both profiles valid -> generate workout using session mode
    final generationContext = WorkoutGenerationContext(
      userProfile: userProfile,
      capabilityProfile: capabilityProfile,
      sessionMode: sessionMode,
    );

    final WorkoutPlan? plan =
        WorkoutGenerator.generateCatalog(generationContext);

    // Determine comeback suggestion
    bool showComebackSuggestion = false;
    final history = historyAsync.valueOrNull;
    if (history != null && history.isNotEmpty) {
      try {
        showComebackSuggestion = ComebackSuggestionPolicy.shouldSuggestComeback(
          history: history,
          now: DateTime.now(),
        );
      } catch (_) {
        showComebackSuggestion = false;
      }
    }

    // Presentation only: the same generated plan, mode and comeback policy.
    return Scaffold(
        backgroundColor: FitFlowVisualV2.of(context).page,
        body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .48, 1],
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [
                        Color(0xFF323E5A),
                        Color(0xFF1B1F20),
                        Color(0xFF1B1F20)
                      ]
                    : const [
                        Color(0xFFD8DFFA),
                        Color(0xFFF2F3F5),
                        Color(0xFFF2F3F5)
                      ],
              ),
            ),
            child:
                SafeArea(child: LayoutBuilder(builder: (context, constraints) {
              const inset = FitFlowSpace.md;
              return SingleChildScrollView(
                  child: FitFlowMaxWidth(
                      child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: inset, vertical: FitFlowSpace.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeHeader(),
                      const SizedBox(height: 8),
                      if (history != null)
                        HomeActivityStrip(history: history, now: DateTime.now())
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(historyAsync.hasError
                              ? context.l10n.trainingHistoryError
                              : context.l10n.trainingHistoryLoading),
                        ),
                      const SizedBox(height: 20),
                      Semantics(
                          header: true,
                          child: Text(context.l10n.homeTitle,
                              style: Theme.of(context).textTheme.titleMedium)),
                      const SizedBox(height: 10),
                      if (plan == null) ...[
                        HomeEmptyStates.noWorkoutAvailable(context,
                            userProfile: userProfile),
                        const SizedBox(height: FitFlowSpace.md),
                        const HomeSessionModeControl(),
                      ] else
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: SystemMotion.standard(context),
                          curve: FitFlowMotion.standardCurve,
                          builder: (_, value, child) =>
                              Opacity(opacity: value, child: child),
                          child: HomeWorkoutHeroCard(
                              plan: plan,
                              userProfile: userProfile,
                              effectiveDuration:
                                  generationContext.effectiveWorkoutDuration,
                              sessionMode: sessionMode),
                        ),
                      if (showComebackSuggestion) ...[
                        const SizedBox(height: FitFlowSpace.lg),
                        const ComebackSuggestionCard(),
                      ],
                      const SizedBox(height: 12),
                      const HomeProgramsShelf(),
                      const SizedBox(height: 12),
                      HomePersonalizationCard(
                          userProfile: userProfile, plan: plan),
                    ]),
              )));
            }))));
  }
}
