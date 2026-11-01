import 'package:flutter/material.dart';

/// Full-width photography with a separate caption that never covers the athlete.
/// The caption grows with text scale instead of clipping inside a fixed card.
class HomePhotoSurface extends StatelessWidget {
  const HomePhotoSurface(
      {super.key,
      required this.width,
      required this.image,
      required this.color,
      required this.child});
  final double width;
  final Widget image;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          image,
          Padding(padding: const EdgeInsets.all(16), child: child),
        ]),
      );
}
