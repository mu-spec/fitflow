/// Intentional spacing scale. Prefer these over raw [EdgeInsets] values.
class FitFlowSpace {
  const FitFlowSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Horizontal inset for phone screens. Kept at the existing 24 so current
  /// screens do not reflow before their dedicated redesigns.
  static const double screenHorizontal = 24;

  static const double section = 24;
  static const double cardPadding = 16;
  static const double compact = 8;
  static const double control = 12;
  static const double list = 12;

  static const List<double> scale = [xxs, xs, sm, md, lg, xl, xxl, xxxl, huge];
}
