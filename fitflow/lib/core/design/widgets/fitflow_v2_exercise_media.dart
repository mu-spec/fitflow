import 'dart:math' as math;

import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Stable, presentation-only inputs for FitFlow's reusable exercise artwork.
///
/// This descriptor deliberately carries existing canonical metadata rather
/// than exercise names, IDs, or localized labels. A single scalable painter
/// interprets each movement, position, and equipment hint; the descriptor is
/// not a second exercise catalog.
@immutable
class FitFlowV2ExerciseVisualDescriptor {
  const FitFlowV2ExerciseVisualDescriptor._({
    required this.movementPattern,
    required this.bodyPosition,
    required this.equipmentHints,
  });

  /// Builds a visual descriptor from canonical exercise fields only.
  factory FitFlowV2ExerciseVisualDescriptor.fromExercise(Exercise exercise) {
    return FitFlowV2ExerciseVisualDescriptor.fromCanonicalMetadata(
      movementPattern: exercise.movementPattern,
      bodyPosition: exercise.bodyPosition,
      requiredEquipment: exercise.requiredEquipment,
    );
  }

  /// Builds a descriptor from canonical metadata without requiring an
  /// [Exercise]. Missing fields are retained as neutral fallbacks by the
  /// painter. `WorkoutEquipment.none` does not create an equipment glyph.
  factory FitFlowV2ExerciseVisualDescriptor.fromCanonicalMetadata({
    MovementPattern? movementPattern,
    ExercisePosition? bodyPosition,
    Iterable<WorkoutEquipment>? requiredEquipment,
  }) {
    final equipmentHints = requiredEquipment
            ?.where((item) => item != WorkoutEquipment.none)
            .toSet()
            .toList() ??
        <WorkoutEquipment>[];
    // Enum order is canonical and locale-independent; sort so Set/Iterable
    // insertion order cannot alter a descriptor or its painted hint.
    equipmentHints.sort((left, right) => left.index.compareTo(right.index));

    return FitFlowV2ExerciseVisualDescriptor._(
      movementPattern: movementPattern,
      bodyPosition: bodyPosition,
      equipmentHints: List<WorkoutEquipment>.unmodifiable(equipmentHints),
    );
  }

  /// Canonical movement family; null uses a neutral, non-prescriptive cue.
  final MovementPattern? movementPattern;

  /// Canonical body position; null uses an abstract neutral posture mark.
  final ExercisePosition? bodyPosition;

  /// Canonical non-`none` equipment hints, in stable enum order.
  final List<WorkoutEquipment> equipmentHints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitFlowV2ExerciseVisualDescriptor &&
          other.movementPattern == movementPattern &&
          other.bodyPosition == bodyPosition &&
          listEquals(other.equipmentHints, equipmentHints);

  @override
  int get hashCode => Object.hash(
        movementPattern,
        bodyPosition,
        Object.hashAll(equipmentHints),
      );
}

/// Decorative, theme-aware exercise artwork shared by future FitFlow surfaces.
///
/// Give [width] and [height] a compact size for a thumbnail/badge or a larger
/// size for a future hero. Both constructors use the same canonical mapping
/// and painter, so consuming screens do not need a separate visual system.
class FitFlowV2ExerciseMedia extends StatelessWidget {
  const FitFlowV2ExerciseMedia({
    super.key,
    required this.descriptor,
    this.width,
    this.height,
    this.onHero = false,
    this.borderRadius = FitFlowRadius.mediumBorder,
  });

  FitFlowV2ExerciseMedia.forExercise({
    super.key,
    required Exercise exercise,
    this.width,
    this.height,
    this.onHero = false,
    this.borderRadius = FitFlowRadius.mediumBorder,
  }) : descriptor = FitFlowV2ExerciseVisualDescriptor.fromExercise(exercise);

  /// A stable descriptor made from canonical movement, position, and equipment.
  final FitFlowV2ExerciseVisualDescriptor descriptor;

  /// Optional layout constraints. With neither provided, the artwork has a
  /// natural 180 × 132 logical-pixel size, subject to parent constraints.
  final double? width;
  final double? height;

  /// Uses the same palette adapted for artwork placed on a V2 hero surface.
  final bool onHero;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final visualDescriptor = descriptor;
    final style = onHero
        ? FitFlowV2ArtStyle.onHero(context)
        : FitFlowV2ArtStyle.standard(context);
    final painter = _FitFlowV2ExerciseMediaPainter(
      descriptor: visualDescriptor,
      style: style,
    );

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.panel,
                borderRadius: borderRadius,
                border: Border.all(color: style.panelEdge),
              ),
              child: CustomPaint(
                size: Size(width ?? 180, height ?? 132),
                painter: painter,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One low-cost static painter. The artwork is intentionally pictographic:
/// simple posture linework, directional marks, grounded forms, and a small
/// equipment glyph—never a photo, anatomical rendering, text, or logo.
class _FitFlowV2ExerciseMediaPainter extends CustomPainter {
  const _FitFlowV2ExerciseMediaPainter({
    required this.descriptor,
    required this.style,
  });

  static const double _designWidth = 180;
  static const double _designHeight = 132;

  final FitFlowV2ExerciseVisualDescriptor descriptor;
  final FitFlowV2ArtStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scale = math.min(
      size.width / _designWidth,
      size.height / _designHeight,
    );
    if (!scale.isFinite || scale <= 0) return;

    canvas.save();
    canvas.translate(
      (size.width - _designWidth * scale) / 2,
      (size.height - _designHeight * scale) / 2,
    );
    canvas.scale(scale);

    _drawFoundation(canvas);
    _drawMovementCue(canvas, descriptor.movementPattern);
    _drawPosture(canvas, descriptor.bodyPosition);
    _drawEquipmentHint(canvas, descriptor.equipmentHints.firstOrNull);

    canvas.restore();
  }

  void _drawFoundation(Canvas canvas) {
    canvas.drawCircle(
      const Offset(136, 34),
      24,
      artFill(style.wash.withValues(alpha: .34)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(136, 34), radius: 31),
      -1.42,
      1.72,
      false,
      artStroke(style.panelEdge.withValues(alpha: .72), 1.15),
    );
    canvas.drawLine(
      const Offset(24, 106),
      const Offset(156, 106),
      artStroke(style.wash.withValues(alpha: .62), 1.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 109, 34, 4),
        const Radius.circular(2),
      ),
      artFill(style.wash.withValues(alpha: .42)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(105, 109, 40, 4),
        const Radius.circular(2),
      ),
      artFill(style.wash.withValues(alpha: .42)),
    );
    canvas.drawCircle(
      const Offset(37, 83),
      2.4,
      artFill(style.accent.withValues(alpha: .72)),
    );
  }

  void _drawMovementCue(Canvas canvas, MovementPattern? pattern) {
    final cue = artStroke(style.accent.withValues(alpha: .9), 2.7);
    final quietCue = artStroke(style.wash.withValues(alpha: .92), 2.2);

    if (pattern == MovementPattern.push) {
      _drawArrow(canvas, const Offset(112, 48), const Offset(143, 48), cue);
      return;
    }
    if (pattern == MovementPattern.pull) {
      _drawArrow(canvas, const Offset(144, 48), const Offset(113, 48), cue);
      return;
    }
    if (pattern == MovementPattern.squat) {
      _drawArrow(canvas, const Offset(132, 39), const Offset(132, 67), cue);
      return;
    }
    if (pattern == MovementPattern.lunge) {
      _drawArrow(canvas, const Offset(115, 59), const Offset(143, 73), cue);
      return;
    }
    if (pattern == MovementPattern.hinge) {
      _drawArcWithDirection(
        canvas,
        const Rect.fromLTWH(112, 36, 35, 33),
        -1.15,
        1.55,
        1,
        cue,
      );
      return;
    }
    if (pattern == MovementPattern.core) {
      _drawArcWithDirection(
        canvas,
        Rect.fromCircle(center: const Offset(132, 73), radius: 15),
        -.6,
        3.9,
        1,
        cue,
      );
      return;
    }
    if (pattern == MovementPattern.glute) {
      _drawArrow(canvas, const Offset(133, 81), const Offset(133, 57), cue);
      return;
    }
    if (pattern == MovementPattern.cardio) {
      _drawArrow(canvas, const Offset(115, 75), const Offset(139, 48), cue);
      canvas.drawLine(const Offset(119, 88), const Offset(128, 78), quietCue);
      canvas.drawLine(const Offset(135, 90), const Offset(143, 81), quietCue);
      return;
    }
    if (pattern == MovementPattern.mobility) {
      _drawArcWithDirection(
        canvas,
        const Rect.fromLTWH(113, 39, 34, 35),
        -.85,
        2.2,
        1,
        cue,
      );
      return;
    }
    if (pattern == MovementPattern.balance) {
      canvas.drawLine(const Offset(137, 42), const Offset(137, 74), quietCue);
      canvas.drawCircle(const Offset(137, 40), 3.3, artFill(style.accent));
      return;
    }
    if (pattern == MovementPattern.warmup) {
      canvas.drawArc(
        const Rect.fromLTWH(118, 43, 29, 27),
        -.2,
        2.4,
        false,
        quietCue,
      );
      canvas.drawArc(
        const Rect.fromLTWH(123, 48, 19, 17),
        -.2,
        2.4,
        false,
        cue,
      );
      return;
    }
    if (pattern == MovementPattern.cooldown) {
      canvas.drawArc(
        const Rect.fromLTWH(113, 48, 36, 20),
        .05,
        2.95,
        false,
        quietCue,
      );
      canvas.drawCircle(
        const Offset(132, 58),
        2.4,
        artFill(style.accent.withValues(alpha: .72)),
      );
      return;
    }

    // Null or a future canonical enum value uses a generic neutral cue.
    _drawNeutralMovementCue(canvas, cue, quietCue);
  }

  void _drawNeutralMovementCue(Canvas canvas, Paint cue, Paint quietCue) {
    canvas.drawCircle(
      const Offset(132, 57),
      10,
      artStroke(quietCue.color.withValues(alpha: .8), 2),
    );
    canvas.drawCircle(const Offset(132, 57), 2.8, artFill(cue.color));
  }

  void _drawPosture(Canvas canvas, ExercisePosition? position) {
    final pose = _poseFor(position);
    if (pose == null) {
      // A missing position is deliberately abstract rather than guessing a
      // body pose that canonical metadata did not provide.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(72, 39, 13, 43),
          const Radius.circular(6.5),
        ),
        artFill(style.wash),
      );
      canvas.drawCircle(const Offset(78.5, 33), 6, artFill(style.panelEdge));
      canvas.drawLine(
        const Offset(78.5, 84),
        const Offset(78.5, 97),
        artStroke(style.ink, 3.8),
      );
      return;
    }

    if (pose.hangingBar) {
      canvas.drawLine(
        const Offset(56, 18),
        const Offset(101, 18),
        artStroke(style.panelEdge, 3.2),
      );
      canvas.drawLine(
        const Offset(60, 18),
        const Offset(60, 24),
        artStroke(style.panelEdge, 1.5),
      );
      canvas.drawLine(
        const Offset(97, 18),
        const Offset(97, 24),
        artStroke(style.panelEdge, 1.5),
      );
    }

    final limb = artStroke(style.wash, 4.2);
    final body = artStroke(style.ink, 5.1);

    canvas.drawLine(pose.head, pose.shoulders, body);
    canvas.drawLine(pose.shoulders, pose.hips, body);
    canvas.drawLine(
      Offset(pose.shoulders.dx - 3, pose.shoulders.dy),
      pose.leftElbow,
      limb,
    );
    canvas.drawLine(pose.leftElbow, pose.leftHand, limb);
    canvas.drawLine(
      Offset(pose.shoulders.dx + 3, pose.shoulders.dy),
      pose.rightElbow,
      limb,
    );
    canvas.drawLine(pose.rightElbow, pose.rightHand, limb);
    canvas.drawLine(
      Offset(pose.hips.dx - 2.8, pose.hips.dy),
      pose.leftKnee,
      body,
    );
    canvas.drawLine(pose.leftKnee, pose.leftFoot, body);
    canvas.drawLine(
      Offset(pose.hips.dx + 2.8, pose.hips.dy),
      pose.rightKnee,
      body,
    );
    canvas.drawLine(pose.rightKnee, pose.rightFoot, body);
    canvas.drawCircle(pose.head, 5.8, artFill(style.panel));
    canvas.drawCircle(pose.head, 5.8, artStroke(style.ink, 2.1));
  }

  _ExercisePose? _poseFor(ExercisePosition? position) {
    if (position == ExercisePosition.standing) {
      return const _ExercisePose(
        head: Offset(78, 25),
        shoulders: Offset(78, 41),
        hips: Offset(80, 68),
        leftElbow: Offset(63, 50),
        leftHand: Offset(59, 62),
        rightElbow: Offset(94, 48),
        rightHand: Offset(101, 39),
        leftKnee: Offset(71, 84),
        leftFoot: Offset(67, 100),
        rightKnee: Offset(89, 84),
        rightFoot: Offset(94, 100),
      );
    }
    if (position == ExercisePosition.floor) {
      return const _ExercisePose(
        head: Offset(46, 69),
        shoulders: Offset(59, 70),
        hips: Offset(88, 71),
        leftElbow: Offset(52, 59),
        leftHand: Offset(49, 49),
        rightElbow: Offset(62, 84),
        rightHand: Offset(72, 91),
        leftKnee: Offset(106, 63),
        leftFoot: Offset(121, 60),
        rightKnee: Offset(108, 79),
        rightFoot: Offset(123, 84),
      );
    }
    if (position == ExercisePosition.seated) {
      return const _ExercisePose(
        head: Offset(78, 25),
        shoulders: Offset(78, 41),
        hips: Offset(79, 67),
        leftElbow: Offset(64, 52),
        leftHand: Offset(60, 65),
        rightElbow: Offset(93, 51),
        rightHand: Offset(101, 58),
        leftKnee: Offset(96, 70),
        leftFoot: Offset(104, 92),
        rightKnee: Offset(72, 81),
        rightFoot: Offset(64, 94),
      );
    }
    if (position == ExercisePosition.kneeling) {
      return const _ExercisePose(
        head: Offset(78, 25),
        shoulders: Offset(78, 41),
        hips: Offset(81, 66),
        leftElbow: Offset(65, 54),
        leftHand: Offset(61, 68),
        rightElbow: Offset(94, 48),
        rightHand: Offset(103, 44),
        leftKnee: Offset(77, 85),
        leftFoot: Offset(66, 92),
        rightKnee: Offset(98, 79),
        rightFoot: Offset(88, 91),
      );
    }
    if (position == ExercisePosition.hanging) {
      return const _ExercisePose(
        head: Offset(78, 43),
        shoulders: Offset(78, 57),
        hips: Offset(78, 81),
        leftElbow: Offset(67, 33),
        leftHand: Offset(66, 21),
        rightElbow: Offset(90, 33),
        rightHand: Offset(92, 21),
        leftKnee: Offset(68, 94),
        leftFoot: Offset(64, 104),
        rightKnee: Offset(89, 94),
        rightFoot: Offset(96, 101),
        hangingBar: true,
      );
    }

    // Null or a future canonical enum value does not imply a guessed pose.
    return null;
  }

  void _drawEquipmentHint(Canvas canvas, WorkoutEquipment? equipment) {
    if (equipment == null) return;

    final plate = RRect.fromRectAndRadius(
      const Rect.fromLTWH(132, 83, 34, 24),
      const Radius.circular(8),
    );
    canvas.drawRRect(plate, artFill(style.panel));
    canvas.drawRRect(plate, artStroke(style.panelEdge, 1.1));

    final line = artStroke(style.ink, 2.1);
    final support = artStroke(style.wash, 2.5);
    switch (equipment) {
      case WorkoutEquipment.none:
        return;
      case WorkoutEquipment.exerciseMat:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(138, 93, 21, 5),
            const Radius.circular(2.5),
          ),
          artFill(style.wash),
        );
        canvas.drawCircle(const Offset(158, 95.5), 2.6, artFill(style.accent));
      case WorkoutEquipment.chair:
        canvas.drawLine(const Offset(143, 87), const Offset(143, 97), line);
        canvas.drawLine(const Offset(143, 94), const Offset(158, 94), line);
        canvas.drawLine(const Offset(143, 98), const Offset(143, 103), support);
        canvas.drawLine(const Offset(157, 96), const Offset(157, 103), support);
      case WorkoutEquipment.resistanceBands:
        canvas.drawArc(
          const Rect.fromLTWH(139, 88, 20, 14),
          .1,
          2.9,
          false,
          artStroke(style.wash, 2.7),
        );
        canvas.drawLine(const Offset(140, 95), const Offset(159, 95), line);
      case WorkoutEquipment.dumbbells:
        canvas.drawLine(const Offset(139, 95), const Offset(159, 95), line);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(137, 89, 4, 12),
            const Radius.circular(1.5),
          ),
          artFill(style.accent),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(157, 89, 4, 12),
            const Radius.circular(1.5),
          ),
          artFill(style.accent),
        );
      case WorkoutEquipment.kettlebell:
        canvas.drawArc(
          const Rect.fromLTWH(144, 87, 11, 10),
          math.pi,
          math.pi,
          false,
          line,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(141, 93, 18, 10),
            const Radius.circular(5),
          ),
          artFill(style.wash),
        );
      case WorkoutEquipment.pullUpBar:
        canvas.drawLine(const Offset(139, 90), const Offset(159, 90), line);
        canvas.drawLine(const Offset(142, 90), const Offset(142, 101), support);
        canvas.drawLine(const Offset(156, 90), const Offset(156, 101), support);
      case WorkoutEquipment.bench:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(138, 90, 21, 4),
            const Radius.circular(2),
          ),
          artFill(style.accent),
        );
        canvas.drawLine(const Offset(141, 94), const Offset(141, 102), line);
        canvas.drawLine(const Offset(156, 94), const Offset(156, 102), line);
      case WorkoutEquipment.towel:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(140, 89, 18, 12),
            const Radius.circular(2.5),
          ),
          artFill(style.wash),
        );
        canvas.drawLine(
          const Offset(149, 90),
          const Offset(149, 100),
          artStroke(style.panel, 1.4),
        );
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const wingLength = 6.0;
    const wingAngle = .62;
    canvas.drawLine(
      end,
      Offset(
        end.dx - wingLength * math.cos(angle - wingAngle),
        end.dy - wingLength * math.sin(angle - wingAngle),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - wingLength * math.cos(angle + wingAngle),
        end.dy - wingLength * math.sin(angle + wingAngle),
      ),
      paint,
    );
  }

  void _drawArcWithDirection(
    Canvas canvas,
    Rect bounds,
    double startAngle,
    double sweepAngle,
    double direction,
    Paint paint,
  ) {
    canvas.drawArc(bounds, startAngle, sweepAngle, false, paint);
    final center = bounds.center;
    final rx = bounds.width / 2;
    final ry = bounds.height / 2;
    final endAngle = startAngle + sweepAngle;
    final end = Offset(
      center.dx + rx * math.cos(endAngle),
      center.dy + ry * math.sin(endAngle),
    );
    final tangent = endAngle + (direction * math.pi / 2);
    const wingLength = 5.2;
    const wingAngle = .65;
    canvas.drawLine(
      end,
      Offset(
        end.dx - wingLength * math.cos(tangent - wingAngle),
        end.dy - wingLength * math.sin(tangent - wingAngle),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - wingLength * math.cos(tangent + wingAngle),
        end.dy - wingLength * math.sin(tangent + wingAngle),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FitFlowV2ExerciseMediaPainter oldDelegate) {
    return descriptor != oldDelegate.descriptor ||
        style.panel != oldDelegate.style.panel ||
        style.panelEdge != oldDelegate.style.panelEdge ||
        style.ink != oldDelegate.style.ink ||
        style.wash != oldDelegate.style.wash ||
        style.accent != oldDelegate.style.accent;
  }
}

class _ExercisePose {
  const _ExercisePose({
    required this.head,
    required this.shoulders,
    required this.hips,
    required this.leftElbow,
    required this.leftHand,
    required this.rightElbow,
    required this.rightHand,
    required this.leftKnee,
    required this.leftFoot,
    required this.rightKnee,
    required this.rightFoot,
    this.hangingBar = false,
  });

  final Offset head;
  final Offset shoulders;
  final Offset hips;
  final Offset leftElbow;
  final Offset leftHand;
  final Offset rightElbow;
  final Offset rightHand;
  final Offset leftKnee;
  final Offset leftFoot;
  final Offset rightKnee;
  final Offset rightFoot;
  final bool hangingBar;
}
