import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _Particle {
  Vector2 pos;
  Vector2 vel;
  double life;       // 0..1, decreasing
  double maxLife;
  double radius;
  Color color;
  double rotation;
  double rotSpeed;

  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
    this.rotation = 0,
    this.rotSpeed = 0,
  }) : maxLife = life;
}

class ParticleSystem extends Component {
  final List<_Particle> _particles = [];
  final _rng = Random();

  // ---- Emitters ----

  void emitExhaust({required Vector2 pos, required double angle, double intensity = 1.0}) {
    final count = (intensity * 2).round();
    for (int i = 0; i < count; i++) {
      final spread = (_rng.nextDouble() - 0.5) * 1.2;
      _particles.add(_Particle(
        pos: pos.clone() + Vector2(sin(angle + spread) * 25, -cos(angle + spread) * 25),
        vel: Vector2(
          sin(angle) * (_rng.nextDouble() * 20 + 10) + (_rng.nextDouble() - 0.5) * 15,
          -cos(angle) * (_rng.nextDouble() * 20 + 10) + (_rng.nextDouble() - 0.5) * 15,
        ),
        life: 0.6 + _rng.nextDouble() * 0.4,
        radius: 2.5 + _rng.nextDouble() * 2,
        color: Colors.grey.withOpacity(0.4),
        rotSpeed: (_rng.nextDouble() - 0.5) * 3,
      ));
    }
  }

  void emitSkid({required Vector2 pos}) {
    if (_rng.nextDouble() > 0.3) return;
    _particles.add(_Particle(
      pos: pos.clone() + Vector2((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 10),
      vel: Vector2((_rng.nextDouble() - 0.5) * 8, (_rng.nextDouble() - 0.5) * 8),
      life: 0.8,
      radius: 3,
      color: const Color(0xFFC8A840).withOpacity(0.5),
    ));
  }

  void emitImpact({required Vector2 pos}) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = _rng.nextDouble() * 60 + 20;
      _particles.add(_Particle(
        pos: pos.clone(),
        vel: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.5 + _rng.nextDouble() * 0.3,
        radius: 2 + _rng.nextDouble() * 3,
        color: i < 4
            ? const Color(0xFFFF3333).withOpacity(0.8)
            : const Color(0xFFFF8800).withOpacity(0.6),
        rotSpeed: (_rng.nextDouble() - 0.5) * 6,
      ));
    }
  }

  void emitParkSuccess({required Vector2 pos}) {
    for (int i = 0; i < 24; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = _rng.nextDouble() * 80 + 30;
      _particles.add(_Particle(
        pos: pos.clone(),
        vel: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 1.0 + _rng.nextDouble() * 0.5,
        radius: 3 + _rng.nextDouble() * 4,
        color: i % 3 == 0
            ? const Color(0xFF00FFC8).withOpacity(0.9)
            : i % 3 == 1
                ? const Color(0xFFFF8C00).withOpacity(0.8)
                : Colors.white.withOpacity(0.7),
        rotSpeed: (_rng.nextDouble() - 0.5) * 8,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.pos += p.vel * dt;
      p.vel *= 0.92; // drag
      p.life -= dt * 1.2;
      p.radius *= 0.99;
      p.rotation += p.rotSpeed * dt;
    }
    _particles.removeWhere((p) => p.life <= 0 || p.radius < 0.3);
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(p.color.opacity * alpha);
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      canvas.rotate(p.rotation);
      canvas.drawCircle(Offset.zero, p.radius, paint);
      canvas.restore();
    }
  }
}
