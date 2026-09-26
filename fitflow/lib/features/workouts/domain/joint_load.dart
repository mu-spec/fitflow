/// Load placed on a specific joint. Used for wrist and knee load.
enum JointLoad {
  none('None'),
  low('Low'),
  moderate('Moderate'),
  high('High');

  const JointLoad(this.label);

  /// User-facing display label.
  final String label;
}
