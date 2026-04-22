import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'dart:math';

import 'car_physics.dart';

class WallData {
  final double x, y, width, height;
  const WallData(this.x, this.y, this.width, this.height);
}

class ConeData {
  final double x, y;
  const ConeData(this.x, this.y);
}

class ParkSpotData {
  final double x, y, width, height, angle;
  const ParkSpotData(this.x, this.y, this.width, this.height, this.angle);
}

class LevelData {
  final int id;
  final String name;
  final String subtitle;
  final Color themeColor;
  final double timeLimit;     // seconds
  final Vector2 worldSize;
  final Vector2 startPosition;
  final double startAngle;
  final ParkSpotData parkSpot;
  final List<WallData> walls;
  final List<ConeData> cones;
  final CarSpec carSpec;
  final String environment; // 'lot', 'garage', 'alley', 'urban', 'night'
  final int difficulty;     // 1-5

  const LevelData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.themeColor,
    required this.timeLimit,
    required this.worldSize,
    required this.startPosition,
    required this.startAngle,
    required this.parkSpot,
    required this.walls,
    required this.cones,
    required this.carSpec,
    required this.environment,
    required this.difficulty,
  });
}

class LevelRegistry {
  static List<LevelData> get all => [
    // ---- LEVEL 1: INTRO ----
    LevelData(
      id: 0, name: 'INTRO RUN', subtitle: 'Learn the basics', difficulty: 1,
      themeColor: const Color(0xFF00FFC8), timeLimit: 70, environment: 'lot',
      worldSize: Vector2(800, 600), startPosition: Vector2(200, 320), startAngle: 0,
      parkSpot: const ParkSpotData(560, 190, 50, 74, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(80, 80, 640, 20), WallData(80, 500, 640, 20),
        WallData(80, 80, 20, 440), WallData(700, 80, 20, 440),
        WallData(430, 80, 20, 170), WallData(560, 80, 20, 170),
      ],
      cones: const [],
    ),

    // ---- LEVEL 2: PARKING LOT A ----
    LevelData(
      id: 1, name: 'PARKING LOT A', subtitle: 'Navigate the bays', difficulty: 1,
      themeColor: const Color(0xFF00FFC8), timeLimit: 55, environment: 'lot',
      worldSize: Vector2(800, 600), startPosition: Vector2(160, 400), startAngle: -pi / 2,
      parkSpot: const ParkSpotData(620, 160, 48, 72, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(80, 80, 640, 18), WallData(80, 500, 640, 18),   // top/bottom border
        WallData(80, 80, 18, 440), WallData(700, 80, 18, 440),   // left/right border
        WallData(360, 80, 18, 220),                               // divider 1 (stops before parking row)
        WallData(460, 120, 18, 180), WallData(560, 120, 18, 180), // bay dividers (clear of parkSpot)
      ],
      cones: const [ConeData(260, 200), ConeData(260, 300), ConeData(260, 400)],
    ),

    // ---- LEVEL 3: UNDERGROUND GARAGE ----
    LevelData(
      id: 2, name: 'UNDERGROUND', subtitle: 'Tight garage columns', difficulty: 2,
      themeColor: const Color(0xFF5566FF), timeLimit: 50, environment: 'garage',
      worldSize: Vector2(820, 580), startPosition: Vector2(130, 300), startAngle: 0,
      parkSpot: const ParkSpotData(660, 300, 48, 72, pi / 2),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
        WallData(200, 60, 18, 270), WallData(200, 380, 18, 140),
        WallData(390, 180, 18, 340), WallData(570, 60, 18, 180), WallData(570, 360, 18, 160),
      ],
      cones: const [ConeData(295, 130), ConeData(295, 460), ConeData(480, 270)],
    ),

    // ---- LEVEL 4: TIGHT ALLEYWAY ----
    LevelData(
      id: 3, name: 'TIGHT ALLEY', subtitle: 'No room for error', difficulty: 3,
      themeColor: const Color(0xFFFF8C00), timeLimit: 45, environment: 'alley',
      worldSize: Vector2(820, 580), startPosition: Vector2(120, 300), startAngle: 0,
      parkSpot: const ParkSpotData(700, 300, 46, 70, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
        WallData(180, 60, 18, 180), WallData(180, 310, 18, 210),
        WallData(340, 60, 18, 380), WallData(340, 470, 18, 60),
        WallData(500, 90, 18, 100), WallData(500, 290, 18, 230),
        WallData(630, 60, 18, 120),
      ],
      cones: const [
        ConeData(260, 250), ConeData(420, 180), ConeData(420, 380), ConeData(565, 210),
      ],
    ),

    // ---- LEVEL 5: URBAN CHAOS ----
    LevelData(
      id: 4, name: 'URBAN CHAOS', subtitle: 'Downtown maze', difficulty: 3,
      themeColor: const Color(0xFFFF8C00), timeLimit: 42, environment: 'urban',
      worldSize: Vector2(820, 580), startPosition: Vector2(110, 300), startAngle: 0,
      parkSpot: const ParkSpotData(715, 150, 44, 68, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
        WallData(160, 60, 18, 200), WallData(160, 330, 18, 230),
        WallData(290, 60, 18, 360), WallData(290, 450, 18, 80),
        WallData(430, 170, 18, 360), WallData(560, 60, 18, 110),
        WallData(560, 240, 18, 290), WallData(640, 60, 18, 90),
      ],
      cones: const [
        ConeData(220, 280), ConeData(360, 120), ConeData(360, 440),
        ConeData(500, 130), ConeData(600, 340),
      ],
    ),

    // ---- LEVEL 6: OBSTACLE COURSE ----
    LevelData(
      id: 5, name: 'OBSTACLE RUN', subtitle: 'Cone slalom', difficulty: 4,
      themeColor: const Color(0xFFFF3C3C), timeLimit: 40, environment: 'lot',
      worldSize: Vector2(820, 580), startPosition: Vector2(110, 300), startAngle: 0,
      parkSpot: const ParkSpotData(710, 300, 44, 68, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
      ],
      cones: const [
        ConeData(200, 180), ConeData(200, 420),
        ConeData(300, 300), ConeData(350, 150), ConeData(350, 450),
        ConeData(450, 220), ConeData(450, 380),
        ConeData(530, 140), ConeData(530, 460),
        ConeData(610, 260), ConeData(610, 340),
      ],
    ),

    // ---- LEVEL 7: SUV CHALLENGE ----
    LevelData(
      id: 6, name: 'SUV CHALLENGE', subtitle: 'Bigger vehicle, tight space', difficulty: 4,
      themeColor: const Color(0xFFFF3C3C), timeLimit: 50, environment: 'garage',
      worldSize: Vector2(820, 580), startPosition: Vector2(120, 300), startAngle: 0,
      parkSpot: const ParkSpotData(680, 280, 52, 76, 0),
      carSpec: CarSpecs.suv,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
        WallData(200, 60, 18, 260), WallData(200, 380, 18, 140),
        WallData(370, 160, 18, 360), WallData(530, 60, 18, 200), WallData(530, 380, 18, 140),
      ],
      cones: const [
        ConeData(290, 130), ConeData(290, 460), ConeData(460, 270),
        ConeData(620, 200), ConeData(620, 380),
      ],
    ),

    // ---- LEVEL 8: NIGHT PARKING ----
    LevelData(
      id: 7, name: 'NIGHT SHIFT', subtitle: 'Limited visibility', difficulty: 4,
      themeColor: const Color(0xFF8844FF), timeLimit: 45, environment: 'night',
      worldSize: Vector2(820, 580), startPosition: Vector2(120, 300), startAngle: 0,
      parkSpot: const ParkSpotData(690, 160, 46, 70, 0),
      carSpec: CarSpecs.sedan,
      walls: const [
        WallData(60, 60, 700, 18), WallData(60, 500, 700, 18),
        WallData(60, 60, 18, 460), WallData(740, 60, 18, 460),
        WallData(170, 60, 18, 220), WallData(170, 350, 18, 170),
        WallData(310, 60, 18, 350), WallData(310, 450, 18, 70),
        WallData(460, 180, 18, 340), WallData(590, 60, 18, 120), WallData(590, 270, 18, 250),
      ],
      cones: const [
        ConeData(240, 300), ConeData(390, 110), ConeData(390, 440),
        ConeData(530, 140), ConeData(650, 360),
      ],
    ),

    // ---- LEVEL 9: SPORTS CAR SPRINT ----
    LevelData(
      id: 8, name: 'TURBO SPRINT', subtitle: 'Fast car, precise parking', difficulty: 5,
      themeColor: const Color(0xFFFF3C3C), timeLimit: 38, environment: 'urban',
      worldSize: Vector2(820, 580), startPosition: Vector2(110, 300), startAngle: 0,
      parkSpot: const ParkSpotData(710, 400, 42, 66, -pi / 6),
      carSpec: CarSpecs.sports,
      walls: const [
        WallData(50, 50, 720, 18), WallData(50, 510, 720, 18),
        WallData(50, 50, 18, 480), WallData(750, 50, 18, 480),
        WallData(160, 50, 18, 250), WallData(160, 380, 18, 180),
        WallData(280, 50, 18, 170), WallData(280, 280, 18, 280),
        WallData(400, 140, 18, 390), WallData(530, 50, 18, 290), WallData(530, 410, 18, 120),
        WallData(650, 80, 18, 210), WallData(650, 360, 18, 80),
      ],
      cones: const [
        ConeData(220, 330), ConeData(340, 100), ConeData(340, 460),
        ConeData(465, 240), ConeData(595, 150), ConeData(595, 440),
      ],
    ),

    // ---- LEVEL 10: EXPERT MASTER ----
    LevelData(
      id: 9, name: 'MASTER CLASS', subtitle: 'The ultimate challenge', difficulty: 5,
      themeColor: const Color(0xFFFF3C3C), timeLimit: 35, environment: 'night',
      worldSize: Vector2(840, 600), startPosition: Vector2(100, 300), startAngle: 0,
      parkSpot: const ParkSpotData(730, 430, 42, 64, -pi / 4),
      carSpec: CarSpecs.sports,
      walls: const [
        WallData(50, 50, 740, 18), WallData(50, 530, 740, 18),
        WallData(50, 50, 18, 500), WallData(770, 50, 18, 500),
        WallData(150, 50, 18, 250), WallData(150, 380, 18, 200),
        WallData(260, 50, 18, 160), WallData(260, 270, 18, 290),
        WallData(370, 130, 18, 420), WallData(490, 50, 18, 280), WallData(490, 400, 18, 150),
        WallData(600, 70, 18, 220), WallData(600, 350, 18, 100),
        WallData(690, 100, 18, 150), WallData(690, 350, 18, 80),
      ],
      cones: const [
        ConeData(205, 320), ConeData(315, 100), ConeData(315, 450),
        ConeData(430, 220), ConeData(545, 140), ConeData(545, 440),
        ConeData(645, 280),
      ],
    ),
  ];

  static LevelData getLevel(int id) {
    return all.firstWhere((l) => l.id == id, orElse: () => all.first);
  }

  static int get totalLevels => all.length;
}
