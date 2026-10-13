import 'dart:math' as math;

import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:flutter/material.dart';

/// Original, abstract program identities. These are visual metaphors, not
/// charts, exercise instructions or representations of program progress.
enum FitFlowV2ProgramMotif {
  balancedPlatforms,
  structuralFrame,
  continuousRoute,
  crossingArcs,
  gentleSteps,
  neutral,
}

/// Decoration-only cover shared by Programs discovery and detail.
///
/// Identity is keyed by stable catalog ID, never a translated display name.
/// All five covers share the existing V2 art palette, rounded slabs, quiet
/// ground line and one warm accent. No images, text, randomness or animation.
class FitFlowV2ProgramCover extends StatelessWidget {
  const FitFlowV2ProgramCover({
    super.key,
    required this.programId,
    this.height = 112,
    this.onHero = false,
    this.borderRadius = FitFlowRadius.mediumBorder,
  });

  final String programId;
  final double height;
  final bool onHero;
  final BorderRadius borderRadius;

  static FitFlowV2ProgramMotif motifFor(String programId) =>
      switch (programId) {
        'balanced_foundations' => FitFlowV2ProgramMotif.balancedPlatforms,
        'strength_foundations' => FitFlowV2ProgramMotif.structuralFrame,
        'endurance_builder' => FitFlowV2ProgramMotif.continuousRoute,
        'mobility_movement' => FitFlowV2ProgramMotif.crossingArcs,
        'stay_active_starter' => FitFlowV2ProgramMotif.gentleSteps,
        _ => FitFlowV2ProgramMotif.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final style = onHero
        ? FitFlowV2ArtStyle.onHero(context)
        : FitFlowV2ArtStyle.standard(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(FitFlowSpace.xs),
          decoration: BoxDecoration(
            color: style.panel,
            borderRadius: borderRadius,
            border: Border.all(color: style.panelEdge),
          ),
          child: CustomPaint(
            painter: FitFlowV2ProgramCoverPainter(
              motif: motifFor(programId),
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small, deterministic vector composition. Uniform scaling preserves its
/// proportions even on a very wide/short cover. Painting has no listeners;
/// theme/identity changes are the only delegate-driven repaint triggers.
class FitFlowV2ProgramCoverPainter extends CustomPainter {
  const FitFlowV2ProgramCoverPainter({
    required this.motif,
    required this.style,
  });

  final FitFlowV2ProgramMotif motif;
  final FitFlowV2ArtStyle style;

  RRect _slab(double x, double y, double width, double height) =>
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        const Radius.circular(7),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 300, size.height / 160);
    if (!scale.isFinite || scale <= 0) return;
    canvas.save();
    canvas.translate(
      (size.width - 300 * scale) / 2,
      (size.height - 160 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawLine(
      const Offset(28, 144),
      const Offset(272, 144),
      artStroke(style.wash.withValues(alpha: .45), 2),
    );
    switch (motif) {
      case FitFlowV2ProgramMotif.balancedPlatforms:
        _balanced(canvas);
      case FitFlowV2ProgramMotif.structuralFrame:
        _strength(canvas);
      case FitFlowV2ProgramMotif.continuousRoute:
        _endurance(canvas);
      case FitFlowV2ProgramMotif.crossingArcs:
        _mobility(canvas);
      case FitFlowV2ProgramMotif.gentleSteps:
        _stayActive(canvas);
      case FitFlowV2ProgramMotif.neutral:
        canvas.drawRRect(_slab(62, 103, 176, 22), artFill(style.wash));
        canvas.drawLine(const Offset(100, 82), const Offset(200, 82),
            artStroke(style.ink, 5));
    }
    canvas.restore();
  }

  // Equal grounded platforms joined by a balanced central bridge.
  void _balanced(Canvas canvas) {
    canvas.drawRRect(
        _slab(40, 122, 220, 16), artFill(style.wash.withValues(alpha: .32)));
    for (final x in [52.0, 178.0]) {
      canvas.drawRRect(_slab(x, 84, 70, 34), artFill(style.wash));
      canvas.drawRRect(_slab(x - 7, 72, 84, 12), artFill(style.ink));
    }
    canvas.drawRRect(_slab(104, 52, 92, 12), artFill(style.ink));
    canvas.drawRRect(_slab(141, 53, 18, 10), artFill(style.accent));
  }

  // A strong open frame with supported corners and quiet diagonal bracing.
  void _strength(Canvas canvas) {
    canvas.drawRRect(_slab(53, 124, 57, 14), artFill(style.wash));
    canvas.drawRRect(_slab(190, 124, 57, 14), artFill(style.wash));
    canvas.drawRRect(_slab(74, 37, 152, 89), artStroke(style.ink, 8));
    canvas.drawLine(
        const Offset(85, 113), const Offset(122, 76), artStroke(style.wash, 5));
    canvas.drawLine(const Offset(215, 113), const Offset(178, 76),
        artStroke(style.wash, 5));
    canvas.drawLine(
        const Offset(88, 55), const Offset(212, 55), artStroke(style.wash, 4));
    canvas.drawCircle(const Offset(226, 37), 7, artFill(style.accent));
  }

  // One continuous route with a repeating curve, not an axis or data plot.
  void _endurance(Canvas canvas) {
    canvas.drawRRect(
        _slab(37, 40, 226, 87), artFill(style.wash.withValues(alpha: .17)));
    canvas.drawPath(
      Path()
        ..moveTo(48, 96)
        ..cubicTo(75, 96, 68, 53, 102, 53)
        ..cubicTo(137, 53, 128, 108, 164, 108)
        ..cubicTo(200, 108, 191, 53, 224, 53)
        ..cubicTo(260, 53, 275, 116, 237, 122)
        ..cubicTo(195, 132, 108, 130, 66, 124),
      artStroke(style.ink, 6),
    );
    canvas.drawCircle(const Offset(48, 96), 6, artFill(style.wash));
    canvas.drawCircle(const Offset(164, 108), 5, artFill(style.wash));
    canvas.drawCircle(const Offset(224, 53), 7, artFill(style.accent));
  }

  // Two broad crossing arcs suggest range and flow without depicting a body.
  void _mobility(Canvas canvas) {
    canvas.drawOval(const Rect.fromLTWH(75, 31, 150, 99),
        artFill(style.wash.withValues(alpha: .17)));
    canvas.drawPath(
      Path()
        ..moveTo(37, 112)
        ..cubicTo(90, 112, 100, 37, 161, 37)
        ..cubicTo(204, 37, 224, 50, 263, 50),
      artStroke(style.ink, 6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(37, 49)
        ..cubicTo(89, 49, 103, 120, 168, 120)
        ..cubicTo(205, 120, 232, 102, 263, 102),
      artStroke(style.wash, 6),
    );
    canvas.drawCircle(const Offset(150, 78), 10, artStroke(style.accent, 3));
  }

  // Low, gentle stepping stones with a small rising movement path.
  void _stayActive(Canvas canvas) {
    canvas.drawRRect(
        _slab(40, 113, 66, 16), artFill(style.wash.withValues(alpha: .65)));
    canvas.drawRRect(_slab(117, 93, 66, 16), artFill(style.wash));
    canvas.drawRRect(_slab(194, 73, 66, 16), artFill(style.ink));
    canvas.drawPath(
      Path()
        ..moveTo(58, 99)
        ..cubicTo(83, 99, 97, 78, 134, 78)
        ..cubicTo(166, 78, 184, 54, 225, 54),
      artStroke(style.ink, 4),
    );
    canvas.drawCircle(const Offset(225, 54), 7, artFill(style.accent));
  }

  @override
  bool shouldRepaint(covariant FitFlowV2ProgramCoverPainter oldDelegate) =>
      motif != oldDelegate.motif ||
      style.panel != oldDelegate.style.panel ||
      style.panelEdge != oldDelegate.style.panelEdge ||
      style.ink != oldDelegate.style.ink ||
      style.wash != oldDelegate.style.wash ||
      style.accent != oldDelegate.style.accent;
}
