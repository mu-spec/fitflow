import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_generation_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/foundation.dart';

/// Truthful reasons why a program workout could not be generated.
enum AdaptiveProgramWorkoutIssue {
  /// The planned session does not belong to the given program definition.
  sessionNotInProgram,

  /// The existing generator could not build a complete valid plan from the
  /// user's current setup.
  noValidPlan,
}

extension AdaptiveProgramWorkoutIssueCopy on AdaptiveProgramWorkoutIssue {
  String get message {
    switch (this) {
      case AdaptiveProgramWorkoutIssue.sessionNotInProgram:
        return 'This session is not part of the selected program.';
      case AdaptiveProgramWorkoutIssue.noValidPlan:
        return "This program workout can't be generated with your current setup.";
    }
  }
}

/// Result of resolving one program session into a current WorkoutPlan.
@immutable
class AdaptiveProgramWorkoutResolution {
  const AdaptiveProgramWorkoutResolution._({
    required this.session,
    required this.generationProfile,
    this.plan,
    this.issue,
    this.context,
  });

  const AdaptiveProgramWorkoutResolution.success({
    required AdaptiveProgramSession session,
    required UserFitnessProfile generationProfile,
    required WorkoutGenerationContext context,
    required WorkoutPlan plan,
  }) : this._(
          session: session,
          generationProfile: generationProfile,
          context: context,
          plan: plan,
        );

  const AdaptiveProgramWorkoutResolution.failure({
    required AdaptiveProgramSession session,
    required UserFitnessProfile generationProfile,
    required AdaptiveProgramWorkoutIssue issue,
    WorkoutGenerationContext? context,
  }) : this._(
          session: session,
          generationProfile: generationProfile,
          context: context,
          issue: issue,
        );

  final AdaptiveProgramSession session;

  /// Temporary profile used for generation (goal overridden). Never saved.
  final UserFitnessProfile generationProfile;

  /// Generation context actually used (null only for sessionNotInProgram).
  final WorkoutGenerationContext? context;

  /// Valid current plan on success.
  final WorkoutPlan? plan;

  /// Truthful issue on failure.
  final AdaptiveProgramWorkoutIssue? issue;

  bool get isSuccess => plan != null && issue == null;
}

/// Pure resolver — generates a program session workout using the EXISTING
/// `WorkoutGenerator` from the CURRENT profile and capability.
///
/// Always uses [WorkoutSessionMode.standard]. It never reads the Home
/// session-mode provider, so Low Energy / Comeback cannot change program
/// sessions. Never persists the generated plan. No fallback fake plan.
class AdaptiveProgramWorkoutResolver {
  AdaptiveProgramWorkoutResolver._();

  static AdaptiveProgramWorkoutResolution resolve({
    required AdaptiveProgramDefinition definition,
    required AdaptiveProgramSession session,
    required UserFitnessProfile userProfile,
    required CapabilityProfile capabilityProfile,
  }) {
    final generationProfile = AdaptiveProgramGenerationProfile.forSession(
      current: userProfile,
      session: session,
    );

    if (session.programId != definition.id ||
        !definition.containsSession(session.id)) {
      return AdaptiveProgramWorkoutResolution.failure(
        session: session,
        generationProfile: generationProfile,
        issue: AdaptiveProgramWorkoutIssue.sessionNotInProgram,
      );
    }

    final context = WorkoutGenerationContext(
      userProfile: generationProfile,
      capabilityProfile: capabilityProfile,
      sessionMode: WorkoutSessionMode.standard,
    );

    final plan = WorkoutGenerator.generateCatalog(context);
    if (plan == null) {
      return AdaptiveProgramWorkoutResolution.failure(
        session: session,
        generationProfile: generationProfile,
        context: context,
        issue: AdaptiveProgramWorkoutIssue.noValidPlan,
      );
    }

    return AdaptiveProgramWorkoutResolution.success(
      session: session,
      generationProfile: generationProfile,
      context: context,
      plan: plan,
    );
  }
}
