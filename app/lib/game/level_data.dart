import 'package:flutter/painting.dart';

class GravityBody {
  final double x, y, mass, radius;
  final Color color;
  const GravityBody({
    required this.x,
    required this.y,
    required this.mass,
    required this.radius,
    required this.color,
  });
}

class Zone {
  final double x, y, radius;
  const Zone({required this.x, required this.y, required this.radius});
}

class LevelData {
  final int id;
  final String name;
  final int shots;
  final double g;
  final List<GravityBody> gravityBodies;
  final Zone launchZone;
  final Zone gateway;
  const LevelData({
    required this.id,
    required this.name,
    required this.shots,
    required this.g,
    required this.gravityBodies,
    required this.launchZone,
    required this.gateway,
  });
}

// ignore: non_constant_identifier_names
Color _c(int rgb) => Color(0xFF000000 | rgb);

const List<LevelData> kLevels = [
  // Level 1 — Tutorial: one planet
  LevelData(
    id: 1, name: 'First Steps', shots: 5, g: 80,
    gravityBodies: [
      GravityBody(x: 560, y: 480, mass: 3000, radius: 44, color: Color(0xFF4488FF)),
    ],
    launchZone: Zone(x: 160, y: 420, radius: 44),
    gateway: Zone(x: 1100, y: 260, radius: 36),
  ),

  // Level 2 — Two planets as stepping stones
  LevelData(
    id: 2, name: 'Double Trouble', shots: 4, g: 90,
    gravityBodies: [
      GravityBody(x: 420, y: 440, mass: 2600, radius: 38, color: Color(0xFFFF5533)),
      GravityBody(x: 800, y: 310, mass: 2800, radius: 42, color: Color(0xFFFFCC44)),
    ],
    launchZone: Zone(x: 150, y: 560, radius: 42),
    gateway: Zone(x: 1130, y: 160, radius: 34),
  ),

  // Level 3 — Thread the needle
  LevelData(
    id: 3, name: 'Needle Eye', shots: 4, g: 100,
    gravityBodies: [
      GravityBody(x: 640, y: 230, mass: 3200, radius: 50, color: Color(0xFF5588FF)),
      GravityBody(x: 640, y: 530, mass: 2200, radius: 35, color: Color(0xFFFF3311)),
    ],
    launchZone: Zone(x: 120, y: 370, radius: 40),
    gateway: Zone(x: 1160, y: 370, radius: 34),
  ),

  // Level 4 — Diagonal chain of three
  LevelData(
    id: 4, name: 'Chain Reaction', shots: 3, g: 100,
    gravityBodies: [
      GravityBody(x: 380, y: 510, mass: 2000, radius: 32, color: Color(0xFFFFEE99)),
      GravityBody(x: 640, y: 360, mass: 2800, radius: 40, color: Color(0xFFFF9944)),
      GravityBody(x: 900, y: 220, mass: 2200, radius: 34, color: Color(0xFFFFF4CC)),
    ],
    launchZone: Zone(x: 140, y: 610, radius: 40),
    gateway: Zone(x: 1140, y: 120, radius: 32),
  ),

  // Level 5 — Massive center + 2 moons, slingshot
  LevelData(
    id: 5, name: 'The Slingshot', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 8000, radius: 68, color: Color(0xFFFFCC44)),
      GravityBody(x: 640, y: 170, mass: 800, radius: 18, color: Color(0xFF99AAFF)),
      GravityBody(x: 640, y: 550, mass: 800, radius: 18, color: Color(0xFFAABBFF)),
    ],
    launchZone: Zone(x: 160, y: 360, radius: 40),
    gateway: Zone(x: 1120, y: 360, radius: 32),
  ),

  // Level 6 — Zigzag slalom
  LevelData(
    id: 6, name: 'Slalom', shots: 3, g: 110,
    gravityBodies: [
      GravityBody(x: 330, y: 210, mass: 2600, radius: 38, color: Color(0xFFFF4422)),
      GravityBody(x: 530, y: 510, mass: 2400, radius: 36, color: Color(0xFF4488FF)),
      GravityBody(x: 730, y: 210, mass: 2600, radius: 38, color: Color(0xFFFF4422)),
      GravityBody(x: 930, y: 510, mass: 2400, radius: 36, color: Color(0xFF4488FF)),
    ],
    launchZone: Zone(x: 130, y: 360, radius: 38),
    gateway: Zone(x: 1150, y: 360, radius: 30),
  ),

  // Level 7 — Must loop around
  LevelData(
    id: 7, name: 'Full Circle', shots: 3, g: 130,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 9000, radius: 74, color: Color(0xFFFF8833)),
      GravityBody(x: 900, y: 560, mass: 1200, radius: 22, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 150, y: 580, radius: 38),
    gateway: Zone(x: 200, y: 130, radius: 30),
  ),

  // Level 8 — Binary star
  LevelData(
    id: 8, name: 'Binary Star', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 380, y: 360, mass: 5000, radius: 58, color: Color(0xFFFF3311)),
      GravityBody(x: 900, y: 360, mass: 5000, radius: 58, color: Color(0xFF3366FF)),
      GravityBody(x: 640, y: 360, mass: 1500, radius: 24, color: Color(0xFFEEF2FF)),
    ],
    launchZone: Zone(x: 640, y: 650, radius: 38),
    gateway: Zone(x: 640, y: 70, radius: 30),
  ),

  // Level 9 — Defensive ring
  LevelData(
    id: 9, name: 'The Gauntlet', shots: 3, g: 140,
    gravityBodies: [
      GravityBody(x: 450, y: 200, mass: 3000, radius: 40, color: Color(0xFFFF4422)),
      GravityBody(x: 640, y: 145, mass: 2500, radius: 35, color: Color(0xFF99AAFF)),
      GravityBody(x: 830, y: 200, mass: 3000, radius: 40, color: Color(0xFFFF4422)),
      GravityBody(x: 450, y: 520, mass: 3000, radius: 40, color: Color(0xFF99AAFF)),
      GravityBody(x: 830, y: 520, mass: 3000, radius: 40, color: Color(0xFFFF4422)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 36),
    gateway: Zone(x: 1160, y: 360, radius: 28),
  ),

  // Level 10 — Maximum complexity: 10 bodies
  LevelData(
    id: 10, name: 'The Labyrinth', shots: 3, g: 150,
    gravityBodies: [
      GravityBody(x: 285, y: 505, mass: 2000, radius: 32, color: Color(0xFFFF3311)),
      GravityBody(x: 460, y: 355, mass: 3500, radius: 46, color: Color(0xFF3366FF)),
      GravityBody(x: 355, y: 190, mass: 1800, radius: 28, color: Color(0xFFFFEE99)),
      GravityBody(x: 640, y: 575, mass: 2200, radius: 34, color: Color(0xFFFF9944)),
      GravityBody(x: 640, y: 285, mass: 4000, radius: 52, color: Color(0xFFFFCC44)),
      GravityBody(x: 820, y: 475, mass: 2500, radius: 36, color: Color(0xFF5588FF)),
      GravityBody(x: 960, y: 590, mass: 1600, radius: 26, color: Color(0xFFFF5533)),
      GravityBody(x: 855, y: 210, mass: 3000, radius: 40, color: Color(0xFFDDEEFF)),
      GravityBody(x: 1050, y: 385, mass: 2000, radius: 30, color: Color(0xFFFF4422)),
      GravityBody(x: 1090, y: 205, mass: 1400, radius: 22, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 105, y: 640, radius: 36),
    gateway: Zone(x: 1180, y: 75, radius: 26),
  ),
];
