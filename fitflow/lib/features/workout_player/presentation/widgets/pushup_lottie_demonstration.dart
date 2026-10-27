import 'package:fitflow/core/design/media/push_up_icon.dart';
import 'package:flutter/material.dart';

/// Player adapter preserves its existing phase/pause decision while reusing
/// the same media as Library, summaries, history and exercise details.
class PushupLottieDemonstration extends StatelessWidget {
  const PushupLottieDemonstration(
      {super.key,
      required this.width,
      required this.height,
      required this.animate});
  final double width, height;
  final bool animate;

  @override
  Widget build(BuildContext context) => PushUpIcon(
      width: width, height: height, animate: animate, heroFallback: true);
}
