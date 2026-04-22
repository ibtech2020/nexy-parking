import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:equatable/equatable.dart';

enum GearState { park, reverse, neutral, drive }
enum CarDamageLevel { none, light, moderate, severe }

class CarPhysics extends Equatable {
  // Position & rotation
  final Vector2 position;
  final double angle;          // radians
  final Vector2 velocity;      // world-space velocity
  final double angularVelocity;

  // Driving state
  final double speed;          // km/h (signed: + forward, - reverse)
  final double steerAngle;     // radians, clamped ±maxSteer
  final double throttle;       // 0..1
  final double brake;          // 0..1
  final GearState gear;

  // Engine
  final double rpm;
  final double engineForce;

  // Damage
  final CarDamageLevel damage;
  final int collisionCount;

  // Car spec (constant per car type)
  final CarSpec spec;

  const CarPhysics({
    required this.position,
    required this.angle,
    required this.velocity,
    required this.angularVelocity,
    required this.speed,
    required this.steerAngle,
    required this.throttle,
    required this.brake,
    required this.gear,
    required this.rpm,
    required this.engineForce,
    required this.damage,
    required this.collisionCount,
    required this.spec,
  });

  factory CarPhysics.initial({required CarSpec spec, required Vector2 startPos, double startAngle = 0}) {
    return CarPhysics(
      position: startPos,
      angle: startAngle,
      velocity: Vector2.zero(),
      angularVelocity: 0,
      speed: 0,
      steerAngle: 0,
      throttle: 0,
      brake: 0,
      gear: GearState.drive,
      rpm: 800,
      engineForce: 0,
      damage: CarDamageLevel.none,
      collisionCount: 0,
      spec: spec,
    );
  }

  /// Core physics step — call every frame with delta time in seconds
  CarPhysics step(double dt, {
    required double throttleInput,   // 0..1
    required double brakeInput,      // 0..1
    required double steerInput,      // -1..1 (left=neg, right=pos)
    required GearState gear,
  }) {
    if (gear == GearState.park) {
      return _withPark();
    }

    final gearSign = gear == GearState.reverse ? -1.0 : (gear == GearState.drive ? 1.0 : 0.0);

    // ---- Engine Force ----
    final maxForce = spec.maxEnginePower * (1.0 - damage.index * 0.15);
    double force = throttleInput * maxForce * gearSign;

    // ---- Acceleration ----
    double newSpeed = speed + (force / spec.mass) * dt * 18.0; // reduced speed scale

    // ---- Braking: directly reduce speed to zero ----
    if (brakeInput > 0) {
      final brakeStrength = brakeInput * spec.maxBrakeForce / spec.mass * dt * 36.0;
      if (newSpeed.abs() <= brakeStrength) {
        newSpeed = 0;
      } else {
        newSpeed -= (newSpeed > 0 ? 1 : -1) * brakeStrength;
      }
    }

    // Speed limits
    final maxFwd = spec.maxSpeed * (1.0 - damage.index * 0.1);
    final maxRev = spec.maxReverseSpeed;
    newSpeed = newSpeed.clamp(-maxRev, maxFwd);

    // Rolling resistance + air drag
    final rollingRes = spec.rollingResistance * 0.1 * dt;
    final airDrag = 0.5 * spec.dragCoefficient * newSpeed.abs() * newSpeed.abs() * dt / spec.mass;
    if (throttleInput < 0.05 && brakeInput < 0.05 && newSpeed.abs() < 1.0) {
      newSpeed = 0;
    } else {
      newSpeed -= (newSpeed > 0 ? 1 : -1) * (rollingRes + airDrag * 0.01);
    }

    // ---- Steering ----
    final speedFactor = (newSpeed.abs() / spec.maxSpeed).clamp(0.0, 1.0);
    final steerSensitivity = spec.steerSpeed * (1.0 - speedFactor * 0.4);
    double newSteer = steerAngle + steerInput * steerSensitivity * dt;
    newSteer = newSteer.clamp(-spec.maxSteerAngle, spec.maxSteerAngle);
    // Auto-center steering
    if (steerInput.abs() < 0.1) {
      newSteer *= (1.0 - spec.steerReturnSpeed * dt);
    }

    // ---- Angular velocity from Ackermann-like steering ----
    double newAngularV = 0;
    final wheelBase = spec.length * 0.6;
    if (newSpeed.abs() > 0.5) {
      final turnRadius = wheelBase / (sin(newSteer.abs()) + 0.0001);
      final angularRate = (newSpeed / 3.6) / turnRadius * (newSteer < 0 ? -1 : 1);
      newAngularV = angularRate * (newSpeed > 0 ? 1 : -1);
    }

    // Drift factor — reduce lateral grip at high speed + high steer
    final driftFactor = 1.0 - (speedFactor * newSteer.abs() * spec.driftTendency).clamp(0.0, 0.6);
    newAngularV *= driftFactor;

    // ---- New angle ----
    final newAngle = angle + newAngularV * dt;

    // ---- New position ----
    final speedMS = newSpeed / 3.6 * 4.0; // reduced pixel scale
    final nx = position.x + sin(newAngle) * speedMS * dt;
    final ny = position.y - cos(newAngle) * speedMS * dt;

    // ---- RPM simulation ----
    final newRpm = (800 + newSpeed.abs() * 35 + throttleInput * 1200).clamp(750.0, spec.maxRpm);

    return copyWith(
      position: Vector2(nx, ny),
      angle: newAngle,
      velocity: Vector2(sin(newAngle) * speedMS, -cos(newAngle) * speedMS),
      angularVelocity: newAngularV,
      speed: newSpeed,
      steerAngle: newSteer,
      throttle: throttleInput,
      brake: brakeInput,
      gear: gear,
      rpm: newRpm,
      engineForce: force,
    );
  }

  CarPhysics _withPark() {
    return copyWith(
      speed: speed * 0.8,
      gear: GearState.park,
      throttle: 0,
      brake: 1,
    );
  }

  /// Apply collision impulse from impact velocity
  CarPhysics applyCollision(double impactSpeed) {
    CarDamageLevel newDamage = damage;
    int newCollisions = collisionCount + 1;
    if (impactSpeed > 30) newDamage = CarDamageLevel.severe;
    else if (impactSpeed > 15) newDamage = damage.index < 2 ? CarDamageLevel.values[damage.index + 1] : damage;
    else if (impactSpeed > 5) newDamage = damage.index < 1 ? CarDamageLevel.light : damage;

    return copyWith(
      speed: -speed * 0.25,
      velocity: Vector2(-velocity.x * 0.25, -velocity.y * 0.25),
      angularVelocity: angularVelocity * -0.3,
      damage: newDamage,
      collisionCount: newCollisions,
    );
  }

  bool get isMoving => speed.abs() > 0.5;
  bool get isSkidding => speed.abs() > 20 && steerAngle.abs() > 0.3;
  bool get isBraking => brake > 0.5 && speed.abs() > 5;

  CarPhysics copyWith({
    Vector2? position, double? angle, Vector2? velocity,
    double? angularVelocity, double? speed, double? steerAngle,
    double? throttle, double? brake, GearState? gear,
    double? rpm, double? engineForce, CarDamageLevel? damage,
    int? collisionCount, CarSpec? spec,
  }) {
    return CarPhysics(
      position: position ?? this.position,
      angle: angle ?? this.angle,
      velocity: velocity ?? this.velocity,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      speed: speed ?? this.speed,
      steerAngle: steerAngle ?? this.steerAngle,
      throttle: throttle ?? this.throttle,
      brake: brake ?? this.brake,
      gear: gear ?? this.gear,
      rpm: rpm ?? this.rpm,
      engineForce: engineForce ?? this.engineForce,
      damage: damage ?? this.damage,
      collisionCount: collisionCount ?? this.collisionCount,
      spec: spec ?? this.spec,
    );
  }

  @override
  List<Object?> get props => [position, angle, speed, gear, damage];
}

/// Car specification — defines the vehicle's handling characteristics
class CarSpec {
  final String id;
  final String name;
  final double mass;             // kg
  final double maxEnginePower;   // N
  final double maxBrakeForce;    // N
  final double maxSpeed;         // km/h
  final double maxReverseSpeed;  // km/h
  final double maxSteerAngle;    // radians
  final double steerSpeed;       // rad/s
  final double steerReturnSpeed; // return to center speed
  final double rollingResistance;
  final double dragCoefficient;
  final double driftTendency;    // 0=no drift, 1=high drift
  final double maxRpm;
  final double length;           // pixels/units
  final double width;
  final String description;
  final int unlockLevel;
  final int price;

  const CarSpec({
    required this.id,
    required this.name,
    required this.mass,
    required this.maxEnginePower,
    required this.maxBrakeForce,
    required this.maxSpeed,
    required this.maxReverseSpeed,
    required this.maxSteerAngle,
    required this.steerSpeed,
    required this.steerReturnSpeed,
    required this.rollingResistance,
    required this.dragCoefficient,
    required this.driftTendency,
    required this.maxRpm,
    required this.length,
    required this.width,
    required this.description,
    required this.unlockLevel,
    required this.price,
  });
}

/// Pre-built car specs
class CarSpecs {
  static const CarSpec sedan = CarSpec(
    id: 'sedan',
    name: 'CITY SEDAN',
    mass: 1200,
    maxEnginePower: 5500,
    maxBrakeForce: 7000,
    maxSpeed: 160,
    maxReverseSpeed: 40,
    maxSteerAngle: 0.6,
    steerSpeed: 3.5,
    steerReturnSpeed: 4.0,
    rollingResistance: 2.5,
    dragCoefficient: 0.32,
    driftTendency: 0.25,
    maxRpm: 6500,
    length: 52,
    width: 26,
    description: 'Balanced sedan. Easy to park, forgiving handling.',
    unlockLevel: 0,
    price: 0,
  );

  static const CarSpec suv = CarSpec(
    id: 'suv',
    name: 'URBAN SUV',
    mass: 1900,
    maxEnginePower: 7000,
    maxBrakeForce: 8500,
    maxSpeed: 140,
    maxReverseSpeed: 35,
    maxSteerAngle: 0.5,
    steerSpeed: 2.8,
    steerReturnSpeed: 3.5,
    rollingResistance: 3.5,
    dragCoefficient: 0.38,
    driftTendency: 0.15,
    maxRpm: 5800,
    length: 60,
    width: 30,
    description: 'Bigger body. Harder to fit tight spots. High torque.',
    unlockLevel: 3,
    price: 1500,
  );

  static const CarSpec sports = CarSpec(
    id: 'sports',
    name: 'TURBO GT',
    mass: 1050,
    maxEnginePower: 12000,
    maxBrakeForce: 10000,
    maxSpeed: 220,
    maxReverseSpeed: 50,
    maxSteerAngle: 0.7,
    steerSpeed: 4.5,
    steerReturnSpeed: 5.5,
    rollingResistance: 2.0,
    dragCoefficient: 0.28,
    driftTendency: 0.55,
    maxRpm: 8500,
    length: 48,
    width: 25,
    description: 'Fast and agile. High drift tendency. Expert control needed.',
    unlockLevel: 6,
    price: 4000,
  );

  static const CarSpec truck = CarSpec(
    id: 'truck',
    name: 'PICKUP XL',
    mass: 2400,
    maxEnginePower: 8000,
    maxBrakeForce: 9500,
    maxSpeed: 120,
    maxReverseSpeed: 30,
    maxSteerAngle: 0.45,
    steerSpeed: 2.2,
    steerReturnSpeed: 3.0,
    rollingResistance: 4.5,
    dragCoefficient: 0.45,
    driftTendency: 0.08,
    maxRpm: 5200,
    length: 68,
    width: 32,
    description: 'Massive vehicle. Challenge mode only. Low drift, very hard to park.',
    unlockLevel: 9,
    price: 6000,
  );

  static const CarSpec muscle = CarSpec(
    id: 'muscle',
    name: 'MUSCLE V8',
    mass: 1600,
    maxEnginePower: 10000,
    maxBrakeForce: 8000,
    maxSpeed: 200,
    maxReverseSpeed: 45,
    maxSteerAngle: 0.55,
    steerSpeed: 3.0,
    steerReturnSpeed: 3.8,
    rollingResistance: 3.0,
    dragCoefficient: 0.36,
    driftTendency: 0.45,
    maxRpm: 7500,
    length: 56,
    width: 28,
    description: 'Raw power. Wide body. Loves to drift.',
    unlockLevel: 2,
    price: 1200,
  );

  static const CarSpec mini = CarSpec(
    id: 'mini',
    name: 'MINI RACER',
    mass: 800,
    maxEnginePower: 4000,
    maxBrakeForce: 6000,
    maxSpeed: 130,
    maxReverseSpeed: 35,
    maxSteerAngle: 0.75,
    steerSpeed: 5.0,
    steerReturnSpeed: 6.0,
    rollingResistance: 1.8,
    dragCoefficient: 0.25,
    driftTendency: 0.1,
    maxRpm: 7000,
    length: 40,
    width: 22,
    description: 'Tiny but nimble. Perfect for tight spots.',
    unlockLevel: 1,
    price: 600,
  );

  static const CarSpec bus = CarSpec(
    id: 'bus',
    name: 'SCHOOL BUS',
    mass: 5000,
    maxEnginePower: 9000,
    maxBrakeForce: 12000,
    maxSpeed: 90,
    maxReverseSpeed: 20,
    maxSteerAngle: 0.35,
    steerSpeed: 1.8,
    steerReturnSpeed: 2.5,
    rollingResistance: 6.0,
    dragCoefficient: 0.55,
    driftTendency: 0.05,
    maxRpm: 4500,
    length: 80,
    width: 36,
    description: 'Huge and slow. Ultimate parking challenge!',
    unlockLevel: 5,
    price: 2500,
  );

  static const CarSpec police = CarSpec(
    id: 'police',
    name: 'POLICE CAR',
    mass: 1400,
    maxEnginePower: 8500,
    maxBrakeForce: 9000,
    maxSpeed: 180,
    maxReverseSpeed: 50,
    maxSteerAngle: 0.65,
    steerSpeed: 4.0,
    steerReturnSpeed: 4.5,
    rollingResistance: 2.2,
    dragCoefficient: 0.30,
    driftTendency: 0.2,
    maxRpm: 7000,
    length: 54,
    width: 27,
    description: 'Fast pursuit vehicle. Handles like a dream.',
    unlockLevel: 4,
    price: 2000,
  );

  static List<CarSpec> get all => [sedan, mini, muscle, suv, police, sports, bus, truck];
}
