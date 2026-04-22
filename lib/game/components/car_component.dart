import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../car_physics.dart';

class CarComponent extends PositionComponent with CollisionCallbacks {
  CarPhysics physics;
  final Function(double impactSpeed) onCarCollision;

  double _damageFlash = 0;
  List<Vector2> _trailPoints = [];

  CarComponent({required this.physics, required this.onCarCollision})
      : super(
          size: Vector2(physics.spec.width, physics.spec.length),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(physics.spec.width * 0.85, physics.spec.length * 0.85),
      anchor: Anchor.center,
    ));
    updatePhysics(physics);
  }

  void updatePhysics(CarPhysics newPhysics) {
    physics = newPhysics;
    position = Vector2(newPhysics.position.x, newPhysics.position.y);
    angle = newPhysics.angle;

    if (physics.isMoving) {
      _trailPoints.add(Vector2(newPhysics.position.x, newPhysics.position.y));
      if (_trailPoints.length > 30) _trailPoints.removeAt(0);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    onCarCollision(physics.speed.abs());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_damageFlash > 0) _damageFlash -= dt * 3;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawCar(canvas);
  }

  void _drawCar(Canvas canvas) {
    final w = physics.spec.width;
    final h = physics.spec.length;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(2, 2), width: w, height: h),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Main body - bright red
    final bodyColor = _getBodyColor();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(8),
      ),
      Paint()..color = bodyColor,
    );

    // Front arrow indicator — makes front of car obvious
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFE600)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(0, -h / 2 - 8)          // tip pointing forward
      ..lineTo(-6, -h / 2 + 2)
      ..lineTo(6, -h / 2 + 2)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Windshield - light blue
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -8), width: w - 10, height: 16),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF87CEEB).withOpacity(0.7),
    );

    // Roof stripe - yellow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 0), width: w - 6, height: h - 16),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFFFE600).withOpacity(0.3),
    );

    // Headlights - bright yellow with glow
    final hlGlow = Paint()
      ..color = const Color(0xFFFFFF00).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(-w / 2 + 6, -h / 2 + 4), 7, hlGlow);
    canvas.drawCircle(Offset(w / 2 - 6, -h / 2 + 4), 7, hlGlow);
    canvas.drawCircle(Offset(-w / 2 + 6, -h / 2 + 4), 4, Paint()..color = const Color(0xFFFFFF88));
    canvas.drawCircle(Offset(w / 2 - 6, -h / 2 + 4), 4, Paint()..color = const Color(0xFFFFFF88));

    // Taillights - always visible red, BRIGHT when braking
    final brakeOn = physics.brake > 0.1;
    final tlColor = brakeOn ? const Color(0xFFFF0000) : const Color(0xFF880000);
    final tlGlowColor = brakeOn
        ? const Color(0xFFFF0000).withOpacity(0.7)
        : const Color(0xFF440000).withOpacity(0.3);
    final tlGlowRadius = brakeOn ? 10.0 : 4.0;
    // Glow
    canvas.drawCircle(
      Offset(-w / 2 + 6, h / 2 - 4),
      tlGlowRadius,
      Paint()
        ..color = tlGlowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(w / 2 - 6, h / 2 - 4),
      tlGlowRadius,
      Paint()
        ..color = tlGlowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Core
    canvas.drawCircle(Offset(-w / 2 + 6, h / 2 - 4), 5, Paint()..color = tlColor);
    canvas.drawCircle(Offset(w / 2 - 6, h / 2 - 4), 5, Paint()..color = tlColor);
    // White center when braking
    if (brakeOn) {
      canvas.drawCircle(Offset(-w / 2 + 6, h / 2 - 4), 2, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w / 2 - 6, h / 2 - 4), 2, Paint()..color = Colors.white);
    }

    // Wheels - black with colorful rims
    _drawWheel(canvas, Offset(-w / 2 - 2, -h / 2 + 12));
    _drawWheel(canvas, Offset(w / 2 - 4, -h / 2 + 12));
    _drawWheel(canvas, Offset(-w / 2 - 2, h / 2 - 18));
    _drawWheel(canvas, Offset(w / 2 - 4, h / 2 - 18));

    // Outline - bright cyan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(8),
      ),
      Paint()
        ..color = _damageFlash > 0
            ? const Color(0xFFFF3333).withOpacity(_damageFlash)
            : const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Smiley face on hood
    if (physics.damage == CarDamageLevel.none) {
      _drawSmiley(canvas, Offset(0, -h / 3));
    }
  }

  void _drawWheel(Canvas canvas, Offset pos) {
    // Black tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx, pos.dy, 6, 12), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    // Colorful rim - hot pink
    canvas.drawCircle(
      Offset(pos.dx + 3, pos.dy + 6),
      2.5,
      Paint()..color = const Color(0xFFFF4FCB),
    );
  }

  void _drawSmiley(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(center + const Offset(-3, -2), 1.5, paint);
    canvas.drawCircle(center + const Offset(3, -2), 1.5, paint);

    // Smile
    final smilePath = Path()
      ..moveTo(center.dx - 4, center.dy + 1)
      ..quadraticBezierTo(center.dx, center.dy + 3, center.dx + 4, center.dy + 1);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  Color _getBodyColor() {
    switch (physics.damage) {
      case CarDamageLevel.none:
        return const Color(0xFFFF3333); // bright red
      case CarDamageLevel.light:
        return const Color(0xFFDD2222);
      case CarDamageLevel.moderate:
        return const Color(0xFFBB1111);
      case CarDamageLevel.severe:
        return const Color(0xFF880000);
    }
  }
}
