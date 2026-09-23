/// Stable internal values for the user's training experience.
enum ExperienceLevel {
  completelyNew('Completely new', 'You have not trained much before.'),
  someExperience('Some experience', 'You have trained now and then.'),
  regularTraining('Regular training', 'You train most weeks.'),
  experienced(
    'Experienced',
    'You train consistently and know your way around.',
  );

  const ExperienceLevel(this.label, this.helperText);

  /// User-facing display label.
  final String label;

  /// Short helper line shown under the option.
  final String helperText;
}
