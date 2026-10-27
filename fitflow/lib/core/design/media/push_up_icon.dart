import 'package:flutter/material.dart';
import 'exercise_animation.dart';

/// Convenience wrapper for Standard Push-Up in tiles, cards and the Player.
class PushUpIcon extends StatelessWidget {
  const PushUpIcon(
      {super.key,
      this.width = 72,
      this.height = 72,
      this.animate = true,
      this.decorative = true,
      this.semanticLabel,
      this.heroFallback = false});
  final double width, height;
  final bool animate, decorative, heroFallback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => ExerciseAnimation(
      exerciseId: 'pushup_standard',
      width: width,
      height: height,
      animate: animate,
      decorative: decorative,
      semanticLabel: semanticLabel,
      heroFallback: heroFallback);
}
