import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Two-exercise illustrated pilot. This clock animates artwork only: it never
/// counts repetitions, changes prescriptions, or calls the workout controller.
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

  static bool supports(String id) =>
      id == 'march_in_place' || id == 'squat_bodyweight';

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

/// An original shaded vector character with fixed limb lengths and planted
/// support feet. Orthographic side view keeps the squat's contacts readable.
class PilotCharacterPainter extends CustomPainter {
  PilotCharacterPainter({required this.motion, required this.squat})
      : super(repaint: motion);
  final Animation<double> motion;
  final bool squat;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 300);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 300),
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, 0),
              const Offset(400, 300),
              [const Color(0xFFE8ECE6), const Color(0xFFBCC8C2)]));
    canvas.drawOval(const Rect.fromLTWH(135, 263, 140, 12),
        Paint()..color = const Color(0xFF60756B).withValues(alpha: .20));
    final angle = motion.value * math.pi * 2;
    final depth = squat ? (1 - math.cos(angle)) / 2 : 0.0;
    final hip = Offset(194 - depth * 34, 165 + depth * 34);
    final shoulder = Offset(196 - depth * 7, 94 + depth * 42);

    void limb(Offset a, Offset b, double width, Color shade, Color highlight) {
      canvas.drawLine(
          a,
          b,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = width
            ..color = shade);
      canvas.drawLine(
          a.translate(-width * .13, 0),
          b.translate(-width * .13, 0),
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = width * .65
            ..shader = ui.Gradient.linear(a, b, [highlight, shade]));
    }

    Offset kneeFor(Offset h, Offset ankle) {
      final delta = ankle - h;
      final distance = delta.distance;
      final midpoint = (h + ankle) / 2;
      final bend = math.sqrt(math.max(0, 50 * 50 - distance * distance / 4));
      return midpoint + Offset(delta.dy, -delta.dx) / distance * bend;
    }

    void shoe(Offset ankle, bool rear) {
      final path = Path()
        ..moveTo(ankle.dx - 8, ankle.dy - 5)
        ..lineTo(ankle.dx + 7, ankle.dy - 5)
        ..quadraticBezierTo(
            ankle.dx + 13, ankle.dy + 1, ankle.dx + 23, ankle.dy + 2)
        ..quadraticBezierTo(
            ankle.dx + 28, ankle.dy + 7, ankle.dx + 21, ankle.dy + 8)
        ..lineTo(ankle.dx - 9, ankle.dy + 8)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = rear ? const Color(0xFF3B4847) : const Color(0xFF202526));
      canvas.drawLine(
          ankle.translate(-7, 7),
          ankle.translate(22, 7),
          Paint()
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFF3F4EE));
      canvas.drawLine(
          ankle.translate(1, -1),
          ankle.translate(10, 1),
          Paint()
            ..strokeWidth = 3
            ..color = const Color(0xFFD4E779));
    }

    void leg(bool rear) {
      final h = hip.translate(rear ? -6 : 6, 0);
      late final Offset knee, ankle;
      if (squat) {
        ankle = Offset(rear ? 186 : 204, 262);
        knee = kneeFor(h, ankle);
      } else {
        final lift = math.max(0.0, math.sin(angle + (rear ? math.pi : 0)));
        final rotation = lift * 1.05;
        knee = h + Offset(math.sin(rotation) * 49, math.cos(rotation) * 49);
        ankle = knee + const Offset(-2, 48);
      }
      final skin = rear ? const Color(0xFFAA785E) : const Color(0xFFC99170);
      limb(knee, ankle, 13, skin, const Color(0xFFE9B48C));
      limb(h, knee, 23, const Color(0xFF303D40),
          rear ? const Color(0xFF435052) : const Color(0xFF59696B));
      shoe(ankle, rear);
    }

    void arm(bool rear) {
      final s = shoulder.translate(rear ? -7 : 7, 3);
      final swing = squat ? depth : -math.sin(angle + (rear ? math.pi : 0));
      final elbow = squat
          ? Offset.lerp(
              s + const Offset(-2, 35), s + const Offset(37, 5), depth)!
          : s + Offset(17 * swing, 33 - 4 * swing.abs());
      final hand = squat
          ? Offset.lerp(
              elbow + const Offset(4, 27), elbow + const Offset(30, -5), depth)!
          : elbow + Offset(21 + 10 * swing, -15 - 8 * swing);
      final skin = rear ? const Color(0xFFAA785E) : const Color(0xFFC99170);
      limb(s, elbow, 14, skin, const Color(0xFFE9B48C));
      limb(elbow, hand, 11, skin, const Color(0xFFE9B48C));
      canvas.drawOval(Rect.fromCenter(center: hand, width: 12, height: 15),
          Paint()..color = skin);
    }

    arm(true);
    leg(true);
    leg(false);
    // Torso follows the hip/shoulder skeleton without scaling limb lengths.
    final torso = Path()
      ..moveTo(shoulder.dx - 16, shoulder.dy - 5)
      ..quadraticBezierTo(
          shoulder.dx + 3, shoulder.dy - 12, shoulder.dx + 18, shoulder.dy)
      ..lineTo(hip.dx + 17, hip.dy - 1)
      ..quadraticBezierTo(hip.dx, hip.dy + 9, hip.dx - 19, hip.dy - 1)
      ..close();
    canvas.drawPath(
        torso,
        Paint()
          ..shader = ui.Gradient.linear(
              shoulder.translate(-16, 0),
              hip.translate(20, 0),
              [const Color(0xFFE3EFAB), const Color(0xFFACBF58)]));
    limb(shoulder.translate(1, -9), shoulder.translate(2, -20), 14,
        const Color(0xFFBE8767), const Color(0xFFE9B48C));
    final head = shoulder + const Offset(2, -35);
    canvas.drawOval(
        Rect.fromCenter(center: head, width: 30, height: 39),
        Paint()
          ..shader = ui.Gradient.linear(
              head.translate(-15, 0),
              head.translate(15, 0),
              [const Color(0xFFC18A68), const Color(0xFFEAC09B)]));
    // Small profile nose, hairline, ear and eye preserve a human silhouette.
    canvas.drawPath(
        Path()
          ..moveTo(head.dx + 12, head.dy - 2)
          ..lineTo(head.dx + 18, head.dy + 6)
          ..lineTo(head.dx + 11, head.dy + 8)
          ..close(),
        Paint()..color = const Color(0xFFEAC09B));
    canvas.drawPath(
        Path()
          ..moveTo(head.dx - 15, head.dy + 2)
          ..cubicTo(head.dx - 21, head.dy - 25, head.dx + 18, head.dy - 29,
              head.dx + 15, head.dy - 9)
          ..lineTo(head.dx + 1, head.dy - 13)
          ..lineTo(head.dx - 8, head.dy + 3)
          ..close(),
        Paint()..color = const Color(0xFF303032));
    canvas.drawOval(
        Rect.fromCenter(center: head.translate(-5, 2), width: 7, height: 11),
        Paint()..color = const Color(0xFFD6A07D));
    canvas.drawCircle(
        head.translate(10, -2), 1.3, Paint()..color = const Color(0xFF303032));
    arm(false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PilotCharacterPainter oldDelegate) =>
      oldDelegate.squat != squat || oldDelegate.motion != motion;
}
