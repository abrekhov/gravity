import { levels } from '../levels.js';

const W = 1280;
const H = 720;

// ─── palette ───────────────────────────────────────────────────────────────
const CLR = {
  bg:       0x000814,
  textPrim: '#ffffff',
  textSub:  '#7a8fa8',
  textDim:  '#3d5068',
  accent:   0x3d6fff,
  accentHex:'#3d6fff',
  locked:   0x1e2d3e,
};

export default class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create() {
    this._buildStarfield();

    // Two containers — only one shown at a time
    this._mainContainer   = this.add.container(0, 0);
    this._levelsContainer = this.add.container(0, 0);

    this._buildMainView();
    this._buildLevelsView();

    // Navigate straight to level-select if flagged from UIScene
    if (this.registry.get('menuTarget') === 'levels') {
      this.registry.remove('menuTarget');
      this._showLevels();
    } else {
      this._showMain();
    }
  }

  // ─── Starfield ─────────────────────────────────────────────────────────────

  _buildStarfield() {
    const g   = this.add.graphics();
    const rng = new Phaser.Math.RandomDataGenerator(['menu-stars']);
    for (let i = 0; i < 240; i++) {
      const x    = rng.between(0, W);
      const y    = rng.between(0, H);
      const r    = rng.frac() < 0.12 ? 1.5 : 1;
      const a    = rng.realInRange(0.1, 0.5);
      const tint = rng.frac() < 0.12 ? (rng.frac() < 0.5 ? 0xdde8ff : 0xfff4e8) : 0xffffff;
      g.fillStyle(tint, a);
      g.fillCircle(x, y, r);
    }

    // A handful of slow-twinkling bright stars
    for (let i = 0; i < 12; i++) {
      const x    = rng.between(60, W - 60);
      const y    = rng.between(60, H - 60);
      const star = this.add.graphics();
      star.fillStyle(0xffffff, 0.9);
      star.fillCircle(x, y, 1.5);
      this.tweens.add({
        targets: star, alpha: { from: 0.9, to: 0.1 },
        duration: rng.between(1200, 3000), yoyo: true, repeat: -1,
        delay: rng.between(0, 2000), ease: 'Sine.easeInOut',
      });
    }
  }

  // ─── Main view ─────────────────────────────────────────────────────────────

  _buildMainView() {
    const c = this._mainContainer;

    // Eyebrow
    const eye = this.add.text(W / 2, 130, 'S P A C E  P U Z Z L E', {
      fontSize: '13px', fontFamily: 'monospace',
      color: CLR.textDim, letterSpacing: 6,
    }).setOrigin(0.5);
    c.add(eye);

    // Main title
    const title = this.add.text(W / 2, 210, 'GRAVITY', {
      fontSize: '110px', fontFamily: 'Arial, sans-serif',
      color: CLR.textPrim,
      stroke: '#1a2a44', strokeThickness: 6,
    }).setOrigin(0.5);
    c.add(title);

    // Very subtle title glow pulse
    this.tweens.add({
      targets: title, alpha: { from: 1, to: 0.82 },
      duration: 2400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
    });

    // Tagline
    const tag = this.add.text(W / 2, 308, 'Bend gravity — reach the portal', {
      fontSize: '17px', fontFamily: 'Arial, sans-serif', color: CLR.textSub,
    }).setOrigin(0.5);
    c.add(tag);

    // Divider line
    const div = this.add.graphics();
    div.lineStyle(1, 0x1d3050, 1);
    div.lineBetween(W / 2 - 160, 344, W / 2 + 160, 344);
    c.add(div);

    // CONTINUE button (resumes at highest reached level)
    const unlocked = parseInt(localStorage.getItem('gravity_unlocked') ?? '1', 10);
    const resumeId = Math.min(unlocked, levels.length);
    const cont = this._makeBtn(W / 2, 415, 320, 64, `CONTINUE  ·  Level ${resumeId}`, true);
    c.add(cont.bg);
    c.add(cont.label);
    cont.bg.on('pointerup', () => {
      this.registry.set('currentLevel', resumeId);
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });

    // SELECT LEVEL button
    const sel = this._makeBtn(W / 2, 500, 240, 52, 'SELECT LEVEL', false);
    c.add(sel.bg);
    c.add(sel.label);
    sel.bg.on('pointerup', () => {
      this._showLevels();
    });

    // Hint
    const hint = this.add.text(W / 2, 580, 'Drag from LAUNCH zone · Gravity curves your path', {
      fontSize: '13px', fontFamily: 'monospace', color: CLR.textDim,
    }).setOrigin(0.5);
    c.add(hint);
  }

  // ─── Levels view ───────────────────────────────────────────────────────────

  _buildLevelsView() {
    const c        = this._levelsContainer;
    const unlocked = parseInt(localStorage.getItem('gravity_unlocked') ?? '1', 10);

    // Header
    const hdr = this.add.text(W / 2, 68, 'SELECT LEVEL', {
      fontSize: '13px', fontFamily: 'monospace',
      color: CLR.textDim, letterSpacing: 5,
    }).setOrigin(0.5);
    c.add(hdr);

    // Back button (top-left)
    const back = this._makeBtn(80, 68, 130, 44, '← BACK', false, 13);
    c.add(back.bg);
    c.add(back.label);
    back.bg.on('pointerup', () => this._showMain());

    // Level grid — 5 × 2
    const cols  = 5;
    const btnW  = 200, btnH = 230;
    const gapX  = 18,  gapY = 22;
    const totalW = cols * btnW + (cols - 1) * gapX;
    const startX = (W - totalW) / 2 + btnW / 2;
    const startY = 185;

    for (let i = 0; i < levels.length; i++) {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x   = startX + col * (btnW + gapX);
      const y   = startY + row * (btnH + gapY);
      const lv  = levels[i];
      const objs = this._makeLevelCard(x, y, btnW, btnH, lv, lv.id <= unlocked);
      objs.forEach(o => c.add(o));
    }
  }

  _makeLevelCard(x, y, w, h, level, isUnlocked) {
    const borderCol = isUnlocked ? 0x2a4466 : 0x1a2433;
    const fillCol   = isUnlocked ? 0x0d1a2a : CLR.locked;

    const bg = this.add.rectangle(x, y, w, h, fillCol, isUnlocked ? 0.9 : 0.6)
      .setStrokeStyle(1, borderCol, isUnlocked ? 0.9 : 0.5);

    const numText = this.add.text(x, y - 62, String(level.id).padStart(2, '0'), {
      fontSize: '36px', fontFamily: 'Arial, sans-serif',
      color: isUnlocked ? '#ffffff' : '#2d4055',
    }).setOrigin(0.5).setAlpha(isUnlocked ? 0.9 : 0.6);

    const nameText = this.add.text(x, y - 18, level.name, {
      fontSize: '12px', fontFamily: 'monospace',
      color: isUnlocked ? CLR.textSub : '#2d4055',
    }).setOrigin(0.5);

    // Shot dots row
    const total   = level.shots ?? 3;
    const dotObjs = [];
    const spacing = 14;
    const dotsX   = x - ((total - 1) * spacing) / 2;
    for (let i = 0; i < total; i++) {
      dotObjs.push(
        this.add.circle(dotsX + i * spacing, y + 22, 4,
          isUnlocked ? 0x3d6fff : 0x1e2d3e, isUnlocked ? 0.7 : 0.4),
      );
    }

    if (!isUnlocked) {
      const lock = this.add.text(x, y + 58, '🔒', { fontSize: '18px' }).setOrigin(0.5).setAlpha(0.4);
      return [bg, numText, nameText, ...dotObjs, lock];
    }

    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerover',  () => { bg.setFillStyle(0x1a3050, 1); bg.setStrokeStyle(1, 0x4a6aaa, 1); });
    bg.on('pointerout',   () => { bg.setFillStyle(fillCol, 0.9); bg.setStrokeStyle(1, borderCol, 0.9); });
    bg.on('pointerdown',  () => bg.setFillStyle(0x2a4466, 1));
    bg.on('pointerup', () => {
      this.registry.set('currentLevel', level.id);
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });

    return [bg, numText, nameText, ...dotObjs];
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  _showMain() {
    this._mainContainer.setVisible(true);
    this._levelsContainer.setVisible(false);
  }

  _showLevels() {
    this._mainContainer.setVisible(false);
    this._levelsContainer.setVisible(true);
  }

  // ─── Shared button factory ─────────────────────────────────────────────────

  _makeBtn(x, y, w, h, text, primary = false, fontSize = 17) {
    const fillCol   = primary ? CLR.accent : 0x0d1e33;
    const borderCol = primary ? CLR.accent : 0x2a4466;
    const fillAlpha = primary ? 0.25 : 0.6;

    const bg = this.add.rectangle(x, y, w, h, fillCol, fillAlpha)
      .setStrokeStyle(1.5, borderCol, primary ? 0.9 : 0.7)
      .setInteractive({ useHandCursor: true });

    const label = this.add.text(x, y, text, {
      fontSize: `${fontSize}px`, fontFamily: 'Arial, sans-serif',
      color: primary ? '#ffffff' : CLR.textSub,
    }).setOrigin(0.5);

    bg.on('pointerover',  () => { bg.setFillStyle(fillCol, primary ? 0.5 : 0.85); });
    bg.on('pointerout',   () => { bg.setFillStyle(fillCol, fillAlpha); });
    bg.on('pointerdown',  () => { bg.setFillStyle(fillCol, primary ? 0.7 : 1); });

    if (primary) {
      this.tweens.add({
        targets: bg, scaleX: { from: 1, to: 1.02 }, scaleY: { from: 1, to: 1.02 },
        duration: 1100, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
      });
    }

    return { bg, label };
  }
}
