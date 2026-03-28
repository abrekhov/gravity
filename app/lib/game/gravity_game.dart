import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'level_data.dart';
import 'physics.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class GameEvent {}

class LevelStarted extends GameEvent {
  final LevelData level;
  LevelStarted(this.level);
}

class LevelWon extends GameEvent {
  final int levelId;
  LevelWon(this.levelId);
}

class LevelFailed extends GameEvent {}

class ShotUsed extends GameEvent {
  final int remaining;
  ShotUsed(this.remaining);
}

class DotLaunched extends GameEvent {}

// ─── Phase ───────────────────────────────────────────────────────────────────

enum _Phase { aiming, flying, dead, won }

// ─── Main Game ───────────────────────────────────────────────────────────────

class GravityGame extends FlameGame with DragCallbacks {
  // Public state (read by overlays)
  int currentLevelId = 1;
  int unlockedLevelId = 1;
  LevelData? activeLevel;

  final _eventCtrl = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventCtrl.stream;

  // Private state
  _Phase _phase = _Phase.aiming;
  DotState? _dot;
  int _shotsRemaining = 0;
  bool _isDragging = false;
  Vector2 _dragStart = Vector2.zero();
  Vector2 _dragCurrent = Vector2.zero();
  final _trail = <Vector2>[];

  // Camera scroll
  double _camTargetX = 0.0;

  // Fixed-timestep accumulator — ensures physics always steps at Physics.fixedDt
  // (1/60 s) regardless of display refresh rate, so trajectory exactly matches.
  double _physicsAccum = 0.0;

  // Components
  late final World _world;
  late final CameraComponent _camera;
  final _levelComponents = <Component>[];
  _DotComponent? _dotComp;
  _TrajectoryComponent? _trajComp;
  _AimArrowComponent? _aimComp;
  _GatewayComponent? _gatewayComp;
  _LaunchZoneComponent? _lzComp;
  final _asteroidComps = <_AsteroidComponent>[];
  _ExplosionComponent? _explosionComp;

  // Prefs
  late SharedPreferences _prefs;

  @override
  Color backgroundColor() => const Color(0xFF000814);

  @override
  Future<void> onLoad() async {
    _world = World();
    _camera = CameraComponent.withFixedResolution(
      world: _world,
      width: 1280,
      height: 720,
    );
    _camera.viewfinder.anchor = Anchor.topLeft;
    await addAll([_world, _camera]);

    _prefs = await SharedPreferences.getInstance();
    unlockedLevelId = _prefs.getInt('gravity_unlocked') ?? 1;
    currentLevelId = unlockedLevelId;

    await _world.add(_StarfieldComponent());
    overlays.add('MainMenu');
  }

  // ─── Level management ────────────────────────────────────────────────────

  Future<void> startLevel(int levelId) async {
    currentLevelId = levelId;
    activeLevel = kLevels.firstWhere((l) => l.id == levelId);
    _phase = _Phase.aiming;
    _shotsRemaining = activeLevel!.shots;
    _dot = null;
    _trail.clear();
    _isDragging = false;
    _camTargetX = 0.0;
    _physicsAccum = 0.0;
    _camera.viewfinder.position = Vector2.zero();

    for (final c in _levelComponents) {
      c.removeFromParent();
    }
    _levelComponents.clear();
    _asteroidComps.clear();

    for (final body in activeLevel!.gravityBodies) {
      final p = _PlanetComponent(body);
      _levelComponents.add(p);
      _world.add(p);
    }

    for (final bh in activeLevel!.blackHoles) {
      final c = _BlackHoleComponent(bh);
      _levelComponents.add(c);
      _world.add(c);
    }

    for (final wall in activeLevel!.walls) {
      final c = _WallComponent(wall);
      _levelComponents.add(c);
      _world.add(c);
    }

    for (final ast in activeLevel!.asteroids) {
      final c = _AsteroidComponent(ast);
      _levelComponents.add(c);
      _world.add(c);
      _asteroidComps.add(c);
    }

    _lzComp = _LaunchZoneComponent(activeLevel!.launchZone);
    _gatewayComp = _GatewayComponent(activeLevel!.gateway);
    _trajComp = _TrajectoryComponent();
    _aimComp = _AimArrowComponent();
    _dotComp = _DotComponent();

    for (final c in [_lzComp!, _gatewayComp!, _trajComp!, _aimComp!, _dotComp!]) {
      _levelComponents.add(c);
      _world.add(c);
    }

    overlays.remove('MainMenu');
    overlays.remove('LevelSelect');
    overlays.remove('WinOverlay');
    overlays.remove('FailOverlay');
    if (!overlays.isActive('HUD')) overlays.add('HUD');

    _eventCtrl.add(LevelStarted(activeLevel!));
  }

  void retry() {
    overlays.remove('WinOverlay');
    overlays.remove('FailOverlay');
    startLevel(currentLevelId);
  }

  void nextLevel() {
    final nextId = (activeLevel?.id ?? 0) + 1;
    startLevel(nextId > kLevels.length ? 1 : nextId);
  }

  void goToMenu({bool showLevels = false}) {
    overlays.remove('HUD');
    overlays.remove('WinOverlay');
    overlays.remove('FailOverlay');
    for (final c in _levelComponents) c.removeFromParent();
    _levelComponents.clear();
    _asteroidComps.clear();
    activeLevel = null;
    _dot = null;
    _camera.viewfinder.position = Vector2.zero();
    overlays.add(showLevels ? 'LevelSelect' : 'MainMenu');
  }

  // ─── Game loop ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth camera scroll
    _updateCamera(dt);

    if (_phase != _Phase.flying || _dot == null || activeLevel == null) return;

    // Fixed timestep: accumulate real time and consume in Physics.fixedDt chunks.
    // This ensures physics always uses the same step size as the trajectory
    // preview, so the shot follows the predicted path at any display refresh rate.
    _physicsAccum += dt.clamp(0.0, 0.10); // 100ms cap prevents spiral-of-death
    while (_physicsAccum >= Physics.fixedDt) {
      Physics.step(_dot!, activeLevel!, Physics.fixedDt);
      _physicsAccum -= Physics.fixedDt;
      _trail.add(Vector2(_dot!.x, _dot!.y));
      if (_trail.length > 60) _trail.removeAt(0);
      _checkCollisions();
      if (_phase != _Phase.flying) break;
    }
    _dotComp?.updateState(_dot!, List.of(_trail));
  }

  void _updateCamera(double dt) {
    if (activeLevel == null) return;
    if (_phase == _Phase.flying && _dot != null) {
      _camTargetX = (_dot!.x - 640).clamp(0.0, 1280.0);
    } else {
      _camTargetX = (activeLevel!.launchZone.x - 640).clamp(0.0, 1280.0);
    }
    final cx = _camera.viewfinder.position.x;
    _camera.viewfinder.position = Vector2(
      cx + (_camTargetX - cx) * (1 - math.exp(-6 * dt)),
      0,
    );
  }

  // ─── Input ───────────────────────────────────────────────────────────────

  /// Convert canvas/screen coordinates to world coordinates, accounting for
  /// the current camera scroll offset.
  Vector2 _toWorld(Vector2 screenPos) {
    final scale = math.min(size.x / 1280, size.y / 720);
    final offsetX = (size.x - 1280 * scale) / 2;
    final offsetY = (size.y - 720 * scale) / 2;
    return Vector2(
      (screenPos.x - offsetX) / scale + _camera.viewfinder.position.x,
      (screenPos.y - offsetY) / scale + _camera.viewfinder.position.y,
    );
  }

  Vector2 _dragToVelocity(Vector2 ptr) {
    final raw = ptr - _dragStart;
    final mag = raw.length;
    if (mag < 0.001) return Vector2.zero();
    final clamped = math.min(mag, Physics.maxDrag);
    return -raw / mag * (clamped * Physics.velocityScale);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_phase != _Phase.aiming || activeLevel == null) return;
    final pos = _toWorld(event.localPosition);
    final lz = activeLevel!.launchZone;
    final dist = (pos - Vector2(lz.x, lz.y)).length;
    if (dist > lz.radius * 1.5) return;
    _isDragging = true;
    _dragStart = pos.clone();
    _dragCurrent = pos.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDragging || activeLevel == null) return;
    _dragCurrent = _toWorld(event.localPosition);
    final vel = _dragToVelocity(_dragCurrent);
    _trajComp?.setPreview(vel.x, vel.y, activeLevel!);
    _aimComp?.setDrag(_dragStart, _dragCurrent, activeLevel!.launchZone);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging || activeLevel == null) return;
    _isDragging = false;
    _aimComp?.clear();
    final raw = _dragCurrent - _dragStart;
    if (raw.length < Physics.minLaunchMag) {
      _trajComp?.clear();
      return;
    }
    // Keep trajectory visible during flight so players can verify ship follows it.
    // It will be cleared when next aiming starts or on reset.
    _launch(_dragToVelocity(_dragCurrent));
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _trajComp?.clear();
    _aimComp?.clear();
  }

  void _launch(Vector2 vel) {
    final lz = activeLevel!.launchZone;
    _dot = DotState(lz.x, lz.y, vel.x, vel.y);
    _phase = _Phase.flying;
    _lzComp?.setDimmed(true);
    _eventCtrl.add(DotLaunched());
  }

  // ─── Collisions ──────────────────────────────────────────────────────────

  void _checkCollisions() {
    final dot = _dot!;
    final level = activeLevel!;

    // Gateway win
    final gw = level.gateway;
    final dgw = math.sqrt(
        (dot.x - gw.x) * (dot.x - gw.x) + (dot.y - gw.y) * (dot.y - gw.y));
    if (dgw < gw.radius) {
      _triggerWin();
      return;
    }

    // Planet collision
    for (final body in level.gravityBodies) {
      final d = math.sqrt((dot.x - body.x) * (dot.x - body.x) +
          (dot.y - body.y) * (dot.y - body.y));
      if (d < body.radius * 1.05) {
        _triggerFail();
        return;
      }
    }

    // Black hole collision
    for (final bh in level.blackHoles) {
      final d = math.sqrt((dot.x - bh.x) * (dot.x - bh.x) +
          (dot.y - bh.y) * (dot.y - bh.y));
      if (d < bh.radius * 1.1) {
        _triggerFail();
        return;
      }
    }

    // Asteroid collision
    for (final ast in _asteroidComps) {
      final ax = ast.posX, ay = ast.posY;
      final d = math.sqrt(
          (dot.x - ax) * (dot.x - ax) + (dot.y - ay) * (dot.y - ay));
      if (d < ast.def.radius + 5) {
        _triggerFail();
        return;
      }
    }

    // Out of bounds (world is 2560 wide)
    if (dot.x < -120 || dot.x > 2680 || dot.y < -120 || dot.y > 840) {
      _triggerFail();
    }
  }

  void _triggerWin() {
    if (_phase == _Phase.won) return;
    _phase = _Phase.won;

    final nextId = activeLevel!.id + 1;
    if (nextId > unlockedLevelId && nextId <= kLevels.length + 1) {
      unlockedLevelId = nextId;
      _prefs.setInt('gravity_unlocked', nextId);
    }

    Future.delayed(const Duration(milliseconds: 350), () {
      _eventCtrl.add(LevelWon(activeLevel!.id));
      overlays.add('WinOverlay');
    });
  }

  void _triggerFail() {
    if (_phase == _Phase.dead) return;
    _phase = _Phase.dead;
    _dotComp?.hide();

    // Spawn explosion at the crash point
    if (_dot != null) {
      _explosionComp?.removeFromParent();
      _explosionComp = _ExplosionComponent(_dot!.x, _dot!.y);
      _world.add(_explosionComp!);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      _shotsRemaining--;
      if (_shotsRemaining <= 0) {
        _eventCtrl.add(LevelFailed());
        overlays.add('FailOverlay');
      } else {
        _eventCtrl.add(ShotUsed(_shotsRemaining));
        _resetToAiming();
      }
    });
  }

  void _resetToAiming() {
    _phase = _Phase.aiming;
    _dot = null;
    _trail.clear();
    _physicsAccum = 0.0;
    _trajComp?.clear();  // clear previous shot's trajectory
    _lzComp?.setDimmed(false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual Components
// ─────────────────────────────────────────────────────────────────────────────

// ─── Starfield ───────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, a;
  final Color color;
  _Star(this.x, this.y, this.r, this.a, this.color);
}

class _StarfieldComponent extends Component {
  final _stars = <_Star>[];

  @override
  Future<void> onLoad() async {
    final rng = math.Random(0x47524156);
    // Cover the full 2560-wide world
    for (int i = 0; i < 400; i++) {
      final x = rng.nextDouble() * 2560;
      final y = rng.nextDouble() * 720;
      final r = rng.nextDouble() < 0.12 ? 0.5 : 0.3;
      final a = 0.06 + rng.nextDouble() * 0.18;
      Color col = const Color(0xFFFFFFFF);
      if (rng.nextDouble() < 0.15) {
        col = rng.nextBool()
            ? const Color(0xFFDDE8FF)
            : const Color(0xFFFFF0E8);
      }
      _stars.add(_Star(x, y, r, a, col));
    }
  }

  @override
  void render(Canvas canvas) {
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.r,
        Paint()..color = s.color.withOpacity(s.a),
      );
    }
  }
}

// ─── Planet ──────────────────────────────────────────────────────────────────

class _PlanetComponent extends Component {
  final GravityBody body;
  _PlanetComponent(this.body) : super(priority: 1);

  /// Map mass → color on a cool-to-hot gradient.
  /// Low mass (≤1200) = dim blue, high mass (≥8000) = bright orange-red.
  static Color _massColor(double mass) {
    // Normalize mass to 0..1 range (1200..8000 mapped to 0..1)
    final t = ((mass - 1200) / 6800).clamp(0.0, 1.0);
    // Gradient stops: deep-blue → cyan → white → yellow → orange → red
    if (t < 0.2) {
      final s = t / 0.2;
      return Color.fromRGBO(
        (40 + 30 * s).round(), (60 + 140 * s).round(), (180 + 75 * s).round(), 1);
    } else if (t < 0.4) {
      final s = (t - 0.2) / 0.2;
      return Color.fromRGBO(
        (70 + 185 * s).round(), (200 + 55 * s).round(), (255 - 30 * s).round(), 1);
    } else if (t < 0.6) {
      final s = (t - 0.4) / 0.2;
      return Color.fromRGBO(255, (255 - 35 * s).round(), (225 - 145 * s).round(), 1);
    } else if (t < 0.8) {
      final s = (t - 0.6) / 0.2;
      return Color.fromRGBO(255, (220 - 100 * s).round(), (80 - 40 * s).round(), 1);
    } else {
      final s = (t - 0.8) / 0.2;
      return Color.fromRGBO(255, (120 - 70 * s).round(), (40 - 20 * s).round(), 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final c = _massColor(body.mass);
    // Glow intensity scales with mass (heavier = more glow)
    final glowStrength = ((body.mass - 1200) / 6800).clamp(0.15, 1.0);
    // 5 glow layers
    for (int i = 5; i >= 1; i--) {
      canvas.drawCircle(
        Offset(body.x, body.y),
        body.radius + i * 7,
        Paint()..color = c.withOpacity(0.055 * (6 - i) * glowStrength),
      );
    }
    // Solid core
    canvas.drawCircle(Offset(body.x, body.y), body.radius, Paint()..color = c);
    // Specular highlight
    canvas.drawCircle(
      Offset(body.x - body.radius * 0.3, body.y - body.radius * 0.3),
      body.radius * 0.35,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.28),
    );
  }
}

// ─── Black Hole ───────────────────────────────────────────────────────────────

class _BlackHoleComponent extends Component {
  final BlackHole bh;
  _BlackHoleComponent(this.bh) : super(priority: 1);

  @override
  void render(Canvas canvas) {
    final x = bh.x, y = bh.y, r = bh.radius;

    // Gravitational lensing glow (subtle purple)
    for (int i = 5; i >= 1; i--) {
      canvas.drawCircle(
        Offset(x, y),
        r + i * 9,
        Paint()..color = const Color(0xFF5533BB).withOpacity(0.025 * (6 - i)),
      );
    }

    // Outer accretion disk
    canvas.drawCircle(
      Offset(x, y),
      r + 5,
      Paint()
        ..color = const Color(0xFFFF7700).withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    // Inner hot ring
    canvas.drawCircle(
      Offset(x, y),
      r + 2,
      Paint()
        ..color = const Color(0xFFFFDD88).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Completely black core
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()..color = const Color(0xFF000000),
    );
  }
}

// ─── Wall ────────────────────────────────────────────────────────────────────

class _WallComponent extends Component {
  final Wall wall;
  _WallComponent(this.wall) : super(priority: 1);

  @override
  void render(Canvas canvas) {
    final p1 = Offset(wall.x1, wall.y1);
    final p2 = Offset(wall.x2, wall.y2);

    // Outer glow
    canvas.drawLine(
      p1, p2,
      Paint()
        ..color = const Color(0xFF4466BB).withOpacity(0.20)
        ..strokeWidth = wall.thickness + 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      p1, p2,
      Paint()
        ..color = const Color(0xFF6688CC).withOpacity(0.30)
        ..strokeWidth = wall.thickness + 5
        ..strokeCap = StrokeCap.round,
    );

    // Core
    canvas.drawLine(
      p1, p2,
      Paint()
        ..color = const Color(0xFFAABBDD).withOpacity(0.90)
        ..strokeWidth = wall.thickness
        ..strokeCap = StrokeCap.round,
    );
  }
}

// ─── Asteroid ────────────────────────────────────────────────────────────────

class _AsteroidComponent extends Component {
  final AsteroidDef def;
  double _angle;

  _AsteroidComponent(this.def)
      : _angle = def.phase0,
        super(priority: 6);

  double get posX => def.cx + def.orbitR * math.cos(_angle);
  double get posY => def.cy + def.orbitR * math.sin(_angle);

  @override
  void update(double dt) {
    _angle += def.speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final x = posX, y = posY, r = def.radius;

    // Irregular rock polygon
    const sides = 7;
    const bumps = <double>[0.0, 0.35, -0.25, 0.4, -0.15, 0.3, -0.2];
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2;
      final rr = r + bumps[i];
      final px = x + rr * math.cos(a);
      final py = y + rr * math.sin(a);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF887766));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}

// ─── Launch Zone ─────────────────────────────────────────────────────────────

class _LaunchZoneComponent extends Component {
  final Zone config;
  bool _dimmed = false;
  double _pulsePhase = 0;

  _LaunchZoneComponent(this.config) : super(priority: 2);

  void setDimmed(bool v) => _dimmed = v;

  @override
  void update(double dt) {
    if (!_dimmed) {
      _pulsePhase += dt * math.pi / 0.9; // 900ms period
    }
  }

  @override
  void render(Canvas canvas) {
    if (_dimmed) {
      _drawLaunchZone(canvas, 0.3);
      return;
    }
    final pulse = (math.sin(_pulsePhase) * 0.5 + 0.5); // 0..1
    final a = 0.4 + 0.6 * pulse;
    _drawLaunchZone(canvas, a);
  }

  void _drawLaunchZone(Canvas canvas, double a) {
    final x = config.x, y = config.y, r = config.radius;

    // Subtle fill
    canvas.drawCircle(
      Offset(x, y), r,
      Paint()..color = const Color(0xFF4466AA).withOpacity(0.06 * a),
    );
    // Outer ring
    canvas.drawCircle(
      Offset(x, y), r,
      Paint()
        ..color = const Color(0xFF7799CC).withOpacity(0.45 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Crosshair ticks
    final t = r * 0.28;
    final tickPaint = Paint()
      ..color = const Color(0xFF9AB0CC).withOpacity(0.3 * a)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(x - t, y), Offset(x + t, y), tickPaint);
    canvas.drawLine(Offset(x, y - t), Offset(x, y + t), tickPaint);
  }
}

// ─── Gateway ─────────────────────────────────────────────────────────────────

class _GatewayComponent extends Component {
  final Zone config;
  double _elapsed = 0; // ms

  _GatewayComponent(this.config) : super(priority: 3);

  @override
  void update(double dt) => _elapsed += dt * 1000;

  @override
  void render(Canvas canvas) {
    final gx = config.x, gy = config.y, gr = config.radius;
    final t = _elapsed;

    // Soft outer halos
    canvas.drawCircle(Offset(gx, gy), gr * 2.4,
        Paint()..color = const Color(0xFF7755CC).withOpacity(0.04));
    canvas.drawCircle(Offset(gx, gy), gr * 1.5,
        Paint()..color = const Color(0xFF9966EE).withOpacity(0.07));

    // 3 slow expanding rings
    for (int i = 0; i < 3; i++) {
      final phase = ((t / 2200) + i / 3) % 1;
      final rad = gr * 0.4 + gr * 1.3 * phase;
      final alpha = (1 - phase) * 0.4;
      canvas.drawCircle(
        Offset(gx, gy), rad,
        Paint()
          ..color = const Color(0xFFAA88FF).withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Rotating inner ring
    final angle = (t / 3000) * math.pi * 2;
    final ir = gr * 0.55;
    canvas.drawCircle(
      Offset(gx, gy), ir,
      Paint()
        ..color = const Color(0xFFCCBBFF).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // 4 tick marks
    for (int i = 0; i < 4; i++) {
      final a = angle + (i / 4) * math.pi * 2;
      final r1 = ir - 4, r2 = ir + 4;
      canvas.drawLine(
        Offset(gx + math.cos(a) * r1, gy + math.sin(a) * r1),
        Offset(gx + math.cos(a) * r2, gy + math.sin(a) * r2),
        Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(0.35)
          ..strokeWidth = 1.5,
      );
    }

    // Core
    canvas.drawCircle(Offset(gx, gy), 8,
        Paint()..color = const Color(0xFF9966FF).withOpacity(0.25));
    canvas.drawCircle(Offset(gx, gy), 3,
        Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.9));
  }
}

// ─── Dot / Starship ──────────────────────────────────────────────────────────

class _DotComponent extends Component {
  DotState? _dot;
  List<Vector2> _trail = [];
  bool _visible = false;
  double _lastAngle = 0.0;

  _DotComponent() : super(priority: 10);

  void updateState(DotState dot, List<Vector2> trail) {
    _dot = dot;
    _trail = trail;
    _visible = true;
    final vx = dot.vx, vy = dot.vy;
    if (vx * vx + vy * vy > 0.01) {
      _lastAngle = math.atan2(vy, vx);
    }
  }

  void hide() => _visible = false;

  @override
  void render(Canvas canvas) {
    if (!_visible || _dot == null) return;

    // Trail — small fading circles
    final pts = _trail;
    final start = math.max(0, pts.length - 35);
    for (int i = start; i < pts.length; i++) {
      final t = (i - start) / (pts.length - start);
      canvas.drawCircle(
        Offset(pts[i].x, pts[i].y),
        0.8 + t * 1.2,
        Paint()..color = const Color(0xFFAABBDD).withOpacity(t * 0.28),
      );
    }

    final x = _dot!.x, y = _dot!.y;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(_lastAngle);

    // Engine exhaust glow
    canvas.drawCircle(Offset(-5, 0), 5,
        Paint()..color = const Color(0xFF4466FF).withOpacity(0.45));
    canvas.drawCircle(Offset(-5, 0), 3,
        Paint()..color = const Color(0xFFAABBFF).withOpacity(0.75));

    // Wing fins
    final wings = Path()
      ..moveTo(-1, 0)
      ..lineTo(-7, -6)
      ..lineTo(-8, -3.5)
      ..lineTo(-3, 0)
      ..lineTo(-8, 3.5)
      ..lineTo(-7, 6)
      ..close();
    canvas.drawPath(wings, Paint()..color = const Color(0xFF5566AA));

    // Main hull
    final hull = Path()
      ..moveTo(11, 0)
      ..lineTo(-4, -4)
      ..lineTo(-2, 0)
      ..lineTo(-4, 4)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFFCCDDFF));

    // Cockpit shine
    canvas.drawCircle(Offset(4, -1), 2,
        Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.55));

    canvas.restore();
  }
}

// ─── Trajectory ──────────────────────────────────────────────────────────────

class _TrajectoryComponent extends Component {
  List<TrajectoryPoint> _points = [];

  _TrajectoryComponent() : super(priority: 4);

  void setPreview(double vx, double vy, LevelData level) {
    _points = Physics.simulateTrajectory(vx, vy, level);
  }

  void clear() => _points = [];

  @override
  void render(Canvas canvas) {
    for (final pt in _points) {
      final color = pt.isImpact
          ? const Color(0xFFFF4444).withOpacity(pt.alpha)
          : const Color(0xFF88DDFF).withOpacity(pt.alpha);
      canvas.drawCircle(Offset(pt.x, pt.y), pt.size, Paint()..color = color);
    }
  }
}

// ─── Aim Arrow ───────────────────────────────────────────────────────────────

class _AimArrowComponent extends Component {
  bool _active = false;
  Vector2 _start = Vector2.zero();
  Vector2 _current = Vector2.zero();
  Zone? _lz;

  _AimArrowComponent() : super(priority: 5);

  void setDrag(Vector2 start, Vector2 current, Zone lz) {
    _active = true;
    _start = start;
    _current = current;
    _lz = lz;
  }

  void clear() => _active = false;

  @override
  void render(Canvas canvas) {
    if (!_active || _lz == null) return;

    final raw = _current - _start;
    final mag = raw.length;
    if (mag < 2) return;

    final clamped = math.min(mag, Physics.maxDrag);
    final n = raw / mag;

    // Arrow from launch zone center, pointing opposite to drag
    final arrowLen = clamped * 0.7;
    final ex = _lz!.x - n.x * arrowLen;
    final ey = _lz!.y - n.y * arrowLen;

    final shaft = Paint()
      ..color = const Color(0xFF8899CC).withOpacity(0.65)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(_lz!.x, _lz!.y), Offset(ex, ey), shaft);

    // Arrowhead
    final headLen = 10.0;
    final headAng = 0.42;
    final backAngle = math.atan2(n.y, n.x);
    canvas.drawLine(
      Offset(ex, ey),
      Offset(ex + headLen * math.cos(backAngle + headAng),
          ey + headLen * math.sin(backAngle + headAng)),
      shaft,
    );
    canvas.drawLine(
      Offset(ex, ey),
      Offset(ex + headLen * math.cos(backAngle - headAng),
          ey + headLen * math.sin(backAngle - headAng)),
      shaft,
    );

    // Power ring at drag point
    final strength = clamped / Physics.maxDrag;
    canvas.drawCircle(
      Offset(_current.x, _current.y),
      4 + strength * 5,
      Paint()
        ..color = const Color(0xFFAABBDD).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

// ─── Explosion ────────────────────────────────────────────────────────────────

class _ExplosionComponent extends Component {
  final double cx, cy;
  double _t = 0.0; // 0..1
  static const double _duration = 0.55; // seconds

  static final _rng = math.Random();

  // Pre-generated sparks: [angle, speed, size]
  late final List<_Spark> _sparks;

  _ExplosionComponent(this.cx, this.cy) : super(priority: 20) {
    _sparks = List.generate(18, (_) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60 + _rng.nextDouble() * 120;
      final size = 1.5 + _rng.nextDouble() * 2.5;
      return _Spark(angle, speed, size);
    });
  }

  @override
  void update(double dt) {
    _t += dt / _duration;
    if (_t >= 1.0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t >= 1.0) return;
    final t = _t.clamp(0.0, 1.0);

    // 1. Flash: bright white core that fades quickly
    if (t < 0.25) {
      final ft = 1.0 - (t / 0.25);
      canvas.drawCircle(
        Offset(cx, cy), 18 * (1 - t * 0.5),
        Paint()..color = const Color(0xFFFFFFFF).withOpacity(ft * 0.9),
      );
    }

    // 2. Expanding orange-red ring
    final ring1R = 6 + t * 44;
    final ring1A = (1 - t) * 0.85;
    canvas.drawCircle(
      Offset(cx, cy), ring1R,
      Paint()
        ..color = const Color(0xFFFF6622).withOpacity(ring1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1 - t * 0.7),
    );

    // 3. Second ring (delayed, blue-white)
    if (t > 0.1) {
      final t2 = ((t - 0.1) / 0.9).clamp(0.0, 1.0);
      final ring2R = 4 + t2 * 30;
      canvas.drawCircle(
        Offset(cx, cy), ring2R,
        Paint()
          ..color = const Color(0xFFAADDFF).withOpacity((1 - t2) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // 4. Sparks
    for (final spark in _sparks) {
      final dist = spark.speed * t * _duration;
      final sx = cx + math.cos(spark.angle) * dist;
      final sy = cy + math.sin(spark.angle) * dist;
      final alpha = (1 - t) * 0.9;
      final sz = spark.size * (1 - t * 0.6);
      // Color shifts orange → red as t increases
      final r = 255;
      final g = ((1 - t) * 160).round().clamp(0, 255);
      canvas.drawCircle(
        Offset(sx, sy), sz,
        Paint()..color = Color.fromRGBO(r, g, 30, alpha),
      );
    }

    // 5. Central glow that lingers
    canvas.drawCircle(
      Offset(cx, cy), 8 + t * 6,
      Paint()..color = const Color(0xFFFF8833).withOpacity((1 - t) * 0.5),
    );
  }
}

class _Spark {
  final double angle, speed, size;
  _Spark(this.angle, this.speed, this.size);
}
