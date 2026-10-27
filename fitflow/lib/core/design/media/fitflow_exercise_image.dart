import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:flutter/material.dart';
import 'push_up_icon.dart';
import 'exercise_animation.dart';
import 'exercise_animation_registry.dart';

/// Opt-in replacement for legacy exercise painters. Pass the exact existing
/// exercise ID; keep names, prescriptions, and actions outside this widget.
class FitFlowExerciseImage extends StatelessWidget {
  const FitFlowExerciseImage.thumbnail({
    super.key,
    required this.exerciseId,
    this.width = 72,
    this.height = 72,
    this.decorative = true,
    this.animate = true,
    this.semanticLabel,
  }) : _hero = false;

  const FitFlowExerciseImage.hero({
    super.key,
    required this.exerciseId,
    this.width = 320,
    this.height = 240,
    this.decorative = true,
    this.animate = true,
    this.semanticLabel,
  }) : _hero = true;

  final String exerciseId;
  final double width;
  final double height;
  final bool decorative;
  final bool animate;
  final String? semanticLabel;
  final bool _hero;

  @override
  Widget build(BuildContext context) {
    if (exerciseId == 'pushup_standard') {
      return PushUpIcon(
          animate: animate,
          width: width,
          height: height,
          heroFallback: _hero,
          decorative: decorative,
          semanticLabel: semanticLabel);
    }
    if (ExerciseAnimationRegistry.assetFor(exerciseId) != null) {
      return ExerciseAnimation(
          exerciseId: exerciseId,
          width: width,
          height: height,
          animate: animate,
          heroFallback: _hero,
          decorative: decorative,
          semanticLabel: semanticLabel);
    }
    final spec = ExerciseMediaRegistry.lookup(exerciseId);
    return FitFlowMediaImage(
      asset: _hero ? spec?.hero : spec?.thumbnail,
      width: width,
      height: height,
      decorative: decorative,
      semanticLabel: semanticLabel,
    );
  }
}
