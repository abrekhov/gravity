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
  static const double _previewDt = 1.0 / 60.0;
  static const int _previewSteps = 220;

  // Dot collision radius used for wall reflection
  static const double _dotRadius = 5.0;

  /// One Euler integration step.
  static void step(DotState dot, LevelData level, double dt) {
    double ax = 0, ay = 0;

    for (final body in level.gravityBodies) {
      final dx = body.x - dot.x;
      final dy = body.y - dot.y;
      final r = math.sqrt(dx * dx + dy * dy);
      final softR = math.max(r, body.radius * 0.5);
      final acc = gravityScale * level.g * body.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }

    for (final bh in level.blackHoles) {
      final dx = bh.x - dot.x;
      final dy = bh.y - dot.y;
      final r = math.sqrt(dx * dx + dy * dy);
      final softR = math.max(r, bh.radius * 0.5);
      final acc = gravityScale * level.g * bh.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }

    dot.vx += ax * dt;
    dot.vy += ay * dt;
    dot.x += dot.vx * dt;
    dot.y += dot.vy * dt;

    for (final wall in level.walls) {
      _reflectWall(dot, wall);
    }
  }

  /// Simulate a trajectory preview.
  static List<TrajectoryPoint> simulateTrajectory(
      double launchVx, double launchVy, LevelData level) {
    final points = <TrajectoryPoint>[];
    double px = level.launchZone.x;
    double py = level.launchZone.y;
    double vx = launchVx, vy = launchVy;

    for (int i = 0; i < _previewSteps; i++) {
      double ax = 0, ay = 0;

      for (final body in level.gravityBodies) {
        final dx = body.x - px;
        final dy = body.y - py;
        final r = math.sqrt(dx * dx + dy * dy);
        if (r < body.radius) {
          points.add(TrajectoryPoint(px, py, 4, 0.8, isImpact: true));
          return points;
        }
        final acc = gravityScale * level.g * body.mass / (r * r);
        ax += acc * (dx / r);
        ay += acc * (dy / r);
      }

      for (final bh in level.blackHoles) {
        final dx = bh.x - px;
        final dy = bh.y - py;
        final r = math.sqrt(dx * dx + dy * dy);
        if (r < bh.radius) {
          points.add(TrajectoryPoint(px, py, 4, 0.8, isImpact: true));
          return points;
        }
        final acc = gravityScale * level.g * bh.mass / (r * r);
        ax += acc * (dx / r);
        ay += acc * (dy / r);
      }

      vx += ax * _previewDt;
      vy += ay * _previewDt;
      px += vx * _previewDt;
      py += vy * _previewDt;

      // Reflect off walls in the preview
      final tmp = DotState(px, py, vx, vy);
      for (final wall in level.walls) {
        _reflectWall(tmp, wall);
      }
      px = tmp.x; py = tmp.y; vx = tmp.vx; vy = tmp.vy;

      if (px < -120 || px > 2680 || py < -120 || py > 840) break;

      if (i % 3 == 0) {
        final t = i / _previewSteps;
        final alpha = 0.72 + (0.08 - 0.72) * t;
        final size = 3.5 + (1.5 - 3.5) * t;
        points.add(TrajectoryPoint(px, py, size, alpha));
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
