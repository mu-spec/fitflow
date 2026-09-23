/// Stable internal values for the user's main training goal.
enum FitnessGoal {
  generalFitness('General fitness'),
  buildStrength('Build strength'),
  buildMuscle('Build muscle'),
  loseWeight('Lose weight'),
  improveEndurance('Improve endurance'),
  improveMobility('Improve mobility'),
  stayActive('Stay active');

  const FitnessGoal(this.label);

  /// User-facing display label.
  final String label;
}
