import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import 'car_physics.dart';
import 'level_data.dart';
import 'components/car_component.dart';
import 'components/wall_component.dart';
import 'components/cone_component.dart';
import 'components/parking_zone_component.dart';
import 'components/skidmark_component.dart';
import 'components/particle_system.dart';
import 'components/environment_component.dart';
import 'components/minimap_component.dart';

enum CameraMode { follow, topDown, driver }
enum GameStatus { playing, paused, parked, timeOut, crashed }

class ParkMasterGame extends FlameGame with HasCollisionDetection {
  GameStatus status = GameStatus.playing;
  CameraMode cameraMode = CameraMode.follow;
  int levelId;
  late LevelData level;

  late CarPhysics carState;
  GearState selectedGear = GearState.drive;

  double throttleInput = 0;
  double brakeInput = 0;
  double steerInput = 0;

  double elapsedTime = 0;
  int hitCount = 0;
  double parkHoldTimer = 0;
  static const double parkHoldRequired = 1.2;

  late CarComponent carComponent;
  late EnvironmentComponent environment;
  late ParkingZoneComponent parkingZone;
  late MinimapComponent minimap;
  late ParticleSystem particles;

  Function(GameStatus)? onStatusChange;
  Function(CarPhysics)? onCarStateUpdate;
  Function(double elapsedTime, int hits)? onScoreUpdate;

  ParkMasterGame({required this.levelId});

  @override
  Color backgroundColor() => const Color(0xFF0A0A0F);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    level = LevelRegistry.getLevel(levelId);
    carState = CarPhysics.initial(
      spec: level.carSpec,
      startPos: Vector2(level.startPosition.x, level.startPosition.y),
      startAngle: level.startAngle,
    );

    camera.viewfinder.zoom = 1.0;

    environment = EnvironmentComponent(level: level);
    world.add(environment);

    parkingZone = ParkingZoneComponent(
      position: Vector2(level.parkSpot.x, level.parkSpot.y),
      size: Vector2(level.parkSpot.width, level.parkSpot.height),
      zoneAngle: level.parkSpot.angle,
    );
    world.add(parkingZone);

    for (final w in level.walls) {
      world.add(WallComponent(
        position: Vector2(w.x, w.y),
        size: Vector2(w.width, w.height),
      ));
    }

    for (final c in level.cones) {
      world.add(ConeComponent(
        position: Vector2(c.x, c.y),
        onHit: _onConeHit,
      ));
    }

    world.add(SkidmarkComponent());

    particles = ParticleSystem();
    world.add(particles);

    carComponent = CarComponent(
      physics: carState,
      onCarCollision: _onCarCollision,
    );
    world.add(carComponent);

    minimap = MinimapComponent(level: level);
    camera.viewport.add(minimap);

    _updateCamera();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (status != GameStatus.playing) return;

    elapsedTime += dt;

    if (elapsedTime >= level.timeLimit) {
      _changeStatus(GameStatus.timeOut);
      return;
    }

    carState = carState.step(
      dt,
      throttleInput: throttleInput,
      brakeInput: brakeInput,
      steerInput: steerInput,
      gear: selectedGear,
    );

    carComponent.updatePhysics(carState);

    // Clamp car position to world bounds
    final margin = 15.0;
    final wx = level.worldSize.x;
    final wy = level.worldSize.y;
    final pos = carState.position;
    if (pos.x < margin || pos.x > wx - margin ||
        pos.y < margin || pos.y > wy - margin) {
      carState = carState.copyWith(
        position: Vector2(
          pos.x.clamp(margin, wx - margin),
          pos.y.clamp(margin, wy - margin),
        ),
        speed: 0,
        velocity: Vector2.zero(),
      );
      carComponent.updatePhysics(carState);
    }

    if (throttleInput > 0.3 && carState.speed.abs() > 2) {
      particles.emitExhaust(
        pos: carState.position,
        angle: carState.angle,
        intensity: throttleInput,
      );
    }

    if (carState.isSkidding) {
      particles.emitSkid(pos: carState.position);
    }

    _checkParking(dt);
    _updateCamera();

    onCarStateUpdate?.call(carState);
    onScoreUpdate?.call(elapsedTime, hitCount);
  }

  void _checkParking(double dt) {
    final spot = level.parkSpot;
    final dx = carState.position.x - spot.x;
    final dy = carState.position.y - spot.y;
    final dist = sqrt(dx * dx + dy * dy);

    double angleDiff = (carState.angle - spot.angle).abs() % (2 * pi);
    if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;

    final inZone = dist < 24 && angleDiff < 0.4 && carState.speed.abs() < 2.0;
    parkingZone.setProximity(dist < 80);

    if (inZone) {
      parkHoldTimer += dt;
      parkingZone.setParking(true, parkHoldTimer / parkHoldRequired);
      if (parkHoldTimer >= parkHoldRequired) {
        _changeStatus(GameStatus.parked);
      }
    } else {
      parkHoldTimer = 0;
      parkingZone.setParking(false, 0);
    }
  }

  void _updateCamera() {
    switch (cameraMode) {
      case CameraMode.follow:
        camera.viewfinder.position =
            Vector2(carState.position.x, carState.position.y);
        camera.viewfinder.zoom = 1.1;
        camera.viewfinder.angle = 0;
        break;
      case CameraMode.topDown:
        camera.viewfinder.position =
            Vector2(level.worldSize.x / 2, level.worldSize.y / 2);
        final scaleX = size.x / level.worldSize.x;
        final scaleY = size.y / level.worldSize.y;
        camera.viewfinder.zoom = min(scaleX, scaleY) * 0.9;
        camera.viewfinder.angle = 0;
        break;
      case CameraMode.driver:
        camera.viewfinder.position = Vector2(
          carState.position.x + sin(carState.angle) * 10,
          carState.position.y - cos(carState.angle) * 10,
        );
        camera.viewfinder.angle = carState.angle;
        camera.viewfinder.zoom = 1.8;
        break;
    }
  }

  void _onCarCollision(double impactSpeed) {
    if (status != GameStatus.playing) return;
    carState = carState.copyWith(
      speed: 0,
      velocity: Vector2.zero(),
    );
    if (impactSpeed > 5) {
      hitCount++;
      particles.emitImpact(pos: carState.position);
      onStatusChange?.call(GameStatus.playing);
    }
  }

  void _onConeHit() => hitCount++;

  void _changeStatus(GameStatus newStatus) {
    status = newStatus;
    onStatusChange?.call(newStatus);
  }

  void setThrottle(double v) => throttleInput = v.clamp(0.0, 1.0);
  void setBrake(double v) => brakeInput = v.clamp(0.0, 1.0);
  void setSteer(double v) => steerInput = v.clamp(-1.0, 1.0);
  void setGear(GearState g) => selectedGear = g;
  void cycleCameraMode() =>
      cameraMode = CameraMode.values[(cameraMode.index + 1) % CameraMode.values.length];
  void pause() => status = GameStatus.paused;
  void resume() => status = GameStatus.playing;

  int calculateStars() {
    if (status != GameStatus.parked) return 0;
    int stars = 3;
    if (hitCount >= 2) stars--;
    if (hitCount >= 5) stars--;
    if (elapsedTime > level.timeLimit * 0.75) stars--;
    return stars.clamp(1, 3);
  }

  int calculateScore() {
    if (status != GameStatus.parked) return 0;
    final stars = calculateStars();
    final timeBonus = max(0, (level.timeLimit - elapsedTime) * 8).toInt();
    final hitPenalty = hitCount * 40;
    return max(0, (stars * 500) + timeBonus - hitPenalty);
  }
}
