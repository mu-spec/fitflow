import 'package:flutter/material.dart';

/// Full-width photography with a readable colored caption over its lower edge.
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
        child: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: image),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: width * .43),
            Container(
              constraints: BoxConstraints(minHeight: width * .32),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: .92), color],
              )),
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ]),
        ]),
      );
}
