import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:flutter/material.dart';

/// FitFlow's original feature-illustration family, introduced by Visual V2
/// Step 3 for the Workouts hub and reusable by later feature entries.
///
/// One coherent "premium editorial fitness" language builds every artwork
/// from the same elements: rounded geometric slabs, single movement paths
/// with round caps, node milestones and faint ground lines in the emerald /
/// mint palette with one restrained warm accent. The compositions are
/// gender-neutral themes of progression, user-built content and movement
/// exploration — never anatomy, medical graphics, photo instruction, copied
/// competitor imagery or logo shapes. No embedded text. No assets or network.
///
/// All paintings are static, deterministic and decoration-only
/// ([ExcludeSemantics]); painters only repaint when a color input changes.
enum FitFlowV2FeatureArtKind {
  /// Structured training over time: ascending weekly terraces, one guided
  /// path and milestone nodes rising across them.
  programs,

  /// User-authored training: a stack they assembled plus tuning sliders.
  customWorkout,

  /// Movement exploration: an atlas of movement tiles with a focus ring.
  exerciseLibrary,

  /// Secondary progression tool: a base node branching upward into skills.
  skillTree,
}

/// Explicit color set for one artwork, tuned for the surface it sits on —
/// intentionally chosen, never a mechanical inversion for dark mode.
class FitFlowV2ArtStyle {
  const FitFlowV2ArtStyle({
    required this.panel,
    required this.panelEdge,
    required this.ink,
    required this.wash,
    required this.accent,
  });

  /// Quiet plate behind the composition.
  final Color panel;

  final Color panelEdge;

  /// Strongest stroke: the leading path or highlighted piece.
  final Color ink;

  /// Supporting strokes and filled slabs.
  final Color wash;

  /// Single restrained warm accent (destination node, one control).
  final Color accent;

  /// Style for artwork placed on ordinary/tinted page surfaces.
  static FitFlowV2ArtStyle standard(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    final t = FitFlowTheme.of(context);
    return FitFlowV2ArtStyle(
      panel: v.tint,
      panelEdge: v.subtleBorder,
      ink: t.brand,
      wash: Color.lerp(v.tint, t.brand, .38)!,
      accent: t.accent,
    );
  }

  /// Style for artwork placed on the V2 hero gradient. Colors stay legible
  /// on the emerald hero in both themes because they derive from the hero's
  /// own contrasting roles rather than being inverted.
  static FitFlowV2ArtStyle onHero(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    final t = FitFlowTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FitFlowV2ArtStyle(
      panel: v.onHero.withValues(alpha: .07),
      panelEdge: v.heroLine,
      ink: v.action,
      wash: Color.lerp(v.heroStart, v.onHero, dark ? .55 : .62)!,
      accent: Color.lerp(v.onHero, t.accent, dark ? .30 : .22)!,
    );
  }
}

/// One static, decoration-only feature artwork with its own quiet panel.
class FitFlowV2FeatureArt extends StatelessWidget {
  const FitFlowV2FeatureArt({
    super.key,
    required this.kind,
    this.onHero = false,
    this.width,
    this.height,
    this.borderRadius = FitFlowRadius.mediumBorder,
    this.padding = const EdgeInsets.all(4),
  });

  final FitFlowV2FeatureArtKind kind;
  final bool onHero;

  /// Unbounded when null; callers size the panel with the surrounding layout.
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  /// Inner margin so strokes never touch the panel edge.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = onHero
        ? FitFlowV2ArtStyle.onHero(context)
        : FitFlowV2ArtStyle.standard(context);
    final painter = switch (kind) {
      FitFlowV2FeatureArtKind.programs => FitFlowV2ProgramsPainter(style),
      FitFlowV2FeatureArtKind.customWorkout =>
        FitFlowV2CustomWorkoutPainter(style),
      FitFlowV2FeatureArtKind.exerciseLibrary =>
        FitFlowV2ExerciseLibraryPainter(style),
      FitFlowV2FeatureArtKind.skillTree => FitFlowV2SkillTreePainter(style),
    };
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: style.panel,
          borderRadius: borderRadius,
          border: Border.all(color: style.panelEdge),
        ),
        padding: padding,
        child: CustomPaint(painter: painter),
      ),
    );
  }
}

/// Round-capped stroke used for every path in the family.
Paint artStroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeWidth = width
  ..color = color;

Paint artFill(Color color) => Paint()
  ..style = PaintingStyle.fill
  ..color = color;

RRect _artSlab(
        double left, double top, double right, double bottom, double radius) =>
    RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));

/// Shared geometry for the family. Positions are fractions of the panel so a
/// composition stays legible from a 48dp explore chip to a wide feature
/// banner; stroke weight follows the short edge like vector linework would.
abstract class _FitFlowV2ArtPainter extends CustomPainter {
  const _FitFlowV2ArtPainter(this.style);

  final FitFlowV2ArtStyle style;

  /// Faint anchor under every composition: "the floor this trains on".
  void groundLine(Canvas canvas, double w, double h, double u) {
    canvas.drawLine(
      Offset(w * .05, h * .9),
      Offset(w * .95, h * .9),
      artStroke(style.wash.withValues(alpha: .5), u * .035),
    );
  }

  /// Kind identity counts: swapping compositions with the same palette
  /// must still repaint.
  @override
  bool shouldRepaint(covariant _FitFlowV2ArtPainter oldDelegate) =>
      runtimeType != oldDelegate.runtimeType ||
      style.panel != oldDelegate.style.panel ||
      style.panelEdge != oldDelegate.style.panelEdge ||
      style.ink != oldDelegate.style.ink ||
      style.wash != oldDelegate.style.wash ||
      style.accent != oldDelegate.style.accent;
}

/// Programs: "Path and terraces". Three ascending week-terraces with one
/// guided route climbing them and milestone nodes — structured training that
/// progresses. Deliberately abstract: no calendar clone, no bar chart, no
/// fake completion numbers.
class FitFlowV2ProgramsPainter extends _FitFlowV2ArtPainter {
  const FitFlowV2ProgramsPainter(super.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = w < h ? w : h; // short edge drives stroke weight
    if (u <= 0) return;

    // Week terraces: increasing height, left-aligned rhythm, rising wash.
    final tops = [h * .62, h * .5, h * .36];
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        _artSlab(
            w * (.07 + i * .3), tops[i], w * (.34 + i * .3), h * .88, u * .07),
        artFill(style.wash.withValues(alpha: .34 + .16 * i)),
      );
    }
    groundLine(canvas, w, h, u);

    // One guided path climbing the terraces, ending at the destination node.
    canvas.drawPath(
      Path()
        ..moveTo(w * .09, h * .84)
        ..cubicTo(w * .2, h * .84, w * .18, h * .58, w * .27, h * .56)
        ..lineTo(w * .41, h * .56)
        ..cubicTo(w * .5, h * .56, w * .49, h * .44, w * .58, h * .44)
        ..lineTo(w * .7, h * .44)
        ..cubicTo(w * .79, h * .44, w * .79, h * .28, w * .86, h * .26),
      artStroke(style.ink, u * .05),
    );
    // Milestone markers along the plan; destination ringed in warm accent.
    canvas.drawCircle(Offset(w * .27, h * .56), u * .045, artFill(style.wash));
    canvas.drawCircle(Offset(w * .58, h * .44), u * .045, artFill(style.wash));
    canvas.drawCircle(
        Offset(w * .86, h * .26), u * .085, artStroke(style.accent, u * .028));
    canvas.drawCircle(Offset(w * .86, h * .26), u * .042, artFill(style.ink));
  }
}

/// Custom workouts: "Built by you". A left stack of rounded slabs the user
/// assembled — the top one still being placed — plus tuning sliders on the
/// right. Nobody is lifting anything; the authorship is the subject.
class FitFlowV2CustomWorkoutPainter extends _FitFlowV2ArtPainter {
  const FitFlowV2CustomWorkoutPainter(super.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = w < h ? w : h;
    if (u <= 0) return;

    // Assembled stack: successive slabs rise with their own footing inset.
    final base = h * .88;
    final slabH = h * .15;
    final gap = h * .035;
    final lefts = [w * .07, w * .1, w * .13];
    final widths = [w * .36, w * .31, w * .26];
    for (var i = 0; i < 3; i++) {
      final bottom = base - i * (slabH + gap);
      canvas.drawRRect(
        _artSlab(
            lefts[i], bottom - slabH, lefts[i] + widths[i], bottom, u * .06),
        artFill(style.wash.withValues(alpha: .38 + .13 * i)),
      );
    }
    // The slab being placed: raised, ink-filled, with two motion ticks.
    final top = base - 3 * (slabH + gap) - h * .02;
    canvas.drawLine(Offset(w * .16, top + slabH + h * .02),
        Offset(w * .16, top + slabH + h * .07), artStroke(style.ink, u * .03));
    canvas.drawLine(Offset(w * .3, top + slabH + h * .02),
        Offset(w * .3, top + slabH + h * .07), artStroke(style.ink, u * .03));
    canvas.drawRRect(
      _artSlab(w * .165, top, w * .165 + w * .21, top + slabH, u * .06),
      artFill(style.ink),
    );

    // Tuning sliders: three tracks with knobs at their own positions.
    final rows = [h * .34, h * .54, h * .74];
    final knobs = [w * .72, w * .64, w * .86];
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * .56, rows[i]),
        Offset(w * .94, rows[i]),
        artStroke(style.wash.withValues(alpha: .55), u * .035),
      );
      canvas.drawCircle(Offset(knobs[i], rows[i]), u * .05,
          artFill(i == 2 ? style.accent : style.ink));
    }
  }
}

/// Exercise Library: "Movement atlas". A 2×3 field of atlas tiles holding
/// abstract movement marks, with one focus ring singling out a movement —
/// referencing/browsing, not instruction. Tiles are never screenshots.
class FitFlowV2ExerciseLibraryPainter extends _FitFlowV2ArtPainter {
  const FitFlowV2ExerciseLibraryPainter(super.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = w < h ? w : h;
    if (u <= 0) return;
    final cell = h * .3;
    final inset = u * .06;

    RRect at(double cx, double cy) => RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: cell, height: cell),
        Radius.circular(u * .06));

    // Atlas tiles; two carry original movement marks, others stay quiet.
    final centers = <Offset>[
      Offset(w * .115, h * .31),
      Offset(w * .115 + cell + inset, h * .31),
      Offset(w * .115, h * .31 + cell + inset),
      Offset(w * .115 + cell + inset, h * .31 + cell + inset),
    ];
    for (final c in centers) {
      canvas.drawRRect(
          at(c.dx, c.dy), artFill(style.wash.withValues(alpha: .22)));
    }
    // Abstract movement marks inside the left column of tiles.
    final cellPaint = artStroke(style.wash, u * .04);
    canvas.drawPath(
      Path()
        ..moveTo(w * .065, h * .39)
        ..cubicTo(w * .09, h * .22, w * .15, h * .2, w * .165, h * .36),
      cellPaint,
    );
    canvas.drawCircle(Offset(w * .15, h * .22), u * .038, artFill(style.wash));
    canvas.drawPath(
      Path()
        ..moveTo(w * .06, h * .74)
        ..lineTo(w * .105, h * .62)
        ..lineTo(w * .15, h * .7)
        ..lineTo(w * .175, h * .58),
      cellPaint,
    );

    // Focus ring: one movement singled out for a closer look.
    final focus = Offset(w * .72, h * .5);
    canvas.drawCircle(focus, h * .3, artStroke(style.ink, u * .04));
    canvas.drawLine(
      Offset(focus.dx + h * .22, focus.dy + h * .22),
      Offset(focus.dx + h * .34, focus.dy + h * .34),
      artStroke(style.ink, u * .045),
    );
    canvas.drawPath(
      Path()
        ..moveTo(focus.dx - h * .14, focus.dy + h * .1)
        ..cubicTo(focus.dx - h * .04, focus.dy - h * .12, focus.dx + h * .07,
            focus.dy - h * .02, focus.dx + h * .13, focus.dy + h * .08),
      artStroke(style.accent, u * .04),
    );
  }
}

/// Skill trees: "Branching path". One base node growing upward into split
/// branches with their own nodes — a progression tree, secondary to the main
/// features by weight of linework, not a flow track, not a logo mark.
class FitFlowV2SkillTreePainter extends _FitFlowV2ArtPainter {
  const FitFlowV2SkillTreePainter(super.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = w < h ? w : h;
    if (u <= 0) return;

    final base = Offset(w * .5, h * .82);
    final fork = Offset(w * .5, h * .55);
    final left = Offset(w * .31, h * .32);
    final right = Offset(w * .7, h * .27);

    groundLine(canvas, w, h, u);
    canvas.drawLine(base, fork, artStroke(style.wash, u * .05));
    canvas.drawPath(
      Path()
        ..moveTo(fork.dx, fork.dy)
        ..cubicTo(w * .42, h * .47, w * .36, h * .42, left.dx, left.dy),
      artStroke(style.wash, u * .05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fork.dx, fork.dy)
        ..cubicTo(w * .58, h * .48, w * .64, h * .37, right.dx, right.dy),
      artStroke(style.wash, u * .05),
    );
    // Side bud: progression is a tree, not a single lane.
    canvas.drawCircle(Offset(w * .2, h * .55), u * .04, artFill(style.wash));
    canvas.drawLine(Offset(w * .38, h * .48), Offset(w * .2, h * .55),
        artStroke(style.wash.withValues(alpha: .7), u * .035));

    canvas.drawCircle(base, u * .06, artFill(style.ink));
    canvas.drawCircle(fork, u * .05, artFill(style.ink));
    canvas.drawCircle(left, u * .05, artFill(style.wash));
    // Growth tip ringed in warm accent: where the path is heading.
    canvas.drawCircle(right, u * .085, artStroke(style.accent, u * .028));
    canvas.drawCircle(right, u * .042, artFill(style.ink));
  }
}
