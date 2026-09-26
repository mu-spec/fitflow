/// Floor space an exercise needs.
enum SpaceRequirement {
  tiny('Tiny'),
  small('Small'),
  medium('Medium'),
  large('Large');

  const SpaceRequirement(this.label);

  /// User-facing display label.
  final String label;
}
