import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

// ============================================================
//  WALL
// ============================================================
class WallComponent extends PositionComponent with CollisionCallbacks {
  WallComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Bright colorful wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF2244AA),
    );
    // Orange top stripe
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 4),
      Paint()..color = const Color(0xFFFF6B35),
    );
    // Bright border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = const Color(0xFF4488FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

// ============================================================
//  CONE
// ============================================================
class ConeComponent extends PositionComponent with CollisionCallbacks {
  final VoidCallback onHit;
  bool _wasHit = false;

  ConeComponent({required Vector2 position, required this.onHit})
      : super(position: position, size: Vector2(22, 26), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 11, anchor: Anchor.center));
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (!_wasHit) {
      _wasHit = true;
      onHit();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_wasHit) {
      // Knocked down – flat on ground
      final flatPaint = Paint()..color = const Color(0xFF884400).withOpacity(0.5);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 6), width: 22, height: 10),
        flatPaint,
      );
      return;
    }

    // Standing cone
    final bodyPaint = Paint()..color = const Color(0xFFFF6600);
    final path = Path()
      ..moveTo(0, -13)
      ..lineTo(11, 9)
      ..lineTo(-11, 9)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // White stripe
    final stripePaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawRect(const Rect.fromLTWH(-8, 2, 16, 4), stripePaint);

    // Base
    final basePaint = Paint()..color = const Color(0xFFCC5500);
    canvas.drawRect(const Rect.fromLTWH(-10, 9, 20, 4), basePaint);
  }
}

// ============================================================
//  PARKING ZONE
// ============================================================
class ParkingZoneComponent extends PositionComponent {
  final double zoneAngle;
  bool _isNear = false;
  bool _isParking = false;
  double _parkProgress = 0;
  double _pulseTimer = 0;

  ParkingZoneComponent({
    required Vector2 position,
    required Vector2 size,
    required this.zoneAngle,
  }) : super(position: position, size: size, anchor: Anchor.center);

  void setProximity(bool near) => _isNear = near;
  void setParking(bool parking, double progress) {
    _isParking = parking;
    _parkProgress = progress;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * (_isParking ? 4 : 2);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(zoneAngle);

    final pulse = sin(_pulseTimer) * 0.15 + 0.85;
    final baseAlpha = _isNear ? 0.25 : 0.12;

    // Fill - bright yellow-green
    final fillPaint = Paint()
      ..color = const Color(0xFF7CFF50).withOpacity((_isNear ? 0.45 : 0.25) * pulse);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      fillPaint,
    );

    // Border - bright lime
    final borderPaint = Paint()
      ..color = const Color(0xFF7CFF50).withOpacity(0.8 + 0.2 * sin(_pulseTimer))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      borderPaint,
    );

    // Progress arc when parking
    if (_isParking && _parkProgress > 0) {
      final arcPaint = Paint()
        ..color = const Color(0xFF00FFC8).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset.zero, width: 50, height: 50),
        -pi / 2,
        _parkProgress * 2 * pi,
        false,
        arcPaint,
      );
    }

    // "P" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00FFC8).withOpacity(0.5 + 0.3 * sin(_pulseTimer)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}

// ============================================================
//  ENVIRONMENT
// ============================================================
class EnvironmentComponent extends Component {
  final dynamic level; // LevelData

  EnvironmentComponent({required this.level});

  @override
  void render(Canvas canvas) {
    final size = Vector2(level.worldSize.x as double, level.worldSize.y as double);

    // Bright asphalt background
    final bgPaint = Paint()..color = _getBgColor();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Colorful floor tiles
    final tileColors = [
      const Color(0xFF1A3A2A),
      const Color(0xFF1A2A3A),
    ];
    const tileSize = 40.0;
    for (double x = 0; x < size.x; x += tileSize) {
      for (double y = 0; y < size.y; y += tileSize) {
        final idx = ((x / tileSize).toInt() + (y / tileSize).toInt()) % 2;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          Paint()..color = tileColors[idx],
        );
      }
    }

    // Bright lane markings
    final lanePaint = Paint()
      ..color = const Color(0xFFFFE600).withOpacity(0.5)
      ..strokeWidth = 2.5;
    for (double y = 80; y < size.y - 80; y += 80) {
      for (double x = 80; x < size.x - 80; x += 40) {
        canvas.drawLine(Offset(x, y), Offset(x + 20, y), lanePaint);
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = const Color(0xFF00D4FF).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  Color _getBgColor() {
    switch (level.environment as String) {
      case 'garage': return const Color(0xFF1A1A2E);
      case 'alley':  return const Color(0xFF1A2A1A);
      case 'urban':  return const Color(0xFF1A1A2A);
      case 'night':  return const Color(0xFF0A0A18);
      default:       return const Color(0xFF1A2A1A);
    }
  }
}

// ============================================================
//  SKIDMARK
// ============================================================
class SkidmarkComponent extends Component {
  final List<_SkidMark> _marks = [];

  void addMark(Vector2 pos) {
    _marks.add(_SkidMark(pos: pos.clone(), alpha: 0.4));
    if (_marks.length > 300) _marks.removeAt(0);
  }

  @override
  void update(double dt) {
    for (final m in _marks) {
      m.alpha = (m.alpha - dt * 0.02).clamp(0, 0.4);
    }
    _marks.removeWhere((m) => m.alpha <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final m in _marks) {
      final p = Paint()..color = const Color(0xFFC8A840).withOpacity(m.alpha * 0.5);
      canvas.drawCircle(Offset(m.pos.x, m.pos.y), 3, p);
    }
  }
}

class _SkidMark {
  Vector2 pos;
  double alpha;
  _SkidMark({required this.pos, required this.alpha});
}

// ============================================================
//  MINIMAP
// ============================================================
class MinimapComponent extends PositionComponent {
  final dynamic level;

  MinimapComponent({required this.level})
      : super(
          position: Vector2(10, 60),
          size: Vector2(120, 120),
        );

  Vector2 _carPos = Vector2.zero();
  double _carAngle = 0;

  void updateCar(Vector2 pos, double angle) {
    _carPos = pos;
    _carAngle = angle;
  }

  @override
  void render(Canvas canvas) {
    final ww = level.worldSize.x as double;
    final wh = level.worldSize.y as double;
    final sx = size.x / ww;
    final sy = size.y / wh;

    // Background
    final bg = Paint()..color = const Color(0xCC05080F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & Size(size.x, size.y), const Radius.circular(8)),
      bg,
    );

    // Border
    final border = Paint()
      ..color = const Color(0xFF00FFC8).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & Size(size.x, size.y), const Radius.circular(8)),
      border,
    );

    // Clip
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & Size(size.x, size.y), const Radius.circular(8)),
    );

    // Walls
    final wallPaint = Paint()..color = const Color(0xFF1A2040);
    for (final w in level.walls) {
      canvas.drawRect(
        Rect.fromLTWH(w.x * sx, w.y * sy, w.width * sx, w.height * sy),
        wallPaint,
      );
    }

    // Park spot
    final spotPaint = Paint()..color = const Color(0xFF00FFC8).withOpacity(0.35);
    final sp = level.parkSpot;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(sp.x * sx, sp.y * sy),
        width: sp.width * sx,
        height: sp.height * sy,
      ),
      spotPaint,
    );

    // Cones
    final conePaint = Paint()..color = const Color(0xFFFF6600);
    for (final c in level.cones) {
      canvas.drawCircle(Offset(c.x * sx, c.y * sy), 2, conePaint);
    }

    // Car
    canvas.save();
    canvas.translate(_carPos.x * sx, _carPos.y * sy);
    canvas.rotate(_carAngle);
    final carPaint = Paint()..color = const Color(0xFF00FFC8);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 5, height: 9), carPaint);
    canvas.restore();

    canvas.restore();
  }
}
