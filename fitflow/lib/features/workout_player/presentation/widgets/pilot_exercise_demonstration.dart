import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Remaining marching illustration pilot. Squats use the shared Lottie renderer.
/// This clock animates artwork only: it never counts repetitions, changes
/// prescriptions, or calls the workout controller.
class PilotExerciseDemonstration extends StatefulWidget {
  const PilotExerciseDemonstration(
      {super.key,
      required this.exerciseId,
      required this.running,
      required this.width,
      required this.height});
  final String exerciseId;
  final bool running;
  final double width, height;

  static bool supports(String id) => id == 'march_in_place';

  @override
  State<PilotExerciseDemonstration> createState() => _DemonstrationState();
}

class _DemonstrationState extends State<PilotExerciseDemonstration>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4800));
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PilotExerciseDemonstration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) _motion.value = 0;
    _sync();
  }

  void _sync() {
    final enabled = widget.running &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (enabled && !_motion.isAnimating) {
      // Repeat resumes at the frozen pose, not at the start of the movement.
      // ignore: discarded_futures
      _motion.repeat();
    } else if (!enabled) {
      _motion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: RepaintBoundary(
          child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: CustomPaint(
                  key: const ValueKey('pilot_character_canvas'),
                  painter: PilotCharacterPainter(
                      motion: _motion,
                      squat: widget.exerciseId == 'squat_bodyweight')))));
}

/// Front-facing pose data for the illustrated pilot. The support foot stays on
/// the ground; a lifted knee and its opposite arm move together. Squat feet stay
/// planted and the knees bend outward, rather than overlapping in profile.
class PilotCharacterPose {
  PilotCharacterPose(double phase, {required this.squat})
      : angle = phase * math.pi * 2;
  final bool squat;
  final double angle;
  static final squatLegLength = math.sqrt(96 * 96 + 22 * 22) / 2;
  double get depth => squat ? (1 - math.cos(angle)) / 2 : 0;
  Offset get pelvis => Offset(200, 164 + 33 * depth);
  Offset get shoulders => Offset(200, 94 + 33 * depth);
  double lift(double side) => squat ? 0 : math.max(0, side * math.sin(angle));
  Offset hip(double side) => pelvis.translate(side * 13, 0);
  Offset ankle(double side) => squat
      ? Offset(200 + side * 35, 260)
      : Offset(200 + side * (23 + 5 * lift(side)), 260 - 43 * lift(side));
  Offset knee(double side) {
    if (!squat) {
      return Offset(200 + side * (18 + 8 * lift(side)), 212 - 43 * lift(side));
    }
    // Two equal-length segments, with the knee on the outward solution.
    final h = hip(side);
    final foot = ankle(side);
    final delta = foot - h;
    final bend = math.sqrt(math.max(
        0, squatLegLength * squatLegLength - delta.distanceSquared / 4));
    return (h + foot) / 2 +
        Offset(delta.dy, -delta.dx) / delta.distance * bend * side;
  }

  Offset shoulder(double side) => shoulders.translate(side * 28, 1);
  Offset elbow(double side) {
    final forward = squat ? depth : lift(-side);
    return shoulders.translate(side * (43 - 6 * forward), 29 - 7 * forward);
  }

  Offset hand(double side) {
    final forward = squat ? depth : lift(-side);
    return shoulders.translate(
        side * (40 - (squat ? 34 : 21) * forward), 62 - 48 * forward);
  }
}

/// A front-facing athletic illustration, not a realistic 3D avatar. Tapered
/// silhouettes, a wider shoulder line and separated limbs replace the old
/// tubular profile. This painter has no access to workout state or timers.
class PilotCharacterPainter extends CustomPainter {
  PilotCharacterPainter({required this.motion, required this.squat})
      : super(repaint: motion);
  final Animation<double> motion;
  final bool squat;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Uniform scaling also keeps proportions intact in nonstandard hosts.
    final scale = math.min(size.width / 400, size.height / 300);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFE7EBE6));
    canvas.translate(
        (size.width - 400 * scale) / 2, (size.height - 300 * scale) / 2);
    canvas.scale(scale);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 300),
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, 0),
              const Offset(400, 300),
              [const Color(0xFFF0F2ED), const Color(0xFFCCD5CF)]));
    canvas.drawOval(const Rect.fromLTWH(128, 264, 144, 10),
        Paint()..color = const Color(0xFF53675E).withValues(alpha: .18));
    final pose = PilotCharacterPose(motion.value, squat: squat);
    const skin = Color(0xFFC08A68);
    const skinLight = Color(0xFFE5B18C);
    const pants = Color(0xFF344349);

    void segment(Offset a, Offset b, double startWidth, double endWidth,
        Color dark, Color light) {
      final direction = b - a;
      final normal = Offset(-direction.dy, direction.dx) / direction.distance;
      final a1 = a + normal * startWidth / 2;
      final a2 = a - normal * startWidth / 2;
      final b1 = b + normal * endWidth / 2;
      final b2 = b - normal * endWidth / 2;
      final path = Path()
        ..moveTo(a1.dx, a1.dy)
        ..quadraticBezierTo((a1.dx + b1.dx) / 2 + normal.dx * 2,
            (a1.dy + b1.dy) / 2 + normal.dy * 2, b1.dx, b1.dy)
        ..quadraticBezierTo(
            b.dx + direction.dx * .08, b.dy + direction.dy * .08, b2.dx, b2.dy)
        ..lineTo(a2.dx, a2.dy)
        ..quadraticBezierTo(
            a.dx - direction.dx * .10, a.dy - direction.dy * .10, a1.dx, a1.dy)
        ..close();
      canvas.drawPath(
          path, Paint()..shader = ui.Gradient.linear(a1, a2, [light, dark]));
    }

    void foot(double side) {
      final a = pose.ankle(side);
      final toe = a.translate(side * 3, 9);
      final shoe = Path()
        ..moveTo(a.dx - 7, a.dy - 5)
        ..quadraticBezierTo(a.dx, a.dy - 8, a.dx + 7, a.dy - 5)
        ..lineTo(toe.dx + 11, toe.dy - 1)
        ..quadraticBezierTo(toe.dx + 12, toe.dy + 5, toe.dx, toe.dy + 5)
        ..quadraticBezierTo(toe.dx - 12, toe.dy + 5, toe.dx - 11, toe.dy - 1)
        ..close();
      canvas.drawPath(shoe, Paint()..color = const Color(0xFFF8F9F4));
      canvas.drawLine(
          toe.translate(-9, 4),
          toe.translate(9, 4),
          Paint()
            ..color = pants
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
            a.translate(-4, -1 + i * 2),
            a.translate(4, -1 + i * 2),
            Paint()
              ..color = const Color(0xFF778681)
              ..strokeWidth = 1);
      }
    }

    // Continuous silhouette around each joint avoids disconnected cylinders
    // and sharp caps when a knee or elbow changes direction.
    void chain(Offset a, Offset joint, Offset b, double wa, double wj,
        double wb, Color dark, Color light) {
      Offset normal(Offset delta) =>
          Offset(-delta.dy, delta.dx) / delta.distance;
      final na = normal(joint - a);
      final nb = normal(b - joint);
      final average = na + nb;
      final nj = average / average.distance;
      final a1 = a + na * wa / 2;
      final a2 = a - na * wa / 2;
      final j1 = joint + nj * wj / 2;
      final j2 = joint - nj * wj / 2;
      final b1 = b + nb * wb / 2;
      final b2 = b - nb * wb / 2;
      final path = Path()
        ..moveTo(a1.dx, a1.dy)
        ..quadraticBezierTo(j1.dx, j1.dy, j1.dx, j1.dy)
        ..lineTo(b1.dx, b1.dy)
        ..quadraticBezierTo(b.dx, b.dy + 3, b2.dx, b2.dy)
        ..lineTo(j2.dx, j2.dy)
        ..lineTo(a2.dx, a2.dy)
        ..quadraticBezierTo(a.dx, a.dy - 5, a1.dx, a1.dy)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(
                a1.translate(-8, 0), a2.translate(8, 0), [light, dark]));
    }

    void leg(double side) {
      chain(pose.hip(side), pose.knee(side), pose.ankle(side), 24, 18, 9, pants,
          const Color(0xFF53666B));
      foot(side);
    }

    void arm(double side) {
      final s = pose.shoulder(side);
      final e = pose.elbow(side);
      final h = pose.hand(side);
      chain(s, e, h, 16, 12, 7, skin, skinLight);
      canvas.drawOval(
          Rect.fromCenter(center: h.translate(0, 3), width: 10, height: 14),
          Paint()..color = skinLight);
      canvas.drawLine(
          h.translate(side * 3, 0),
          h.translate(side * 4, 5),
          Paint()
            ..color = skin
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    }

    leg(-1);
    leg(1);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: pose.pelvis.translate(0, -1), width: 40, height: 23),
            const Radius.circular(8)),
        Paint()
          ..shader = ui.Gradient.linear(pose.pelvis.translate(-20, 0),
              pose.pelvis.translate(20, 0), [const Color(0xFF53666B), pants]));
    arm(-1);
    arm(1);
    final s = pose.shoulders;
    final h = pose.pelvis;
    // Fitted short-sleeve shirt with a continuous shoulder/waist silhouette.
    final torso = Path()
      ..moveTo(s.dx - 10, s.dy - 9)
      ..lineTo(s.dx - 29, s.dy - 3)
      ..quadraticBezierTo(s.dx - 34, s.dy + 3, s.dx - 36, s.dy + 14)
      ..lineTo(s.dx - 24, s.dy + 19)
      ..lineTo(h.dx - 19, h.dy - 5)
      ..quadraticBezierTo(h.dx, h.dy + 3, h.dx + 19, h.dy - 5)
      ..lineTo(s.dx + 24, s.dy + 19)
      ..lineTo(s.dx + 36, s.dy + 14)
      ..quadraticBezierTo(s.dx + 34, s.dy + 3, s.dx + 29, s.dy - 3)
      ..lineTo(s.dx + 10, s.dy - 9)
      ..close();
    canvas.drawPath(
        torso,
        Paint()
          ..shader = ui.Gradient.linear(
              s.translate(-30, 0),
              s.translate(35, 40),
              [const Color(0xFFDFEC9B), const Color(0xFFA8BD55)]));
    canvas.drawPath(
        Path()
          ..moveTo(s.dx - 18, s.dy + 23)
          ..quadraticBezierTo(s.dx - 10, s.dy + 38, h.dx - 15, h.dy - 11),
        Paint()
          ..color = const Color(0xFF91A746).withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Neck and face are centered: the viewer sees both eyes and shoulders.
    segment(s.translate(0, -20), s.translate(0, -7), 13, 16, skin, skinLight);
    final head = s.translate(0, -32);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: head.translate(side * 15, 0), width: 6, height: 10),
          Paint()..color = skin);
    }
    final face = Path()
      ..moveTo(head.dx - 15, head.dy - 10)
      ..quadraticBezierTo(head.dx, head.dy - 26, head.dx + 15, head.dy - 10)
      ..lineTo(head.dx + 13, head.dy + 9)
      ..quadraticBezierTo(head.dx + 8, head.dy + 19, head.dx, head.dy + 19)
      ..quadraticBezierTo(head.dx - 8, head.dy + 19, head.dx - 13, head.dy + 9)
      ..close();
    canvas.drawPath(
        face,
        Paint()
          ..shader = ui.Gradient.linear(head.translate(-16, 0),
              head.translate(16, 0), [skin, skinLight]));
    canvas.drawPath(
        Path()
          ..moveTo(head.dx - 15, head.dy - 2)
          ..cubicTo(head.dx - 22, head.dy - 28, head.dx + 20, head.dy - 29,
              head.dx + 16, head.dy - 3)
          ..lineTo(head.dx + 11, head.dy - 11)
          ..quadraticBezierTo(
              head.dx - 1, head.dy - 7, head.dx - 10, head.dy - 12)
          ..close(),
        Paint()..color = const Color(0xFF303735));
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(head.translate(side * 6, -1), 1.1,
          Paint()..color = const Color(0xFF333B38));
    }
    canvas.drawLine(
        head.translate(0, 1),
        head.translate(-1, 6),
        Paint()
          ..color = skin
          ..strokeWidth = 1.2);
    canvas.drawLine(
        head.translate(-4, 11),
        head.translate(4, 11),
        Paint()
          ..color = const Color(0xFF8A5B47)
          ..strokeWidth = 1.2);
    // Forward forearms cross in front of the shirt, never behind the torso.
    for (final side in [-1.0, 1.0]) {
      if ((squat && pose.depth > .2) || (!squat && pose.lift(-side) > .2)) {
        final e = pose.elbow(side);
        final hand = pose.hand(side);
        segment(e, hand, 12, 7, skin, skinLight);
        canvas.drawOval(
            Rect.fromCenter(
                center: hand.translate(0, 3), width: 10, height: 14),
            Paint()..color = skinLight);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PilotCharacterPainter oldDelegate) =>
      oldDelegate.squat != squat || oldDelegate.motion != motion;
}
