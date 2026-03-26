import 'dart:math' as math;
import 'level_data.dart';

class DotState {
  double x, y, vx, vy;
  DotState(this.x, this.y, this.vx, this.vy);
}

class TrajectoryPoint {
  final double x, y, size, alpha;
  final bool isImpact;
  const TrajectoryPoint(this.x, this.y, this.size, this.alpha,
      {this.isImpact = false});
}

class Physics {
  static const double gravityScale = 100.0;
  static const double velocityScale = 3.2;
  static const double maxDrag = 160.0;
  static const double minLaunchMag = 6.0;
  /// Fixed physics timestep — shared by game loop and trajectory preview so
  /// the preview exactly predicts the actual shot at any display refresh rate.
  static const double fixedDt = 1.0 / 60.0;
  static const double _previewDt = fixedDt;
  static const int _previewSteps = 220;

  // Dot collision radius used for wall reflection
  static const double _dotRadius = 5.0;

  /// One integration step (single Euler, matches _previewDt exactly).
  static void step(DotState dot, LevelData level, double dt) {
    _applyGravity(dot, level, dt);
    for (final wall in level.walls) {
      _reflectWall(dot, wall);
    }
  }

  /// Compute gravity from all bodies & black holes and integrate.
  static void _applyGravity(DotState dot, LevelData level, double dt) {
    double ax = 0, ay = 0;

    for (final body in level.gravityBodies) {
      final dx = body.x - dot.x;
      final dy = body.y - dot.y;
      final r = math.sqrt(dx * dx + dy * dy);
      if (r < 0.001) continue;
      // softR prevents singularity if dot passes inside body
      final softR = math.max(r, body.radius * 0.5);
      final acc = gravityScale * level.g * body.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }

    for (final bh in level.blackHoles) {
      final dx = bh.x - dot.x;
      final dy = bh.y - dot.y;
      final r = math.sqrt(dx * dx + dy * dy);
      if (r < 0.001) continue;
      // Black holes have extreme mass; cap near-field gravity so single-step
      // Euler stays numerically stable. softR = 8*radius keeps Δx < 10px/frame
      // at minimum approach distance (r = radius * 1.1).
      final softR = math.max(r, bh.radius * 8.0);
      final acc = gravityScale * level.g * bh.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }

    dot.vx += ax * dt;
    dot.vy += ay * dt;
    dot.x += dot.vx * dt;
    dot.y += dot.vy * dt;
  }

  /// Simulate a trajectory preview — mirrors step() then _checkCollisions() exactly.
  static List<TrajectoryPoint> simulateTrajectory(
      double launchVx, double launchVy, LevelData level) {
    final points = <TrajectoryPoint>[];
    final sim = DotState(level.launchZone.x, level.launchZone.y, launchVx, launchVy);

    for (int i = 0; i < _previewSteps; i++) {
      // 1. Gravity + integrate — identical to step()
      _applyGravity(sim, level, _previewDt);

      // 2. Wall reflection — matches step()
      for (final wall in level.walls) {
        _reflectWall(sim, wall);
      }

      // 3. Collision — same thresholds as _checkCollisions()
      bool hit = false;
      for (final body in level.gravityBodies) {
        final dx = body.x - sim.x, dy = body.y - sim.y;
        if (dx * dx + dy * dy < (body.radius * 1.05) * (body.radius * 1.05)) {
          hit = true;
          break;
        }
      }
      if (!hit) {
        for (final bh in level.blackHoles) {
          final dx = bh.x - sim.x, dy = bh.y - sim.y;
          if (dx * dx + dy * dy < (bh.radius * 1.1) * (bh.radius * 1.1)) {
            hit = true;
            break;
          }
        }
      }
      if (hit) {
        points.add(TrajectoryPoint(sim.x, sim.y, 4, 0.8, isImpact: true));
        return points;
      }

      // 4. Out of bounds
      if (sim.x < -120 || sim.x > 2680 || sim.y < -120 || sim.y > 840) break;

      // 5. Record point
      if (i % 3 == 0) {
        final t = i / _previewSteps;
        final alpha = 0.72 + (0.08 - 0.72) * t;
        final size = 3.5 + (1.5 - 3.5) * t;
        points.add(TrajectoryPoint(sim.x, sim.y, size, alpha));
      }
    }
    return points;
  }

  /// Reflect the dot off a wall segment if it is within collision distance.
  static void _reflectWall(DotState dot, Wall w) {
    final abx = w.x2 - w.x1, aby = w.y2 - w.y1;
    final ab2 = abx * abx + aby * aby;
    if (ab2 < 0.001) return;

    final t = ((dot.x - w.x1) * abx + (dot.y - w.y1) * aby) / ab2;
    final tc = t.clamp(0.0, 1.0);
    final cx = w.x1 + tc * abx;
    final cy = w.y1 + tc * aby;

    final dx = dot.x - cx;
    final dy = dot.y - cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final hitDist = w.thickness / 2 + _dotRadius;

    if (dist < hitDist && dist > 0.001) {
      final nx = dx / dist;
      final ny = dy / dist;
      final vDotN = dot.vx * nx + dot.vy * ny;
      if (vDotN < 0) {
        dot.vx -= 2 * vDotN * nx;
        dot.vy -= 2 * vDotN * ny;
      }
      // Nudge outside the wall
      dot.x = cx + nx * (hitDist + 1);
      dot.y = cy + ny * (hitDist + 1);
    }
  }
}
