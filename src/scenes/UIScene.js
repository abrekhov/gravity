import { levels } from '../levels.js';

const W = 1280;
const H = 720;

export default class UIScene extends Phaser.Scene {
  constructor() { super('UIScene'); }

  create() {
    // Dim overlay behind win/fail panels
    this.overlay = this.add.rectangle(W / 2, H / 2, W, H, 0x000814, 0)
      .setDepth(20).setAlpha(0);

    this._buildHUD();
    this._buildOverlays();
    this._listenToGameScene();
  }

  // ─── HUD ───────────────────────────────────────────────────────────────────

  _buildHUD() {
    const levelId   = this.registry.get('currentLevel') ?? 1;
    const levelConf = levels.find(l => l.id === levelId) ?? levels[0];

    // Level label — top-left
    this.add.text(22, 20, `LEVEL ${String(levelId).padStart(2, '0')}`, {
      fontSize: '13px', fontFamily: 'monospace', color: '#5a7090',
    }).setDepth(21);

    this.add.text(22, 38, levelConf.name, {
      fontSize: '16px', fontFamily: 'Arial, sans-serif', color: '#c8d8ea',
    }).setDepth(21);

    // Shot dots — top-right
    const total   = levelConf.shots ?? 3;
    this.shotDots = [];
    const dotR    = 5, spacing = 18;
    for (let i = 0; i < total; i++) {
      const x = W - 20 - (total - 1 - i) * spacing;
      const d = this.add.circle(x, 30, dotR, 0x4466aa, 0.9).setDepth(21);
      this.shotDots.push(d);
    }

    // Aim hint — bottom center, fades after first launch
    this.aimHint = this.add.text(W / 2, H - 30, 'Drag from LAUNCH zone · Release to fire', {
      fontSize: '13px', fontFamily: 'monospace', color: '#3d5570',
    }).setOrigin(0.5, 1).setDepth(21).setAlpha(0.8);

    this.scene.get('GameScene').events.once('dotLaunched', () => {
      this.tweens.add({ targets: this.aimHint, alpha: 0, duration: 800 });
    });
  }

  // ─── Overlays ──────────────────────────────────────────────────────────────

  _buildOverlays() {
    this.winGroup  = this.add.group();
    this.failGroup = this.add.group();
    this._buildWinOverlay();
    this._buildFailOverlay();
    this.winGroup.setVisible(false);
    this.failGroup.setVisible(false);
  }

  _buildWinOverlay() {
    const cx = W / 2, cy = H / 2;

    const bg = this.add.rectangle(cx, cy, 480, 270, 0x060d18, 0.95)
      .setDepth(22).setStrokeStyle(1, 0x2a4060, 1);
    this.winGroup.add(bg);

    const title = this.add.text(cx, cy - 80, 'LEVEL COMPLETE', {
      fontSize: '30px', fontFamily: 'Arial, sans-serif',
      color: '#ffffff',
    }).setOrigin(0.5).setDepth(23);
    this.winGroup.add(title);

    this.winSubtext = this.add.text(cx, cy - 38, '', {
      fontSize: '14px', fontFamily: 'monospace', color: '#6a8aaa',
    }).setOrigin(0.5).setDepth(23);
    this.winGroup.add(this.winSubtext);

    // NEXT LEVEL (primary)
    this.nextBtn = this._makeBtn(cx, cy + 35, 240, 56, 'NEXT LEVEL', true);
    this.winGroup.add(this.nextBtn.bg);
    this.winGroup.add(this.nextBtn.label);
    this.nextBtn.bg.on('pointerup', () => this._goNextLevel());

    // LEVELS (secondary)
    const lvlBtn = this._makeBtn(cx, cy + 104, 140, 40, 'LEVELS', false, 14);
    this.winGroup.add(lvlBtn.bg);
    this.winGroup.add(lvlBtn.label);
    lvlBtn.bg.on('pointerup', () => this._goLevels());
  }

  _buildFailOverlay() {
    const cx = W / 2, cy = H / 2;

    const bg = this.add.rectangle(cx, cy, 420, 240, 0x0c0a0a, 0.95)
      .setDepth(22).setStrokeStyle(1, 0x3a1a1a, 1);
    this.failGroup.add(bg);

    const title = this.add.text(cx, cy - 70, 'MISSION FAILED', {
      fontSize: '28px', fontFamily: 'Arial, sans-serif', color: '#cc4433',
    }).setOrigin(0.5).setDepth(23);
    this.failGroup.add(title);

    const retryBtn = this._makeBtn(cx, cy + 20, 200, 52, 'TRY AGAIN', true);
    this.failGroup.add(retryBtn.bg);
    this.failGroup.add(retryBtn.label);
    retryBtn.bg.on('pointerup', () => this._retry());

    const lvlBtn = this._makeBtn(cx, cy + 84, 140, 40, 'LEVELS', false, 14);
    this.failGroup.add(lvlBtn.bg);
    this.failGroup.add(lvlBtn.label);
    lvlBtn.bg.on('pointerup', () => this._goLevels());
  }

  _makeBtn(x, y, w, h, text, primary = false, fontSize = 17) {
    const fill   = primary ? 0x1a3a5a : 0x0c1a28;
    const border = primary ? 0x3d6fff : 0x2a4060;
    const alpha  = primary ? 0.8 : 0.7;

    const bg = this.add.rectangle(x, y, w, h, fill, alpha)
      .setDepth(23).setStrokeStyle(1.5, border, primary ? 0.9 : 0.6)
      .setInteractive({ useHandCursor: true });

    const label = this.add.text(x, y, text, {
      fontSize: `${fontSize}px`, fontFamily: 'Arial, sans-serif',
      color: primary ? '#ffffff' : '#6a8aaa',
    }).setOrigin(0.5).setDepth(24);

    bg.on('pointerover',  () => bg.setFillStyle(fill, 1));
    bg.on('pointerout',   () => bg.setFillStyle(fill, alpha));
    bg.on('pointerdown',  () => bg.setFillStyle(primary ? 0x2a5080 : 0x162030, 1));

    return { bg, label };
  }

  // ─── Event wiring ──────────────────────────────────────────────────────────

  _listenToGameScene() {
    const game = this.scene.get('GameScene');
    game.events.on('levelWon',    this._onWin,      this);
    game.events.on('levelFailed', this._onFail,     this);
    game.events.on('shotUsed',    this._onShotUsed, this);
  }

  _onShotUsed(remaining) {
    const idx = this.shotDots.length - remaining - 1;
    if (this.shotDots[idx]) {
      this.tweens.add({ targets: this.shotDots[idx], alpha: 0.12, duration: 220 });
    }
  }

  _onWin(levelId) {
    const nextId = levelId + 1;
    const isLast = nextId > levels.length;
    this.winSubtext.setText(isLast ? 'All levels complete!' : `Level ${nextId} unlocked`);
    if (isLast) {
      this.nextBtn.label.setText('PLAY AGAIN');
    }

    this._fadeInOverlay();
    // Delay buttons to prevent phantom taps from the winning gesture
    this.time.delayedCall(550, () => {
      this.winGroup.setVisible(true);
    });
  }

  _onFail() {
    this.shotDots.forEach(d =>
      this.tweens.add({ targets: d, alpha: 0.12, duration: 220 }),
    );
    this._fadeInOverlay();
    this.time.delayedCall(300, () => {
      this.failGroup.setVisible(true);
    });
  }

  _fadeInOverlay() {
    this.tweens.add({ targets: this.overlay, alpha: 0.7, duration: 280 });
  }

  _fadeOutOverlay() {
    this.tweens.add({ targets: this.overlay, alpha: 0, duration: 180 });
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  _retry() {
    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.failGroup.setVisible(false);
    this.scene.stop('UIScene');
    this.scene.restart('GameScene');
    this.scene.launch('UIScene');
  }

  _goNextLevel() {
    const levelId = this.registry.get('currentLevel') ?? 1;
    const nextId  = levelId + 1;
    this.registry.set('currentLevel', nextId > levels.length ? 1 : nextId);
    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.scene.stop('UIScene');
    this.scene.start('GameScene');
    this.scene.launch('UIScene');
  }

  _goLevels() {
    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.failGroup.setVisible(false);
    this.registry.set('menuTarget', 'levels');
    this.scene.stop('UIScene');
    this.scene.stop('GameScene');
    this.scene.start('MenuScene');
  }
}
