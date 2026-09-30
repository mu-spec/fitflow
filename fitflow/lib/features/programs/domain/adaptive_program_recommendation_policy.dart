import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';

/// Pure recommendation policy — maps the user's saved goal to exactly one
/// built-in program.
///
/// UI wording is "Matches your selected goal". It is never described as
/// best/optimal/guaranteed and all programs remain manually selectable.
class AdaptiveProgramRecommendationPolicy {
  AdaptiveProgramRecommendationPolicy._();

  /// Exact goal → program ID mapping.
  static String recommendedProgramIdFor(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.generalFitness:
        return AdaptiveProgramCatalog.balancedFoundationsId;
      case FitnessGoal.buildStrength:
      case FitnessGoal.buildMuscle:
        return AdaptiveProgramCatalog.strengthFoundationsId;
      case FitnessGoal.loseWeight:
      case FitnessGoal.improveEndurance:
        return AdaptiveProgramCatalog.enduranceBuilderId;
      case FitnessGoal.improveMobility:
        return AdaptiveProgramCatalog.mobilityMovementId;
      case FitnessGoal.stayActive:
        return AdaptiveProgramCatalog.stayActiveStarterId;
    }
  }

  /// Recommended definition for [goal].
  static AdaptiveProgramDefinition recommendedFor(FitnessGoal goal) {
    final def = AdaptiveProgramCatalog.byId(recommendedProgramIdFor(goal));
    // The catalog always contains every mapped ID; guard defensively.
    if (def == null) {
      throw StateError('Recommended program missing for ${goal.name}');
    }
    return def;
  }

  /// Whether [programId] is the recommended program for [goal].
  static bool isRecommended(String programId, FitnessGoal? goal) {
    if (goal == null) return false;
    return recommendedProgramIdFor(goal) == programId;
  }

  /// Exact UI wording for the recommended program.
  static const String matchLabel = 'Matches your selected goal';
}
