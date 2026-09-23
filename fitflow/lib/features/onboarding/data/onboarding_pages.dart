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
      title: 'Welcome to FitFlow',
      body:
          'Your workouts will adapt to your strength, time, space and equipment.',
    ),
    OnboardingPage(
      id: 'goal',
      title: 'What is your main goal?',
    ),
    OnboardingPage(
      id: 'experience',
      title: 'What is your current experience?',
    ),
    OnboardingPage(
      id: 'workout_time',
      title: 'How much time do you usually have?',
    ),
    OnboardingPage(
      id: 'environment',
      title: 'Where do you usually train?',
    ),
    OnboardingPage(
      id: 'equipment',
      title: 'What equipment do you have?',
    ),
    OnboardingPage(
      id: 'preferences',
      title: "Let's customize your workouts",
    ),
    OnboardingPage(
      id: 'ready',
      title: "You're ready",
      body:
          'Next, FitFlow will use your preferences to build workouts around you.',
    ),
  ];
}
