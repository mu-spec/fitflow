import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:flutter/material.dart';

/// A neutral movement-media slot, not an exercise demonstration. Step 6 can
/// supply [artwork] without replacing Preview/Player layout. Identity and
/// prescriptions always remain real semantic text outside this decoration.
class FitFlowV2WorkoutMedia extends StatelessWidget {
  const FitFlowV2WorkoutMedia({
    super.key,
    required this.height,
    this.onHero = false,
    this.artwork,
  });

  final double height;
  final bool onHero;
  final Widget? artwork;

  @override
  Widget build(BuildContext context) {
    final style = onHero
        ? FitFlowV2ArtStyle.onHero(context)
        : FitFlowV2ArtStyle.standard(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.panel,
              borderRadius: FitFlowRadius.mediumBorder,
              border: Border.all(color: style.panelEdge),
            ),
            child: ClipRRect(
              borderRadius: FitFlowRadius.mediumBorder,
              child: artwork ??
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: CustomPaint(
                      painter: FitFlowV2WorkoutMovementPainter(style),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pure presentation measurements. Art yields before copy or controls; no
/// text-scale clamp, fixed aspect ratio, session key, animation or device name.
class WorkoutV2Layout {
  WorkoutV2Layout._();

  static Size viewport(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (!size.isEmpty) return size;
    final view = View.of(context);
    return view.physicalSize / view.devicePixelRatio;
  }

  static bool largeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) > 22;

  static double mediaHeight(BuildContext context, {bool player = false}) {
    if (largeText(context) || viewport(context).height < 400) return 48;
    if (!player) return viewport(context).width < 360 ? 80 : 104;
    if (viewport(context).height < 750) return 112;
    return 152;
  }
}

/// One original, static flow mark shared by every exercise: two grounded
/// slabs, crossing movement paths and one warm geometric accent. No figure,
/// anatomy, chart, text, exercise lookup, randomness or loop.
class FitFlowV2WorkoutMovementPainter extends CustomPainter {
  const FitFlowV2WorkoutMovementPainter(this.style);
  final FitFlowV2ArtStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = (size.width / 300).clamp(0.0, size.height / 140);
    canvas.save();
    canvas.translate(
        (size.width - 300 * scale) / 2, (size.height - 140 * scale) / 2);
    canvas.scale(scale);
    canvas.drawLine(const Offset(35, 122), const Offset(265, 122),
        artStroke(style.wash.withValues(alpha: .42), 2));
    for (final x in [46.0, 201.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 108, 53, 10), const Radius.circular(5)),
          artFill(style.wash));
    }
    canvas.drawPath(
      Path()
        ..moveTo(52, 91)
        ..cubicTo(101, 91, 104, 36, 148, 36)
        ..cubicTo(192, 36, 199, 92, 247, 92),
      artStroke(style.ink, 6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(61, 54)
        ..cubicTo(108, 54, 114, 103, 153, 103)
        ..cubicTo(194, 103, 211, 53, 238, 53),
      artStroke(style.wash, 5),
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(137, 32, 24, 8), const Radius.circular(4)),
        artFill(style.accent));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FitFlowV2WorkoutMovementPainter oldDelegate) =>
      style.panel != oldDelegate.style.panel ||
      style.panelEdge != oldDelegate.style.panelEdge ||
      style.ink != oldDelegate.style.ink ||
      style.wash != oldDelegate.style.wash ||
      style.accent != oldDelegate.style.accent;
}
