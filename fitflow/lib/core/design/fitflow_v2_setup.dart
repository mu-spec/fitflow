import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:flutter/material.dart';

/// Opt-in setup selections. Native controls supply tap/focus/selection behavior.
/// Constant border width avoids layout movement when selection changes.
class FitFlowV2SelectionSurface extends StatelessWidget {
  const FitFlowV2SelectionSurface(
      {super.key, required this.selected, required this.child});
  final bool selected;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return AnimatedContainer(
      duration: SystemMotion.micro(context),
      decoration: BoxDecoration(
        color: selected ? v.heroStart : v.support,
        borderRadius: FitFlowRadius.mediumBorder,
        border: Border.all(
            width: 2,
            color: selected ? FitFlowTheme.of(context).brand : v.subtleBorder),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// A compact bottom boundary, used inside each screen's existing safe area.
class FitFlowV2ActionSurface extends StatelessWidget {
  const FitFlowV2ActionSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
          color: v.page,
          border: Border(top: BorderSide(color: v.subtleBorder))),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
          child: child),
    );
  }

  static ButtonStyle primaryStyle(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.styleFrom(
      backgroundColor: dark ? v.action : v.heroStart,
      foregroundColor: dark ? v.onAction : v.onHero,
      minimumSize: const Size(64, 56),
      overlayColor: (dark ? v.onAction : v.action).withValues(alpha: .16),
    );
  }
}

/// Compact options form two readable columns when space and text allow it.
/// Row-major source order and full text are preserved; no fixed card heights.
class FitFlowV2OptionGrid extends StatelessWidget {
  const FitFlowV2OptionGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final two = c.maxWidth >= 300 &&
            MediaQuery.textScalerOf(context).scale(16) <= 22;
        return Wrap(spacing: FitFlowSpace.xs, runSpacing: 0, children: [
          for (final child in children)
            SizedBox(
                width: two ? (c.maxWidth - FitFlowSpace.xs) / 2 : c.maxWidth,
                child: child),
        ]);
      });
}

/// Original abstract branching movement tracks, not an exercise illustration,
/// anatomy diagram, score, or progress chart. Static and decoration-only.
class FitFlowV2AdaptiveMotif extends StatelessWidget {
  const FitFlowV2AdaptiveMotif({super.key, this.size = 104});
  final double size;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return ExcludeSemantics(
        child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
                painter: FitFlowV2AdaptivePainter(v.action, v.onHero))));
  }
}

class FitFlowV2AdaptivePainter extends CustomPainter {
  const FitFlowV2AdaptivePainter(this.mint, this.light);
  final Color mint, light;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = 22.0 + i * 34;
      paint
        ..color = i == 1 ? mint : light.withValues(alpha: .40)
        ..strokeWidth = i == 1 ? 9 : 4;
      canvas.drawPath(
          Path()
            ..moveTo(12, 106 - i * 10)
            ..cubicTo(55, 106 - i * 10, 49, y, 98, y),
          paint);
      canvas.drawCircle(Offset(105, y), i == 1 ? 5 : 3,
          Paint()..color = i == 1 ? mint : light.withValues(alpha: .65));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FitFlowV2AdaptivePainter oldDelegate) =>
      mint != oldDelegate.mint || light != oldDelegate.light;
}
