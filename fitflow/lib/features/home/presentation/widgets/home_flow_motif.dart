import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:flutter/material.dart';

/// Original, static flowing-track artwork. Abstract movement, not exercise
/// instruction, a progress gauge, a score, or an app logo. No asset or ticker.
class HomeFlowMotif extends StatelessWidget {
  const HomeFlowMotif({super.key});
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return ExcludeSemantics(
        child: SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(painter: HomeFlowPainter(v.action, v.onHero)),
    ));
  }
}

class HomeFlowPainter extends CustomPainter {
  const HomeFlowPainter(this.mint, this.light);
  final Color mint, light;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Three open paths with different bend radii suggest an adaptable track.
    for (var i = 0; i < 3; i++) {
      final offset = i * 18.0;
      final path = Path()
        ..moveTo(16, 110 + offset)
        ..cubicTo(105, 110 + offset, 132, 88 + offset, 96, 65 + offset)
        ..cubicTo(50, 40 + offset, 60, 12 + offset, 135, 12 + offset);
      paint
        ..strokeWidth = i == 1 ? 10 : 5
        ..color = i == 1 ? mint : light.withValues(alpha: i == 0 ? .30 : .65);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HomeFlowPainter oldDelegate) =>
      mint != oldDelegate.mint || light != oldDelegate.light;
}
