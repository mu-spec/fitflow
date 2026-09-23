/// Stable internal values for where the user usually trains.
enum TrainingEnvironment {
  apartment('Apartment / quiet space'),
  normalHome('Normal home'),
  smallRoom('Small room'),
  largeRoom('Large room'),
  hotel('Hotel / travel'),
  outdoor('Outdoor');

  const TrainingEnvironment(this.label);

  /// User-facing display label.
  final String label;
}
