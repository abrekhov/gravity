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

  /// One Euler integration step — matches GameScene._stepPhysics exactly.
  static void step(DotState dot, LevelData level, double dt) {
    double ax = 0, ay = 0;
    for (final body in level.gravityBodies) {
      final dx = body.x - dot.x;
      final dy = body.y - dot.y;
      final r = math.sqrt(dx * dx + dy * dy);
      final softR = math.max(r, body.radius * 0.5);
      final acc =
          gravityScale * level.g * body.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }
    dot.vx += ax * dt;
    dot.vy += ay * dt;
    dot.x += dot.vx * dt;
    dot.y += dot.vy * dt;
  }

  /// Simulate a trajectory preview — matches GameScene._redrawTrajectory.
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

      vx += ax * _previewDt;
      vy += ay * _previewDt;
      px += vx * _previewDt;
      py += vy * _previewDt;

      if (px < -120 || px > 1400 || py < -120 || py > 840) break;

      if (i % 3 == 0) {
        final t = i / _previewSteps;
        final alpha = 0.72 + (0.08 - 0.72) * t;
        final size = 3.5 + (1.5 - 3.5) * t;
        points.add(TrajectoryPoint(px, py, size, alpha));
      }
    }
    return points;
  }
}
