import 'dart:math';
import 'package:flutter/material.dart';

class SteeringWheelWidget extends StatefulWidget {
  final Function(double steerValue) onSteer;
  const SteeringWheelWidget({super.key, required this.onSteer});

  @override
  State<SteeringWheelWidget> createState() => _SteeringWheelWidgetState();
}

class _SteeringWheelWidgetState extends State<SteeringWheelWidget> {
  double _steerValue = 0;
  double _wheelRotation = 0; // radians, max ±pi*0.75
  Offset? _lastPos;

  static const double _wheelSize = 140.0;
  static const double _maxRotation = pi * 0.75;

  void _onPanStart(DragStartDetails d) {
    _lastPos = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_lastPos == null) return;
    final center = Offset(_wheelSize / 2, _wheelSize / 2);
    final prev = _lastPos! - center;
    final curr = d.localPosition - center;

    // Compute angle delta between previous and current touch point
    final prevAngle = atan2(prev.dy, prev.dx);
    final currAngle = atan2(curr.dy, curr.dx);
    double delta = currAngle - prevAngle;

    // Wrap delta to [-pi, pi]
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    setState(() {
      _wheelRotation = (_wheelRotation + delta).clamp(-_maxRotation, _maxRotation);
      _steerValue = _wheelRotation / _maxRotation;
    });
    widget.onSteer(_steerValue);
    _lastPos = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) {
    _lastPos = null;
    // Auto-center
    setState(() {
      _wheelRotation = 0;
      _steerValue = 0;
    });
    widget.onSteer(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: SizedBox(
        width: _wheelSize,
        height: _wheelSize,
        child: Transform.rotate(
          angle: _wheelRotation,
          child: CustomPaint(
            size: Size(_wheelSize, _wheelSize),
            painter: _RealSteeringPainter(steerValue: _steerValue),
          ),
        ),
      ),
    );
  }
}

class _RealSteeringPainter extends CustomPainter {
  final double steerValue;
  const _RealSteeringPainter({required this.steerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = size.width / 2 - 4;
    final innerR = outerR * 0.38;

    // ---- Outer ring shadow ----
    canvas.drawCircle(
      center + const Offset(2, 2),
      outerR,
      Paint()..color = Colors.black.withOpacity(0.4),
    );

    // ---- Outer ring - dark leather ----
    canvas.drawCircle(
      center,
      outerR,
      Paint()..color = const Color(0xFF1A0A00),
    );

    // Leather texture segments
    final segPaint = Paint()
      ..color = const Color(0xFF2C1500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerR * 0.28;
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerR * 0.86),
        a + 0.1,
        pi / 6 - 0.2,
        false,
        segPaint,
      );
    }

    // Outer ring highlight
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ---- 3 Spokes ----
    final spokePaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = outerR * 0.18
      ..strokeCap = StrokeCap.round;

    final spokeHighlight = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = outerR * 0.06
      ..strokeCap = StrokeCap.round;

    final spokeAngles = [-pi / 2, pi / 2 + pi / 3, pi / 2 - pi / 3];
    for (final a in spokeAngles) {
      final outer = center + Offset(cos(a) * outerR * 0.72, sin(a) * outerR * 0.72);
      final inner = center + Offset(cos(a) * innerR, sin(a) * innerR);
      canvas.drawLine(inner, outer, spokePaint);
      canvas.drawLine(inner, outer, spokeHighlight);
    }

    // ---- Center hub ----
    canvas.drawCircle(center, innerR, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(center, innerR, Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Horn button - colorful
    canvas.drawCircle(center, innerR * 0.6, Paint()..color = const Color(0xFFFF6B35));
    canvas.drawCircle(center, innerR * 0.6, Paint()
      ..color = const Color(0xFFFF9966)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Horn icon (small circle)
    canvas.drawCircle(center, innerR * 0.2, Paint()..color = Colors.white.withOpacity(0.8));

    // ---- Grip markers on outer ring ----
    final markerPaint = Paint()
      ..color = const Color(0xFF8B4513).withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2;
      final p1 = center + Offset(cos(a) * (outerR - 2), sin(a) * (outerR - 2));
      final p2 = center + Offset(cos(a) * (outerR * 0.72), sin(a) * (outerR * 0.72));
      canvas.drawLine(p1, p2, markerPaint);
    }
  }

  @override
  bool shouldRepaint(_RealSteeringPainter old) => old.steerValue != steerValue;
}
