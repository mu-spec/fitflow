import 'package:flutter/material.dart';

/// Recognizable shape language. Components do not all share one radius.
class FitFlowRadius {
  const FitFlowRadius._();

  static const double small = 8;
  static const double medium = 12;
  static const double card = 16;
  static const double sheet = 18;
  static const double pill = 999;

  static const BorderRadius smallBorder =
      BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorder =
      BorderRadius.all(Radius.circular(medium));
  static const BorderRadius cardBorder =
      BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius pillBorder =
      BorderRadius.all(Radius.circular(pill));
}
