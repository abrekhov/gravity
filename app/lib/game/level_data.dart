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

class BlackHole {
  final double x, y, mass, radius;
  const BlackHole({
    required this.x,
    required this.y,
    required this.mass,
    required this.radius,
  });
}

class Wall {
  final double x1, y1, x2, y2, thickness;
  const Wall({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.thickness = 6,
  });
}

class AsteroidDef {
  final double cx, cy;    // orbit center
  final double orbitR;    // orbit radius in pixels
  final double speed;     // rad/s (positive = CCW)
  final double phase0;    // initial angle in radians
  final double radius;    // collision radius
  const AsteroidDef({
    required this.cx,
    required this.cy,
    required this.orbitR,
    required this.speed,
    required this.phase0,
    this.radius = 6,
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
  final List<BlackHole> blackHoles;
  final List<Wall> walls;
  final List<AsteroidDef> asteroids;
  const LevelData({
    required this.id,
    required this.name,
    required this.shots,
    required this.g,
    required this.gravityBodies,
    required this.launchZone,
    required this.gateway,
    this.blackHoles = const [],
    this.walls = const [],
    this.asteroids = const [],
  });
}


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

  // Level 5 — Massive center + 2 moons, slingshot; asteroids orbit the star
  LevelData(
    id: 5, name: 'The Slingshot', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 8000, radius: 68, color: Color(0xFFFFCC44)),
      GravityBody(x: 640, y: 170, mass: 800, radius: 18, color: Color(0xFF99AAFF)),
      GravityBody(x: 640, y: 550, mass: 800, radius: 18, color: Color(0xFFAABBFF)),
    ],
    launchZone: Zone(x: 160, y: 360, radius: 40),
    gateway: Zone(x: 1120, y: 360, radius: 32),
    asteroids: [
      AsteroidDef(cx: 640, cy: 360, orbitR: 108, speed:  0.90, phase0: 0.5),
      AsteroidDef(cx: 640, cy: 360, orbitR: 122, speed: -0.65, phase0: 2.1),
      AsteroidDef(cx: 640, cy: 360, orbitR: 114, speed:  0.75, phase0: 4.3),
    ],
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

  // Level 7 — Must loop around; walls block the obvious direct path;
  //           black hole pulls off-course shots; asteroids orbit the big planet
  LevelData(
    id: 7, name: 'Full Circle', shots: 3, g: 130,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 9000, radius: 74, color: Color(0xFFFF8833)),
      GravityBody(x: 900, y: 560, mass: 1200, radius: 22, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 150, y: 580, radius: 38),
    gateway: Zone(x: 200, y: 130, radius: 30),
    blackHoles: [
      BlackHole(x: 385, y: 185, mass: 30000, radius: 15),
    ],
    walls: [
      // Horizontal bar — blocks the direct up-left shot
      Wall(x1: 35, y1: 335, x2: 315, y2: 335, thickness: 7),
      // Vertical bar — closes the upper-left corridor
      Wall(x1: 295, y1: 55, x2: 295, y2: 340, thickness: 7),
    ],
    asteroids: [
      AsteroidDef(cx: 640, cy: 360, orbitR: 118, speed:  0.80, phase0: 0.0),
      AsteroidDef(cx: 640, cy: 360, orbitR: 130, speed: -0.55, phase0: 3.2),
    ],
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

  // Level 9 — Defensive ring + black hole at centre
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
    blackHoles: [
      BlackHole(x: 640, y: 360, mass: 26000, radius: 14),
    ],
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Tier 2 — Intermediate (11–15)
  // ═══════════════════════════════════════════════════════════════════════════

  // Level 11 — Black hole introduces itself as central gravity
  LevelData(
    id: 11, name: 'Event Horizon', shots: 4, g: 110,
    gravityBodies: [
      GravityBody(x: 380, y: 200, mass: 1800, radius: 26, color: Color(0xFF99AAFF)),
      GravityBody(x: 900, y: 520, mass: 1600, radius: 24, color: Color(0xFFAABBFF)),
    ],
    launchZone: Zone(x: 140, y: 580, radius: 40),
    gateway: Zone(x: 1140, y: 140, radius: 30),
    blackHoles: [
      BlackHole(x: 640, y: 360, mass: 28000, radius: 16),
    ],
  ),

  // Level 12 — Parallel walls create a channel; planets pull sideways
  LevelData(
    id: 12, name: 'Corridor', shots: 4, g: 100,
    gravityBodies: [
      GravityBody(x: 500, y: 180, mass: 2800, radius: 38, color: Color(0xFFFF5533)),
      GravityBody(x: 780, y: 540, mass: 2800, radius: 38, color: Color(0xFF4488FF)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 38),
    gateway: Zone(x: 1160, y: 360, radius: 30),
    walls: [
      Wall(x1: 300, y1: 280, x2: 960, y2: 280, thickness: 7),
      Wall(x1: 300, y1: 440, x2: 960, y2: 440, thickness: 7),
    ],
  ),

  // Level 13 — Ring of asteroids around center planet; find the gap
  LevelData(
    id: 13, name: 'Asteroid Belt', shots: 4, g: 100,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 6000, radius: 56, color: Color(0xFFFFCC44)),
    ],
    launchZone: Zone(x: 130, y: 500, radius: 38),
    gateway: Zone(x: 1150, y: 220, radius: 30),
    asteroids: [
      AsteroidDef(cx: 640, cy: 360, orbitR: 100, speed: 0.70, phase0: 0.0),
      AsteroidDef(cx: 640, cy: 360, orbitR: 100, speed: 0.70, phase0: 1.26),
      AsteroidDef(cx: 640, cy: 360, orbitR: 100, speed: 0.70, phase0: 2.51),
      AsteroidDef(cx: 640, cy: 360, orbitR: 100, speed: 0.70, phase0: 3.77),
      AsteroidDef(cx: 640, cy: 360, orbitR: 100, speed: 0.70, phase0: 5.03),
    ],
  ),

  // Level 14 — Two black holes pulling in opposite directions
  LevelData(
    id: 14, name: 'Twin Holes', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 640, y: 160, mass: 1200, radius: 20, color: Color(0xFFFFEE99)),
      GravityBody(x: 640, y: 560, mass: 1200, radius: 20, color: Color(0xFFFFF4CC)),
    ],
    launchZone: Zone(x: 130, y: 360, radius: 38),
    gateway: Zone(x: 1150, y: 360, radius: 28),
    blackHoles: [
      BlackHole(x: 440, y: 240, mass: 24000, radius: 14),
      BlackHole(x: 840, y: 480, mass: 24000, radius: 14),
    ],
  ),

  // Level 15 — Three walls creating corridors + planets
  LevelData(
    id: 15, name: 'The Maze', shots: 4, g: 110,
    gravityBodies: [
      GravityBody(x: 350, y: 500, mass: 2400, radius: 34, color: Color(0xFFFF4422)),
      GravityBody(x: 640, y: 200, mass: 2600, radius: 36, color: Color(0xFF4488FF)),
      GravityBody(x: 950, y: 450, mass: 2200, radius: 32, color: Color(0xFFFFCC44)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 38),
    gateway: Zone(x: 1160, y: 160, radius: 28),
    walls: [
      Wall(x1: 260, y1: 60, x2: 260, y2: 400, thickness: 7),
      Wall(x1: 520, y1: 320, x2: 520, y2: 660, thickness: 7),
      Wall(x1: 800, y1: 60, x2: 800, y2: 360, thickness: 7),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // Tier 3 — Advanced (16–20)
  // ═══════════════════════════════════════════════════════════════════════════

  // Level 16 — Angled walls create bouncing paths
  LevelData(
    id: 16, name: 'Pinball', shots: 4, g: 90,
    gravityBodies: [
      GravityBody(x: 450, y: 360, mass: 3000, radius: 40, color: Color(0xFFFF9944)),
      GravityBody(x: 900, y: 300, mass: 2200, radius: 32, color: Color(0xFF5588FF)),
    ],
    launchZone: Zone(x: 130, y: 600, radius: 38),
    gateway: Zone(x: 1150, y: 120, radius: 28),
    walls: [
      Wall(x1: 250, y1: 200, x2: 380, y2: 130, thickness: 7),
      Wall(x1: 600, y1: 560, x2: 750, y2: 620, thickness: 7),
      Wall(x1: 700, y1: 140, x2: 850, y2: 200, thickness: 7),
      Wall(x1: 1000, y1: 400, x2: 1100, y2: 500, thickness: 7),
    ],
  ),

  // Level 17 — Uses wider world; objects past x=1280
  LevelData(
    id: 17, name: 'Outer Rim', shots: 4, g: 100,
    gravityBodies: [
      GravityBody(x: 500, y: 360, mass: 4000, radius: 50, color: Color(0xFFFFCC44)),
      GravityBody(x: 1000, y: 250, mass: 2600, radius: 36, color: Color(0xFFFF5533)),
      GravityBody(x: 1500, y: 400, mass: 3000, radius: 42, color: Color(0xFF4488FF)),
    ],
    launchZone: Zone(x: 150, y: 500, radius: 40),
    gateway: Zone(x: 1800, y: 200, radius: 30),
  ),

  // Level 18 — Large center planet + many asteroids at different speeds
  LevelData(
    id: 18, name: 'Spiral Arms', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 640, y: 360, mass: 7000, radius: 62, color: Color(0xFFFF8833)),
    ],
    launchZone: Zone(x: 130, y: 360, radius: 38),
    gateway: Zone(x: 1150, y: 360, radius: 28),
    asteroids: [
      AsteroidDef(cx: 640, cy: 360, orbitR: 105, speed:  0.90, phase0: 0.0),
      AsteroidDef(cx: 640, cy: 360, orbitR: 120, speed: -0.60, phase0: 1.0),
      AsteroidDef(cx: 640, cy: 360, orbitR: 138, speed:  0.45, phase0: 2.5),
      AsteroidDef(cx: 640, cy: 360, orbitR: 155, speed: -0.80, phase0: 4.0),
      AsteroidDef(cx: 640, cy: 360, orbitR: 170, speed:  0.55, phase0: 5.5),
    ],
  ),

  // Level 19 — Massive black hole center + 4 planets around it
  LevelData(
    id: 19, name: 'Gravity Well', shots: 3, g: 130,
    gravityBodies: [
      GravityBody(x: 400, y: 180, mass: 1800, radius: 26, color: Color(0xFF99AAFF)),
      GravityBody(x: 880, y: 180, mass: 1800, radius: 26, color: Color(0xFFFF9944)),
      GravityBody(x: 400, y: 540, mass: 1800, radius: 26, color: Color(0xFFFFEE99)),
      GravityBody(x: 880, y: 540, mass: 1800, radius: 26, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 36),
    gateway: Zone(x: 1160, y: 360, radius: 28),
    blackHoles: [
      BlackHole(x: 640, y: 360, mass: 35000, radius: 18),
    ],
  ),

  // Level 20 — Ring of 6 planets, black hole center, wall barriers
  LevelData(
    id: 20, name: 'Gauntlet II', shots: 3, g: 130,
    gravityBodies: [
      GravityBody(x: 440, y: 180, mass: 2400, radius: 34, color: Color(0xFFFF4422)),
      GravityBody(x: 840, y: 180, mass: 2400, radius: 34, color: Color(0xFF4488FF)),
      GravityBody(x: 340, y: 360, mass: 2000, radius: 30, color: Color(0xFFFFCC44)),
      GravityBody(x: 940, y: 360, mass: 2000, radius: 30, color: Color(0xFFFF9944)),
      GravityBody(x: 440, y: 540, mass: 2400, radius: 34, color: Color(0xFF99AAFF)),
      GravityBody(x: 840, y: 540, mass: 2400, radius: 34, color: Color(0xFFFF5533)),
    ],
    launchZone: Zone(x: 110, y: 360, radius: 36),
    gateway: Zone(x: 1170, y: 360, radius: 26),
    blackHoles: [
      BlackHole(x: 640, y: 360, mass: 22000, radius: 13),
    ],
    walls: [
      Wall(x1: 580, y1: 60, x2: 580, y2: 280, thickness: 7),
      Wall(x1: 700, y1: 440, x2: 700, y2: 660, thickness: 7),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // Tier 4 — Expert (21–25)
  // ═══════════════════════════════════════════════════════════════════════════

  // Level 21 — Wide world; launch right, gateway far left; 3 black holes
  LevelData(
    id: 21, name: 'Wormhole', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 600, y: 300, mass: 3000, radius: 40, color: Color(0xFFFF8833)),
      GravityBody(x: 1200, y: 500, mass: 2500, radius: 36, color: Color(0xFF4488FF)),
      GravityBody(x: 1700, y: 250, mass: 2800, radius: 38, color: Color(0xFFFFCC44)),
    ],
    launchZone: Zone(x: 2000, y: 500, radius: 38),
    gateway: Zone(x: 150, y: 150, radius: 28),
    blackHoles: [
      BlackHole(x: 400, y: 500, mass: 25000, radius: 14),
      BlackHole(x: 950, y: 200, mass: 22000, radius: 13),
      BlackHole(x: 1450, y: 450, mass: 20000, radius: 12),
    ],
  ),

  // Level 22 — Gateway surrounded by walls + asteroids
  LevelData(
    id: 22, name: 'Fortress', shots: 3, g: 110,
    gravityBodies: [
      GravityBody(x: 500, y: 360, mass: 4000, radius: 48, color: Color(0xFFFF3311)),
      GravityBody(x: 820, y: 200, mass: 1800, radius: 26, color: Color(0xFF99AAFF)),
    ],
    launchZone: Zone(x: 130, y: 560, radius: 38),
    gateway: Zone(x: 1050, y: 400, radius: 26),
    walls: [
      Wall(x1: 960, y1: 320, x2: 1140, y2: 320, thickness: 7),
      Wall(x1: 960, y1: 480, x2: 1140, y2: 480, thickness: 7),
      Wall(x1: 1140, y1: 320, x2: 1140, y2: 480, thickness: 7),
    ],
    asteroids: [
      AsteroidDef(cx: 1050, cy: 400, orbitR: 110, speed: 0.75, phase0: 0.0),
      AsteroidDef(cx: 1050, cy: 400, orbitR: 110, speed: 0.75, phase0: 3.14),
    ],
  ),

  // Level 23 — 2 close black holes + 4 planets + walls
  LevelData(
    id: 23, name: 'Binary Collapse', shots: 3, g: 130,
    gravityBodies: [
      GravityBody(x: 350, y: 200, mass: 2600, radius: 36, color: Color(0xFFFF5533)),
      GravityBody(x: 350, y: 520, mass: 2600, radius: 36, color: Color(0xFF4488FF)),
      GravityBody(x: 900, y: 200, mass: 2200, radius: 32, color: Color(0xFFFFEE99)),
      GravityBody(x: 900, y: 520, mass: 2200, radius: 32, color: Color(0xFFFFCC44)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 36),
    gateway: Zone(x: 1160, y: 360, radius: 26),
    blackHoles: [
      BlackHole(x: 590, y: 320, mass: 26000, radius: 14),
      BlackHole(x: 690, y: 400, mass: 26000, radius: 14),
    ],
    walls: [
      Wall(x1: 200, y1: 360, x2: 480, y2: 360, thickness: 7),
      Wall(x1: 800, y1: 360, x2: 1060, y2: 360, thickness: 7),
    ],
  ),

  // Level 24 — 6 asteroids orbiting 2 planets at different speeds
  LevelData(
    id: 24, name: 'Asteroid Storm', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 440, y: 320, mass: 4500, radius: 52, color: Color(0xFFFF8833)),
      GravityBody(x: 880, y: 400, mass: 4000, radius: 48, color: Color(0xFF3366FF)),
    ],
    launchZone: Zone(x: 130, y: 600, radius: 36),
    gateway: Zone(x: 1150, y: 120, radius: 26),
    asteroids: [
      AsteroidDef(cx: 440, cy: 320, orbitR: 95, speed:  0.90, phase0: 0.0),
      AsteroidDef(cx: 440, cy: 320, orbitR: 95, speed:  0.90, phase0: 2.09),
      AsteroidDef(cx: 440, cy: 320, orbitR: 95, speed:  0.90, phase0: 4.19),
      AsteroidDef(cx: 880, cy: 400, orbitR: 90, speed: -0.80, phase0: 0.5),
      AsteroidDef(cx: 880, cy: 400, orbitR: 90, speed: -0.80, phase0: 2.59),
      AsteroidDef(cx: 880, cy: 400, orbitR: 90, speed: -0.80, phase0: 4.69),
    ],
  ),

  // Level 25 — Converging walls + black hole at narrow end
  LevelData(
    id: 25, name: 'The Funnel', shots: 3, g: 120,
    gravityBodies: [
      GravityBody(x: 400, y: 360, mass: 2800, radius: 38, color: Color(0xFFFFCC44)),
      GravityBody(x: 750, y: 200, mass: 1600, radius: 24, color: Color(0xFF99AAFF)),
      GravityBody(x: 750, y: 520, mass: 1600, radius: 24, color: Color(0xFFFF9944)),
    ],
    launchZone: Zone(x: 130, y: 360, radius: 36),
    gateway: Zone(x: 1150, y: 360, radius: 26),
    blackHoles: [
      BlackHole(x: 1000, y: 360, mass: 30000, radius: 16),
    ],
    walls: [
      Wall(x1: 550, y1: 100, x2: 920, y2: 300, thickness: 7),
      Wall(x1: 550, y1: 620, x2: 920, y2: 420, thickness: 7),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // Tier 5 — Master (26–30)
  // ═══════════════════════════════════════════════════════════════════════════

  // Level 26 — 3 black holes, no visible planets; navigate by invisible gravity
  LevelData(
    id: 26, name: 'Dark Matter', shots: 3, g: 130,
    gravityBodies: [],
    launchZone: Zone(x: 130, y: 580, radius: 36),
    gateway: Zone(x: 1150, y: 130, radius: 26),
    blackHoles: [
      BlackHole(x: 380, y: 280, mass: 28000, radius: 15),
      BlackHole(x: 700, y: 500, mass: 32000, radius: 16),
      BlackHole(x: 960, y: 250, mass: 26000, radius: 14),
    ],
  ),

  // Level 27 — Wide world; extreme distance; many obstacles; 2 shots
  LevelData(
    id: 27, name: 'Impossible Shot', shots: 2, g: 110,
    gravityBodies: [
      GravityBody(x: 500, y: 400, mass: 3500, radius: 44, color: Color(0xFFFF5533)),
      GravityBody(x: 900, y: 250, mass: 3000, radius: 40, color: Color(0xFF4488FF)),
      GravityBody(x: 1350, y: 450, mass: 3200, radius: 42, color: Color(0xFFFFCC44)),
      GravityBody(x: 1750, y: 280, mass: 2800, radius: 38, color: Color(0xFF99AAFF)),
    ],
    launchZone: Zone(x: 140, y: 580, radius: 36),
    gateway: Zone(x: 2100, y: 150, radius: 26),
    blackHoles: [
      BlackHole(x: 700, y: 550, mass: 20000, radius: 12),
      BlackHole(x: 1550, y: 200, mass: 22000, radius: 13),
    ],
    walls: [
      Wall(x1: 1100, y1: 100, x2: 1100, y2: 380, thickness: 7),
    ],
  ),

  // Level 28 — Chaos: 8 planets + 2 black holes + 4 asteroids + 2 walls
  LevelData(
    id: 28, name: 'Chaos Theory', shots: 3, g: 140,
    gravityBodies: [
      GravityBody(x: 280, y: 200, mass: 2000, radius: 30, color: Color(0xFFFF4422)),
      GravityBody(x: 450, y: 480, mass: 2400, radius: 34, color: Color(0xFF4488FF)),
      GravityBody(x: 580, y: 200, mass: 1800, radius: 28, color: Color(0xFFFFEE99)),
      GravityBody(x: 700, y: 520, mass: 2200, radius: 32, color: Color(0xFFFF9944)),
      GravityBody(x: 820, y: 180, mass: 2600, radius: 36, color: Color(0xFF5588FF)),
      GravityBody(x: 940, y: 480, mass: 2000, radius: 30, color: Color(0xFFFFCC44)),
      GravityBody(x: 1060, y: 220, mass: 1600, radius: 26, color: Color(0xFFFF5533)),
      GravityBody(x: 1100, y: 550, mass: 1400, radius: 24, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 110, y: 600, radius: 34),
    gateway: Zone(x: 1180, y: 100, radius: 24),
    blackHoles: [
      BlackHole(x: 400, y: 340, mass: 20000, radius: 12),
      BlackHole(x: 860, y: 360, mass: 22000, radius: 13),
    ],
    walls: [
      Wall(x1: 200, y1: 380, x2: 500, y2: 380, thickness: 7),
      Wall(x1: 760, y1: 340, x2: 1000, y2: 340, thickness: 7),
    ],
    asteroids: [
      AsteroidDef(cx: 400, cy: 340, orbitR: 80, speed:  0.70, phase0: 0.0),
      AsteroidDef(cx: 400, cy: 340, orbitR: 80, speed:  0.70, phase0: 3.14),
      AsteroidDef(cx: 860, cy: 360, orbitR: 75, speed: -0.65, phase0: 1.0),
      AsteroidDef(cx: 860, cy: 360, orbitR: 75, speed: -0.65, phase0: 4.14),
    ],
  ),

  // Level 29 — Massive central black hole; must slingshot perfectly
  LevelData(
    id: 29, name: 'Singularity', shots: 3, g: 150,
    gravityBodies: [
      GravityBody(x: 350, y: 180, mass: 1400, radius: 22, color: Color(0xFF99AAFF)),
      GravityBody(x: 350, y: 540, mass: 1400, radius: 22, color: Color(0xFFFFEE99)),
      GravityBody(x: 930, y: 180, mass: 1400, radius: 22, color: Color(0xFFFF9944)),
      GravityBody(x: 930, y: 540, mass: 1400, radius: 22, color: Color(0xFF66CCFF)),
    ],
    launchZone: Zone(x: 120, y: 360, radius: 36),
    gateway: Zone(x: 1160, y: 360, radius: 24),
    blackHoles: [
      BlackHole(x: 640, y: 360, mass: 50000, radius: 20),
    ],
  ),

  // Level 30 — The ultimate: wide world, everything combined, 2 shots
  LevelData(
    id: 30, name: 'Gravity Master', shots: 2, g: 140,
    gravityBodies: [
      GravityBody(x: 400, y: 300, mass: 3500, radius: 44, color: Color(0xFFFF8833)),
      GravityBody(x: 700, y: 550, mass: 2800, radius: 38, color: Color(0xFF4488FF)),
      GravityBody(x: 1100, y: 200, mass: 3200, radius: 42, color: Color(0xFFFFCC44)),
      GravityBody(x: 1450, y: 480, mass: 2600, radius: 36, color: Color(0xFFFF5533)),
      GravityBody(x: 1800, y: 300, mass: 3000, radius: 40, color: Color(0xFF99AAFF)),
      GravityBody(x: 2050, y: 500, mass: 2200, radius: 32, color: Color(0xFFFF4422)),
    ],
    launchZone: Zone(x: 130, y: 580, radius: 36),
    gateway: Zone(x: 2300, y: 120, radius: 24),
    blackHoles: [
      BlackHole(x: 550, y: 450, mass: 28000, radius: 15),
      BlackHole(x: 950, y: 380, mass: 30000, radius: 16),
      BlackHole(x: 1650, y: 200, mass: 26000, radius: 14),
    ],
    walls: [
      Wall(x1: 300, y1: 460, x2: 600, y2: 460, thickness: 7),
      Wall(x1: 850, y1: 280, x2: 1050, y2: 280, thickness: 7),
      Wall(x1: 1900, y1: 200, x2: 1900, y2: 440, thickness: 7),
    ],
    asteroids: [
      AsteroidDef(cx: 400, cy: 300, orbitR: 90, speed:  0.80, phase0: 0.0),
      AsteroidDef(cx: 700, cy: 550, orbitR: 80, speed: -0.70, phase0: 1.5),
      AsteroidDef(cx: 1100, cy: 200, orbitR: 85, speed:  0.60, phase0: 3.0),
      AsteroidDef(cx: 1450, cy: 480, orbitR: 75, speed: -0.90, phase0: 4.5),
      AsteroidDef(cx: 1800, cy: 300, orbitR: 82, speed:  0.55, phase0: 0.8),
      AsteroidDef(cx: 2050, cy: 500, orbitR: 70, speed: -0.75, phase0: 2.2),
    ],
  ),
];
