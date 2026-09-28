/// Movement-specific post-workout feedback.
enum MovementWorkoutFeedback {
  tooHard,
  justRight,
  easy,
}

extension MovementWorkoutFeedbackLabel on MovementWorkoutFeedback {
  String get label {
    switch (this) {
      case MovementWorkoutFeedback.tooHard:
        return 'Too hard';
      case MovementWorkoutFeedback.justRight:
        return 'Just right';
      case MovementWorkoutFeedback.easy:
        return 'Easy';
    }
  }

  String get description {
    switch (this) {
      case MovementWorkoutFeedback.tooHard:
        return 'Felt too difficult';
      case MovementWorkoutFeedback.justRight:
        return 'Felt about right';
      case MovementWorkoutFeedback.easy:
        return 'Felt easy';
    }
  }
}
