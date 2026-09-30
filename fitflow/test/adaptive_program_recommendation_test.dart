import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveProgramRecommendationPolicy', () {
    test('maps all seven goals exactly', () {
      const expected = {
        FitnessGoal.generalFitness: 'balanced_foundations',
        FitnessGoal.buildStrength: 'strength_foundations',
        FitnessGoal.buildMuscle: 'strength_foundations',
        FitnessGoal.loseWeight: 'endurance_builder',
        FitnessGoal.improveEndurance: 'endurance_builder',
        FitnessGoal.improveMobility: 'mobility_movement',
        FitnessGoal.stayActive: 'stay_active_starter',
      };
      expect(expected.length, FitnessGoal.values.length);
      for (final goal in FitnessGoal.values) {
        expect(
          AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(goal),
          expected[goal],
          reason: goal.name,
        );
        expect(
          AdaptiveProgramRecommendationPolicy.recommendedFor(goal).id,
          expected[goal],
        );
      }
    });

    test('recommended program is always in the catalog', () {
      for (final goal in FitnessGoal.values) {
        final id =
            AdaptiveProgramRecommendationPolicy.recommendedProgramIdFor(goal);
        expect(AdaptiveProgramCatalog.contains(id), isTrue);
      }
    });

    test('recommendation is consistent with definition.recommendedFor', () {
      for (final goal in FitnessGoal.values) {
        final def = AdaptiveProgramRecommendationPolicy.recommendedFor(goal);
        expect(def.recommendedFor, contains(goal));
      }
      // And no other program claims the goal.
      for (final goal in FitnessGoal.values) {
        final claiming = AdaptiveProgramCatalog.all
            .where((p) => p.recommendedFor.contains(goal))
            .toList();
        expect(claiming.length, 1, reason: goal.name);
      }
    });

    test('isRecommended', () {
      expect(
        AdaptiveProgramRecommendationPolicy.isRecommended(
            'balanced_foundations', FitnessGoal.generalFitness),
        isTrue,
      );
      expect(
        AdaptiveProgramRecommendationPolicy.isRecommended(
            'strength_foundations', FitnessGoal.generalFitness),
        isFalse,
      );
      expect(
        AdaptiveProgramRecommendationPolicy.isRecommended(
            'balanced_foundations', null),
        isFalse,
      );
    });

    test('UI wording is factual', () {
      expect(AdaptiveProgramRecommendationPolicy.matchLabel,
          'Matches your selected goal');
      final lower = AdaptiveProgramRecommendationPolicy.matchLabel.toLowerCase();
      expect(lower.contains('best'), isFalse);
      expect(lower.contains('optimal'), isFalse);
      expect(lower.contains('guaranteed'), isFalse);
    });
  });
}
