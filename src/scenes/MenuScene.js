import { levels } from '../levels.js';

const W = 1280;
const H = 720;

export default class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create() {
    this._buildStarfield();
    this._buildTitle();
    this._buildLevelGrid();
    this._buildFooter();
  }

  // ─── Starfield ─────────────────────────────────────────────────────────────

  _buildStarfield() {
    const g   = this.add.graphics();
    const rng = new Phaser.Math.RandomDataGenerator(['menu-stars']);

    // Static dim stars
    for (let i = 0; i < 200; i++) {
      const x = rng.between(0, W);
      const y = rng.between(0, H);
      const r = rng.frac() < 0.25 ? 1.5 : 1;
      const a = rng.realInRange(0.2, 0.8);
      g.fillStyle(0xffffff, a);
      g.fillCircle(x, y, r);
    }

    // A few twinkling bright stars
    const twinkleCount = 15;
    for (let i = 0; i < twinkleCount; i++) {
      const x = rng.between(50, W - 50);
      const y = rng.between(50, H - 50);
      const star = this.add.graphics();
      star.fillStyle(0xffffff, 1);
      star.fillCircle(x, y, 2);
      this.tweens.add({
        targets: star,
        alpha: { from: 1, to: 0.1 },
        duration: rng.between(600, 1800),
        yoyo: true,
        repeat: -1,
        delay: rng.between(0, 1200),
      });
    }
  }

  // ─── Title ─────────────────────────────────────────────────────────────────

  _buildTitle() {
    // Glowing subtitle
    this.add.text(W / 2, 80, 'S P A C E  G R A V I T Y', {
      fontSize: '16px',
      fontFamily: 'monospace',
      color: '#00ffee',
      letterSpacing: 4,
    }).setOrigin(0.5);

    // Main title
    const title = this.add.text(W / 2, 138, 'GRAVITY', {
      fontSize: '96px',
      fontFamily: 'monospace',
      color: '#ffffff',
      stroke: '#ff00ff',
      strokeThickness: 3,
    }).setOrigin(0.5);

    // Slow glow pulse on title
    this.tweens.add({
      targets: title,
      alpha: { from: 1, to: 0.75 },
      duration: 1800,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    // Tagline
    this.add.text(W / 2, 225, 'Use gravity wells to reach the warp gateway', {
      fontSize: '17px',
      fontFamily: 'monospace',
      color: '#aaaacc',
    }).setOrigin(0.5);
  }

  // ─── Level Grid ────────────────────────────────────────────────────────────

  _buildLevelGrid() {
    const unlocked = parseInt(localStorage.getItem('gravity_unlocked') ?? '1', 10);

    this.add.text(W / 2, 280, 'SELECT LEVEL', {
      fontSize: '14px',
      fontFamily: 'monospace',
      color: '#555577',
      letterSpacing: 3,
    }).setOrigin(0.5);

    const cols      = 5;
    const btnW      = 180;
    const btnH      = 72;
    const gapX      = 24;
    const gapY      = 18;
    const totalW    = cols * btnW + (cols - 1) * gapX;
    const startX    = (W - totalW) / 2 + btnW / 2;
    const startY    = 320;

    for (let i = 0; i < levels.length; i++) {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x   = startX + col * (btnW + gapX);
      const y   = startY + row * (btnH + gapY);
      const lv  = levels[i];
      const isUnlocked = lv.id <= unlocked;

      this._makeLevelButton(x, y, btnW, btnH, lv, isUnlocked);
    }

    // Quick-start: Play button launches at the highest reached level
    const resumeId = Math.min(unlocked, levels.length);
    const playY    = startY + 2 * (btnH + gapY) + 58;

    const playBg = this.add.rectangle(W / 2, playY, 320, 70, 0xff00ff, 0.2)
      .setStrokeStyle(2, 0xff00ff, 0.9)
      .setInteractive({ useHandCursor: true });

    const playLabel = this.add.text(W / 2, playY, `▶  PLAY  (Level ${resumeId})`, {
      fontSize: '24px',
      fontFamily: 'monospace',
      color: '#ffffff',
    }).setOrigin(0.5);

    playBg.on('pointerover',  () => playBg.setFillStyle(0xff00ff, 0.45));
    playBg.on('pointerout',   () => playBg.setFillStyle(0xff00ff, 0.2));
    playBg.on('pointerdown',  () => playBg.setFillStyle(0xff00ff, 0.7));
    playBg.on('pointerup', () => {
      this.registry.set('currentLevel', resumeId);
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });

    // Pulse play button
    this.tweens.add({
      targets: playBg,
      scaleX: { from: 1, to: 1.03 },
      scaleY: { from: 1, to: 1.03 },
      duration: 900,
      yoyo: true,
      repeat: -1,
    });
  }

  _makeLevelButton(x, y, w, h, level, isUnlocked) {
    const borderColor = isUnlocked ? 0x4466cc : 0x333333;
    const fillColor   = isUnlocked ? 0x1122aa : 0x111111;
    const textColor   = isUnlocked ? '#ffffff' : '#555555';

    const bg = this.add.rectangle(x, y, w, h, fillColor, 0.7)
      .setStrokeStyle(1.5, borderColor, isUnlocked ? 0.8 : 0.4);

    const numText = this.add.text(x, y - 12, String(level.id), {
      fontSize: '22px',
      fontFamily: 'monospace',
      color: isUnlocked ? '#88aaff' : '#444444',
      stroke: isUnlocked ? '#ffffff' : 'none',
      strokeThickness: isUnlocked ? 0.5 : 0,
    }).setOrigin(0.5);

    const nameText = this.add.text(x, y + 14, level.name, {
      fontSize: '11px',
      fontFamily: 'monospace',
      color: textColor,
    }).setOrigin(0.5);

    if (!isUnlocked) {
      this.add.text(x, y, '🔒', { fontSize: '20px' }).setOrigin(0.5).setAlpha(0.5);
      return;
    }

    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerover',  () => bg.setFillStyle(0x2233cc, 0.85));
    bg.on('pointerout',   () => bg.setFillStyle(fillColor, 0.7));
    bg.on('pointerdown',  () => bg.setFillStyle(0x4455ee, 1));
    bg.on('pointerup', () => {
      this.registry.set('currentLevel', level.id);
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  _buildFooter() {
    this.add.text(W / 2, H - 20, 'Drag from LAUNCH zone · Gravity curves your path · Reach the WARP gateway', {
      fontSize: '13px',
      fontFamily: 'monospace',
      color: '#444466',
    }).setOrigin(0.5, 1);
  }
}
