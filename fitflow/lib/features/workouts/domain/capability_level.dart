import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';

/// Strongly typed per-movement capability level, 1 (easiest) to 5 (hardest).
///
/// Do NOT use Beginner/Intermediate/Advanced globally - level belongs to one movement.
enum CapabilityLevel {
  level1('Level 1'),
  level2('Level 2'),
  level3('Level 3'),
  level4('Level 4'),
  level5('Level 5');

  const CapabilityLevel(this.label);

  /// User-facing display label.
  final String label;

  /// Numeric rank 1-5 for comparison and mapping.
  int get rank {
    switch (this) {
      case CapabilityLevel.level1:
        return 1;
      case CapabilityLevel.level2:
        return 2;
      case CapabilityLevel.level3:
        return 3;
      case CapabilityLevel.level4:
        return 4;
      case CapabilityLevel.level5:
        return 5;
    }
  }

  bool isHigherThan(CapabilityLevel other) => rank > other.rank;
  bool isLowerThan(CapabilityLevel other) => rank < other.rank;

  /// Centralized mapping to exercise difficulty.
  ExerciseDifficulty toExerciseDifficulty() {
    switch (this) {
      case CapabilityLevel.level1:
        return ExerciseDifficulty.level1;
      case CapabilityLevel.level2:
        return ExerciseDifficulty.level2;
      case CapabilityLevel.level3:
        return ExerciseDifficulty.level3;
      case CapabilityLevel.level4:
        return ExerciseDifficulty.level4;
      case CapabilityLevel.level5:
        return ExerciseDifficulty.level5;
    }
  }

  static CapabilityLevel fromExerciseDifficulty(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.level1:
        return CapabilityLevel.level1;
      case ExerciseDifficulty.level2:
        return CapabilityLevel.level2;
      case ExerciseDifficulty.level3:
        return CapabilityLevel.level3;
      case ExerciseDifficulty.level4:
        return CapabilityLevel.level4;
      case ExerciseDifficulty.level5:
        return CapabilityLevel.level5;
    }
  }
}
