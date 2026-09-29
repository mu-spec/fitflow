/// Centralized limits for custom workout prescription editing (V1).
class CustomWorkoutLimits {
  const CustomWorkoutLimits._();

  static const int setsMin = 1;
  static const int setsMax = 10;

  static const int repsMin = 1;
  static const int repsMax = 100;

  static const int timedWorkMinSec = 5;
  static const int timedWorkMaxSec = 300;

  static const int restMinSec = 0;
  static const int restMaxSec = 300;

  static const int nameMaxLength = 60;
  static const int maxTemplates = 50;
}
