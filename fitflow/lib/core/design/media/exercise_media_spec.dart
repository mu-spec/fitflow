import 'package:flutter/material.dart';

/// Presentation only. Pixel dimensions describe the bundled export, not a
/// prescription. Crops must be reviewed before changing the safe contain fit.
@immutable
class FitFlowMediaAsset {
  const FitFlowMediaAsset({
    required this.path,
    required this.pixelWidth,
    required this.pixelHeight,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String path;
  final int pixelWidth;
  final int pixelHeight;
  final BoxFit fit;
  final Alignment alignment;
}

@immutable
class ExerciseMediaSpec {
  const ExerciseMediaSpec({
    required this.exerciseId,
    required this.thumbnail,
    required this.hero,
    this.secondaryFrame,
  });

  final String exerciseId;
  final FitFlowMediaAsset thumbnail;
  final FitFlowMediaAsset hero;
  final FitFlowMediaAsset? secondaryFrame;

  Iterable<FitFlowMediaAsset> get assets sync* {
    yield thumbnail;
    yield hero;
    if (secondaryFrame != null) yield secondaryFrame!;
  }
}
