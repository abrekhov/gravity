import { levels } from '../levels.js';

const W = 1280;
const H = 720;
const MAX_DRAG        = 160;   // pixels the player can drag back
const VELOCITY_SCALE  = 3.2;   // maps drag distance → launch speed (reduced so gravity has time to act)
const GRAVITY_SCALE   = 100;   // multiplier so level G values (80-150) produce strong curves
const PREVIEW_STEPS   = 220;   // trajectory preview simulation steps
const PREVIEW_DT      = 1 / 60;
const MIN_LAUNCH_MAG  = 6;     // ignore taps shorter than this

export default class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  create() {
    const levelId = this.registry.get('currentLevel') ?? 1;
    this.levelConfig = levels.find(l => l.id === levelId) ?? levels[0];

    this.phase          = 'aiming';   // 'aiming' | 'flying' | 'dead' | 'won'
    this.dot            = null;       // { x, y, vx, vy }
    this.isDragging     = false;
    this.dragStart      = { x: 0, y: 0 };
    this.shotsRemaining = this.levelConfig.shots ?? 3;

    this._buildStarfield();
    this._buildGravityBodies();
    this._buildLaunchZone();
    this._buildGateway();
    this._buildDotSprite();
    this._buildTrail();
    this._buildGraphicsLayers();
    this._setupInput();
    this._startGatewayAnim();
    this._pulseLaunchZone();
  }

  update(_time, delta) {
    if (this.phase !== 'flying') return;

    const dt = Math.min(delta / 1000, 0.05);
    this._stepPhysics(dt);
    this._checkCollisions();
  }

  // ─── Scene building ────────────────────────────────────────────────────────

  _buildStarfield() {
    const g = this.add.graphics();
    const rng = new Phaser.Math.RandomDataGenerator(['gravity-stars']);
    for (let i = 0; i < 180; i++) {
      const x = rng.between(0, W);
      const y = rng.between(0, H);
      const r = rng.frac() < 0.3 ? 1.5 : 1;
      const a = rng.realInRange(0.3, 1.0);
      g.fillStyle(0xffffff, a);
      g.fillCircle(x, y, r);
    }
  }

  _buildGravityBodies() {
    this.bodyGraphics = this.add.graphics();
    for (const body of this.levelConfig.gravityBodies) {
      this._drawGlowPlanet(this.bodyGraphics, body.x, body.y, body.radius, body.color);
    }
  }

  _drawGlowPlanet(g, x, y, radius, color) {
    // Outer glow layers
    for (let i = 5; i >= 1; i--) {
      const r = radius + i * 7;
      const a = 0.06 * (6 - i);
      g.fillStyle(color, a);
      g.fillCircle(x, y, r);
    }
    // Core
    g.fillStyle(color, 1.0);
    g.fillCircle(x, y, radius);
    // Highlight
    g.fillStyle(0xffffff, 0.25);
    g.fillCircle(x - radius * 0.3, y - radius * 0.3, radius * 0.35);
  }

  _buildLaunchZone() {
    const lz = this.levelConfig.launchZone;
    this.launchZoneGfx = this.add.graphics();
    this._drawLaunchZone(1.0);
    // "LAUNCH" label
    this.add.text(lz.x, lz.y + lz.radius + 18, 'LAUNCH', {
      fontSize: '14px',
      fontFamily: 'monospace',
      color: '#00ffee',
      alpha: 0.7,
    }).setOrigin(0.5, 0);
  }

  _drawLaunchZone(alpha) {
    const lz = this.levelConfig.launchZone;
    this.launchZoneGfx.clear();
    // Outer ring
    this.launchZoneGfx.lineStyle(2, 0x00ffee, 0.6 * alpha);
    this.launchZoneGfx.strokeCircle(lz.x, lz.y, lz.radius);
    // Inner fill
    this.launchZoneGfx.fillStyle(0x00ffee, 0.08 * alpha);
    this.launchZoneGfx.fillCircle(lz.x, lz.y, lz.radius);
    // Cross-hair
    this.launchZoneGfx.lineStyle(1, 0x00ffee, 0.4 * alpha);
    this.launchZoneGfx.lineBetween(lz.x - lz.radius * 0.5, lz.y, lz.x + lz.radius * 0.5, lz.y);
    this.launchZoneGfx.lineBetween(lz.x, lz.y - lz.radius * 0.5, lz.x, lz.y + lz.radius * 0.5);
  }

  _pulseLaunchZone() {
    const tgt = { v: 1 };
    this.tweens.add({
      targets: tgt,
      v: 0.4,
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
      onUpdate: () => {
        if (this.phase === 'aiming') this._drawLaunchZone(tgt.v + 0.4);
      },
    });
  }

  _buildGateway() {
    this.gatewayGfx = this.add.graphics();
    // "WARP" label
    const gw = this.levelConfig.gateway;
    this.add.text(gw.x, gw.y + gw.radius + 14, 'WARP', {
      fontSize: '13px',
      fontFamily: 'monospace',
      color: '#ff00ff',
      alpha: 0.8,
    }).setOrigin(0.5, 0);
  }

  _startGatewayAnim() {
    this.time.addEvent({
      delay: 16,
      loop: true,
      callback: () => this._drawGateway(this.time.now),
    });
  }

  _drawGateway(t) {
    const gw = this.levelConfig.gateway;
    this.gatewayGfx.clear();

    // Outer halo
    this.gatewayGfx.fillStyle(0xff00ff, 0.05);
    this.gatewayGfx.fillCircle(gw.x, gw.y, gw.radius * 2.2);

    // Expanding rings
    for (let i = 0; i < 4; i++) {
      const phase = ((t / 1400) + i * 0.25) % 1;
      const r     = gw.radius * 0.3 + gw.radius * 1.4 * phase;
      const alpha = (1 - phase) * 0.75;
      this.gatewayGfx.lineStyle(2, 0xff00ff, alpha);
      this.gatewayGfx.strokeCircle(gw.x, gw.y, r);
    }

    // Rotating spokes
    const angle = (t / 1000) * Math.PI;
    for (let i = 0; i < 6; i++) {
      const a = angle + (i / 6) * Math.PI * 2;
      const x1 = gw.x + Math.cos(a) * gw.radius * 0.25;
      const y1 = gw.y + Math.sin(a) * gw.radius * 0.25;
      const x2 = gw.x + Math.cos(a) * gw.radius * 0.85;
      const y2 = gw.y + Math.sin(a) * gw.radius * 0.85;
      this.gatewayGfx.lineStyle(1, 0xffffff, 0.4);
      this.gatewayGfx.lineBetween(x1, y1, x2, y2);
    }

    // Inner core
    this.gatewayGfx.fillStyle(0xff00ff, 0.9);
    this.gatewayGfx.fillCircle(gw.x, gw.y, 5);
    this.gatewayGfx.fillStyle(0xffffff, 0.6);
    this.gatewayGfx.fillCircle(gw.x, gw.y, 3);
  }

  _buildDotSprite() {
    this.dotGfx = this.add.graphics();
    this._dotVisible = false;
  }

  _buildTrail() {
    this.trailPoints = [];
  }

  _buildGraphicsLayers() {
    this.trajectoryGfx = this.add.graphics();
    this.aimGfx        = this.add.graphics();
    // dot drawn on top
    this.dotGfx.setDepth(10);
    this.trajectoryGfx.setDepth(5);
    this.aimGfx.setDepth(6);
  }

  // ─── Input ─────────────────────────────────────────────────────────────────

  _setupInput() {
    this.input.on('pointerdown',  this._onPointerDown,  this);
    this.input.on('pointermove',  this._onPointerMove,  this);
    this.input.on('pointerup',    this._onPointerUp,    this);
  }

  _onPointerDown(ptr) {
    if (this.phase !== 'aiming') return;
    const lz   = this.levelConfig.launchZone;
    const dist = Phaser.Math.Distance.Between(ptr.x, ptr.y, lz.x, lz.y);
    // Be generous on touch: 1.5x the visual radius
    if (dist > lz.radius * 1.5) return;
    this.isDragging = true;
    this.dragStart  = { x: ptr.x, y: ptr.y };
  }

  _onPointerMove(ptr) {
    if (!this.isDragging) return;
    const { vx, vy } = this._dragToVelocity(ptr);
    this._redrawTrajectory(vx, vy);
    this._redrawAimArrow(ptr);
  }

  _onPointerUp(ptr) {
    if (!this.isDragging) return;
    this.isDragging = false;
    this.trajectoryGfx.clear();
    this.aimGfx.clear();

    const raw = { x: ptr.x - this.dragStart.x, y: ptr.y - this.dragStart.y };
    const mag = Math.sqrt(raw.x * raw.x + raw.y * raw.y);
    if (mag < MIN_LAUNCH_MAG) return;

    const { vx, vy } = this._dragToVelocity(ptr);
    this._launch(vx, vy);
  }

  _dragToVelocity(ptr) {
    const raw = { x: ptr.x - this.dragStart.x, y: ptr.y - this.dragStart.y };
    const mag = Math.sqrt(raw.x * raw.x + raw.y * raw.y);
    if (mag < 0.001) return { vx: 0, vy: 0 };
    const clamped = Math.min(mag, MAX_DRAG);
    const nx = raw.x / mag;
    const ny = raw.y / mag;
    // Flip: drag back → shoot forward
    return {
      vx: -nx * clamped * VELOCITY_SCALE,
      vy: -ny * clamped * VELOCITY_SCALE,
    };
  }

  // ─── Launch & Physics ──────────────────────────────────────────────────────

  _launch(vx, vy) {
    const lz = this.levelConfig.launchZone;
    this.dot = { x: lz.x, y: lz.y, vx, vy };
    this.phase = 'flying';
    this._dotVisible = true;
    this.trailPoints = [];

    // Hide launch zone
    this.launchZoneGfx.setAlpha(0.3);

    this.events.emit('dotLaunched');
  }

  _stepPhysics(dt) {
    const { G, gravityBodies } = this.levelConfig;
    let ax = 0, ay = 0;

    for (const body of gravityBodies) {
      const dx = body.x - this.dot.x;
      const dy = body.y - this.dot.y;
      const r2 = dx * dx + dy * dy;
      const r  = Math.sqrt(r2);
      const softR = Math.max(r, body.radius * 0.5);
      const acc = GRAVITY_SCALE * G * body.mass / (softR * softR);
      ax += acc * (dx / r);
      ay += acc * (dy / r);
    }

    this.dot.vx += ax * dt;
    this.dot.vy += ay * dt;
    this.dot.x  += this.dot.vx * dt;
    this.dot.y  += this.dot.vy * dt;

    // Update trail
    this.trailPoints.push({ x: this.dot.x, y: this.dot.y });
    if (this.trailPoints.length > 60) this.trailPoints.shift();

    this._redrawDot();
  }

  _redrawDot() {
    this.dotGfx.clear();
    if (!this._dotVisible) return;

    // Draw trail
    const pts = this.trailPoints;
    for (let i = 1; i < pts.length; i++) {
      const alpha = (i / pts.length) * 0.55;
      const size  = 2 + (i / pts.length) * 2;
      this.dotGfx.fillStyle(0x88ddff, alpha);
      this.dotGfx.fillCircle(pts[i].x, pts[i].y, size);
    }

    // Draw dot
    const x = this.dot.x;
    const y = this.dot.y;
    this.dotGfx.fillStyle(0x88ddff, 0.35);
    this.dotGfx.fillCircle(x, y, 10);
    this.dotGfx.fillStyle(0xffffff, 1);
    this.dotGfx.fillCircle(x, y, 5);
    this.dotGfx.fillStyle(0x88ddff, 0.8);
    this.dotGfx.fillCircle(x - 2, y - 2, 2);
  }

  // ─── Collision Detection ───────────────────────────────────────────────────

  _checkCollisions() {
    const { gravityBodies, gateway } = this.levelConfig;
    const { x, y } = this.dot;

    // Gateway win
    const dGW = Phaser.Math.Distance.Between(x, y, gateway.x, gateway.y);
    if (dGW < gateway.radius) {
      this._triggerWin();
      return;
    }

    // Hit a planet
    for (const body of gravityBodies) {
      const d = Phaser.Math.Distance.Between(x, y, body.x, body.y);
      if (d < body.radius * 1.05) {
        this._triggerFail();
        return;
      }
    }

    // Out of bounds
    const PAD = 120;
    if (x < -PAD || x > W + PAD || y < -PAD || y > H + PAD) {
      this._triggerFail();
    }
  }

  // ─── Win / Fail ────────────────────────────────────────────────────────────

  _triggerWin() {
    if (this.phase === 'won') return;
    this.phase = 'won';

    // Flash and warp the dot into the gateway
    this.tweens.add({
      targets: this.dot,
      x: this.levelConfig.gateway.x,
      y: this.levelConfig.gateway.y,
      duration: 300,
      ease: 'Cubic.easeIn',
      onUpdate: () => this._redrawDot(),
      onComplete: () => {
        this._dotVisible = false;
        this.dotGfx.clear();
      },
    });

    this.cameras.main.flash(400, 255, 0, 255, false);

    // Unlock next level
    const nextId = this.levelConfig.id + 1;
    const unlocked = parseInt(localStorage.getItem('gravity_unlocked') ?? '1', 10);
    if (nextId > unlocked) {
      localStorage.setItem('gravity_unlocked', String(nextId));
    }

    this.time.delayedCall(350, () => {
      this.events.emit('levelWon', this.levelConfig.id);
    });
  }

  _triggerFail() {
    if (this.phase === 'dead') return;
    this.phase = 'dead';
    this._dotVisible = false;
    this.dotGfx.clear();
    this.cameras.main.shake(220, 0.012);
    this.cameras.main.flash(180, 255, 40, 40, false);

    this.time.delayedCall(420, () => {
      this.shotsRemaining--;
      if (this.shotsRemaining <= 0) {
        this.events.emit('levelFailed');
      } else {
        this.events.emit('shotUsed', this.shotsRemaining);
        this._resetToAiming();
      }
    });
  }

  _resetToAiming() {
    this.phase = 'aiming';
    this.dot = null;
    this._dotVisible = false;
    this.trailPoints = [];
    this.launchZoneGfx.setAlpha(1);
  }

  // ─── Trajectory Preview ────────────────────────────────────────────────────

  _redrawTrajectory(launchVx, launchVy) {
    this.trajectoryGfx.clear();
    const { G, gravityBodies, launchZone } = this.levelConfig;

    let px = launchZone.x;
    let py = launchZone.y;
    let vx = launchVx;
    let vy = launchVy;

    for (let i = 0; i < PREVIEW_STEPS; i++) {
      let ax = 0, ay = 0;

      for (const body of gravityBodies) {
        const dx = body.x - px;
        const dy = body.y - py;
        const r2 = dx * dx + dy * dy;
        const r  = Math.sqrt(r2);
        if (r < body.radius) {
          // Predicted impact
          this.trajectoryGfx.fillStyle(0xff4444, 0.8);
          this.trajectoryGfx.fillCircle(px, py, 4);
          return;
        }
        const acc = GRAVITY_SCALE * G * body.mass / r2;
        ax += acc * (dx / r);
        ay += acc * (dy / r);
      }

      vx += ax * PREVIEW_DT;
      vy += ay * PREVIEW_DT;
      px += vx * PREVIEW_DT;
      py += vy * PREVIEW_DT;

      if (px < -120 || px > W + 120 || py < -120 || py > H + 120) break;

      // Draw every 3rd step for dashed look
      if (i % 3 === 0) {
        const alpha = Phaser.Math.Linear(0.75, 0.08, i / PREVIEW_STEPS);
        const size  = Phaser.Math.Linear(3.5, 1.5, i / PREVIEW_STEPS);
        this.trajectoryGfx.fillStyle(0x88ddff, alpha);
        this.trajectoryGfx.fillCircle(px, py, size);
      }
    }
  }

  _redrawAimArrow(ptr) {
    this.aimGfx.clear();
    const lz  = this.levelConfig.launchZone;
    const raw = { x: ptr.x - this.dragStart.x, y: ptr.y - this.dragStart.y };
    const mag = Math.sqrt(raw.x * raw.x + raw.y * raw.y);
    if (mag < 2) return;

    const clamped = Math.min(mag, MAX_DRAG);
    const nx = raw.x / mag;
    const ny = raw.y / mag;

    // Arrow points opposite to drag (shows launch direction)
    const arrowLen = clamped * 0.7;
    const ex = lz.x - nx * arrowLen;
    const ey = lz.y - ny * arrowLen;

    // Shaft
    this.aimGfx.lineStyle(2, 0x00ffee, 0.8);
    this.aimGfx.lineBetween(lz.x, lz.y, ex, ey);

    // Arrowhead
    const headLen = 12;
    const headAng = 0.45;
    const backAngle = Math.atan2(ny, nx);  // points back (from arrow tip toward origin)
    this.aimGfx.lineStyle(2, 0x00ffee, 0.8);
    this.aimGfx.lineBetween(
      ex, ey,
      ex + headLen * Math.cos(backAngle + headAng),
      ey + headLen * Math.sin(backAngle + headAng),
    );
    this.aimGfx.lineBetween(
      ex, ey,
      ex + headLen * Math.cos(backAngle - headAng),
      ey + headLen * Math.sin(backAngle - headAng),
    );

    // Power indicator dot on drag point
    const strength = clamped / MAX_DRAG;
    const dotColor = Phaser.Display.Color.Interpolate.ColorWithColor(
      Phaser.Display.Color.ValueToColor(0x00ffee),
      Phaser.Display.Color.ValueToColor(0xff4444),
      100,
      Math.round(strength * 100),
    );
    this.aimGfx.fillStyle(
      Phaser.Display.Color.GetColor(dotColor.r, dotColor.g, dotColor.b),
      0.9,
    );
    this.aimGfx.fillCircle(ptr.x, ptr.y, 6);
  }
}
