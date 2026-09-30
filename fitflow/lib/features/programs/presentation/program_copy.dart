/// Centralised, factual UI copy for adaptive programs — M16 Part 1.
///
/// Never claims outcomes (weight loss, best/optimal/guaranteed results).
class ProgramCopy {
  ProgramCopy._();

  // Workouts screen entry
  static const String entryTitle = 'Programs';
  static const String entrySubtitle =
      'Adaptive multi-week workouts built around your current level and setup.';

  // Recommended / active cards
  static const String recommendedTitle = 'Recommended program';
  static const String recommendedMatch = 'Matches your selected goal';
  static const String recommendedMissingProfile =
      'Complete your profile to see a program matched to your selected goal.';
  static const String viewProgram = 'View program';
  static const String activeTitle = 'Active program';
  static const String continueLabel = 'Continue';

  // Overview
  static const String overviewTitle = 'Adaptive programs';
  static const String overviewIntro =
      'Structured multi-week plans whose workouts adapt to your current movement levels and setup.';

  // Detail actions
  static const String startProgram = 'Start program';
  static const String resumeProgram = 'Resume program';
  static const String switchProgram = 'Switch to this program';
  static const String restartProgram = 'Restart program';
  static const String programComplete = 'Program complete';
  static const String viewWorkout = 'View workout';

  // Switch confirmation
  static const String switchDialogTitle = 'Switch active program?';
  static const String switchDialogBody =
      'Your progress in the current program will be kept.';
  static const String switchDialogConfirm = 'Switch';

  // Restart confirmation
  static const String restartDialogTitle = 'Restart this program?';
  static const String restartDialogBody =
      'Its saved program progress will be cleared. Completed workout history will stay unchanged.';
  static const String restartDialogConfirm = 'Restart';

  static const String cancel = 'Cancel';
  static const String actionFailed = "Couldn't save program changes. Try again.";

  // Preview
  static const String previewTitle = 'Program workout';
  static const String adaptationNote =
      'Generated from your current movement levels, equipment, environment, and preferences.';
  static const String goalUnchangedNote =
      'Your saved profile goal is not changed by this program session.';
  static const String generationFailed =
      "This program workout can't be generated with your current setup.";
  static const String startWorkout = 'Start workout';
  static const String startUnavailable =
      'Workout start will be available after program setup finishes.';

  // Not found
  static const String programNotFound = 'Program not found';
  static const String programNotFoundBody =
      "This program isn't available. Go back and choose one from the list.";
  static const String sessionNotFound = 'Session not found';
  static const String sessionNotFoundBody =
      "This session isn't part of the program. Go back and choose one from the program.";

  static String weeksLabel(int weeks) => weeks == 1 ? '1 week' : '$weeks weeks';
  static String perWeekLabel(int n) =>
      n == 1 ? '1 session/week' : '$n sessions/week';
  static String totalLabel(int n) => n == 1 ? '1 workout' : '$n workouts';
  static String completedShort(int done, int total) => '$done of $total completed';
  static String weekLabel(int week) => 'Week $week';
}
