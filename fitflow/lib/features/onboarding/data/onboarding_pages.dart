/// Definition of a single onboarding step.
class OnboardingPage {
  const OnboardingPage({
    required this.id,
    required this.title,
    this.body,
  });

  /// Stable identifier for the step.
  final String id;

  /// Heading shown at the top of the page.
  final String title;

  /// Descriptive text. Steps without body text show a placeholder box until
  /// real content is added in a later milestone.
  final String? body;
}

/// All onboarding steps in display order.
class OnboardingPages {
  OnboardingPages._();

  static const List<OnboardingPage> all = [
    OnboardingPage(
      id: 'welcome',
      title: 'Welcome to Home Workout',
      body: 'A few choices to shape your workouts.',
    ),
    OnboardingPage(
      id: 'goal',
      title: 'Your main goal',
    ),
    OnboardingPage(
      id: 'experience',
      title: 'Your training experience',
    ),
    OnboardingPage(
      id: 'workout_time',
      title: 'Time for a workout',
    ),
    OnboardingPage(
      id: 'environment',
      title: 'Your training space',
    ),
    OnboardingPage(
      id: 'equipment',
      title: 'Available equipment',
    ),
    OnboardingPage(
      id: 'preferences',
      title: "Your workout preferences",
    ),
    OnboardingPage(
      id: 'ready',
      title: "One last step",
      body:
          'Next, Home Workout will use your preferences to build workouts around you.',
    ),
  ];
}
