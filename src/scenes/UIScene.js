import { levels } from '../levels.js';

const W = 1280;
const H = 720;

export default class UIScene extends Phaser.Scene {
  constructor() { super('UIScene'); }

  create() {
    this.attempts = 0;

    // Semi-transparent overlay (hidden by default, shown on win/fail)
    this.overlay = this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0)
      .setDepth(20).setAlpha(0);

    this._buildHUD();
    this._buildOverlays();
    this._listenToGameScene();
  }

  // ─── HUD ───────────────────────────────────────────────────────────────────

  _buildHUD() {
    const levelId   = this.registry.get('currentLevel') ?? 1;
    const levelConf = levels.find(l => l.id === levelId) ?? levels[0];

    this.levelText = this.add.text(24, 18, `LEVEL ${levelId}  ·  ${levelConf.name}`, {
      fontSize: '18px',
      fontFamily: 'monospace',
      color: '#ffffff',
      alpha: 0.85,
    }).setDepth(21);

    this.attemptsText = this.add.text(W - 24, 18, 'ATTEMPT 1', {
      fontSize: '16px',
      fontFamily: 'monospace',
      color: '#aaaaaa',
    }).setOrigin(1, 0).setDepth(21);

    // Aim hint — fades out after first launch
    this.aimHint = this.add.text(W / 2, H - 38, 'Drag from the LAUNCH zone to aim · Release to fire', {
      fontSize: '15px',
      fontFamily: 'monospace',
      color: '#00ffee',
      alpha: 0.7,
    }).setOrigin(0.5, 1).setDepth(21);

    // Hide hint when dot is launched
    const game = this.scene.get('GameScene');
    game.events.once('dotLaunched', () => {
      this.tweens.add({ targets: this.aimHint, alpha: 0, duration: 600 });
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
    const cx = W / 2;
    const cy = H / 2;

    const bg = this.add.rectangle(cx, cy, 520, 260, 0x000022, 0.88)
      .setDepth(22).setStrokeStyle(2, 0xff00ff, 0.9);
    this.winGroup.add(bg);

    const title = this.add.text(cx, cy - 70, 'WARP ACHIEVED', {
      fontSize: '36px',
      fontFamily: 'monospace',
      color: '#ff00ff',
      stroke: '#ffffff',
      strokeThickness: 1,
    }).setOrigin(0.5).setDepth(23);
    this.winGroup.add(title);

    this.winSubtext = this.add.text(cx, cy - 20, '', {
      fontSize: '16px',
      fontFamily: 'monospace',
      color: '#aaaaff',
    }).setOrigin(0.5).setDepth(23);
    this.winGroup.add(this.winSubtext);

    // Next Level button
    this.nextBtn = this._makeButton(cx, cy + 55, 'NEXT LEVEL', 0xff00ff, () => {
      this._goNextLevel();
    });
    this.winGroup.add(this.nextBtn.bg);
    this.winGroup.add(this.nextBtn.label);

    // Menu button (small)
    const menuBtnWin = this._makeButton(cx, cy + 115, 'MENU', 0x555588, () => {
      this._goMenu();
    }, true);
    this.winGroup.add(menuBtnWin.bg);
    this.winGroup.add(menuBtnWin.label);
  }

  _buildFailOverlay() {
    const cx = W / 2;
    const cy = H / 2;

    const bg = this.add.rectangle(cx, cy, 460, 230, 0x220000, 0.88)
      .setDepth(22).setStrokeStyle(2, 0xff4444, 0.9);
    this.failGroup.add(bg);

    const title = this.add.text(cx, cy - 60, 'LOST IN SPACE', {
      fontSize: '34px',
      fontFamily: 'monospace',
      color: '#ff4444',
    }).setOrigin(0.5).setDepth(23);
    this.failGroup.add(title);

    // Retry button
    this.retryBtn = this._makeButton(cx, cy + 30, 'TRY AGAIN', 0xff4444, () => {
      this._retry();
    });
    this.failGroup.add(this.retryBtn.bg);
    this.failGroup.add(this.retryBtn.label);

    // Menu button (small)
    const menuBtnFail = this._makeButton(cx, cy + 95, 'MENU', 0x555555, () => {
      this._goMenu();
    }, true);
    this.failGroup.add(menuBtnFail.bg);
    this.failGroup.add(menuBtnFail.label);
  }

  _makeButton(x, y, text, color, callback, small = false) {
    const w = small ? 160 : 260;
    const h = small ? 44  : 60;
    const fontSize = small ? '16px' : '22px';

    const bg = this.add.rectangle(x, y, w, h, color, 0.25)
      .setDepth(23)
      .setStrokeStyle(2, color, 0.9)
      .setInteractive({ useHandCursor: true });

    const label = this.add.text(x, y, text, {
      fontSize,
      fontFamily: 'monospace',
      color: '#ffffff',
    }).setOrigin(0.5).setDepth(24);

    bg.on('pointerover',  () => bg.setFillStyle(color, 0.5));
    bg.on('pointerout',   () => bg.setFillStyle(color, 0.25));
    bg.on('pointerdown',  () => bg.setFillStyle(color, 0.8));
    bg.on('pointerup',    callback);

    return { bg, label };
  }

  // ─── Event wiring ──────────────────────────────────────────────────────────

  _listenToGameScene() {
    const game = this.scene.get('GameScene');
    game.events.on('levelWon',    this._onWin,  this);
    game.events.on('levelFailed', this._onFail, this);
  }

  _onWin(levelId) {
    const nextId = levelId + 1;
    const isLast = nextId > levels.length;
    this.winSubtext.setText(isLast ? 'All levels complete!' : `Level ${nextId} unlocked`);

    if (isLast) {
      this.nextBtn.label.setText('PLAY AGAIN');
      this.nextBtn.bg.setStrokeStyle(2, 0xffff00, 0.9);
    }

    this._fadeInOverlay();
    this.winGroup.setVisible(true);
  }

  _onFail() {
    this.attempts++;
    this.attemptsText.setText(`ATTEMPT ${this.attempts + 1}`);
    this._fadeInOverlay();
    this.failGroup.setVisible(true);
  }

  _fadeInOverlay() {
    this.tweens.add({ targets: this.overlay, alpha: 0.55, duration: 300 });
  }

  _fadeOutOverlay() {
    this.tweens.add({ targets: this.overlay, alpha: 0, duration: 200 });
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  _retry() {
    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.failGroup.setVisible(false);
    this.scene.stop('UIScene');
    this.scene.restart('GameScene');
  }

  _goNextLevel() {
    const levelId = this.registry.get('currentLevel') ?? 1;
    const nextId  = levelId + 1;

    if (nextId > levels.length) {
      // Beat all levels → go back to level 1
      this.registry.set('currentLevel', 1);
    } else {
      this.registry.set('currentLevel', nextId);
    }

    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.scene.stop('UIScene');
    this.scene.start('GameScene');
    this.scene.launch('UIScene');
  }

  _goMenu() {
    this._fadeOutOverlay();
    this.winGroup.setVisible(false);
    this.failGroup.setVisible(false);
    this.scene.stop('UIScene');
    this.scene.stop('GameScene');
    this.scene.start('MenuScene');
  }
}
