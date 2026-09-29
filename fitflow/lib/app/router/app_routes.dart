class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String capabilityAssessment = '/capability-assessment';
  static const String home = '/home';
  static const String workoutPreview = '/home/workout-preview';
  static const String workoutPlayer = '/home/workout-preview/player';
  static const String workouts = '/workouts';
  static const String exerciseLibrary = '/workouts/exercise-library';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String settings = '/profile/settings';

  static String exerciseDetail(String exerciseId) =>
      '/workouts/exercise-library/$exerciseId';

  // Custom workout builder routes – M13
  static const String customWorkoutNew = '/workouts/custom/new';
  static String customWorkoutDetail(String workoutId) => '/workouts/custom/$workoutId';
  static String customWorkoutEdit(String workoutId) => '/workouts/custom/$workoutId/edit';
  static String customWorkoutPlayer(String workoutId) => '/workouts/custom/$workoutId/player';
}
