// All level configurations for the space gravity game.
// Canvas size: 1280 x 720
// launchZone: where the player drags from
// gateway: the exit portal to reach
// gravityBodies: planets/stars that attract the dot

export const levels = [
  // ─── Level 1 ── Tutorial: one planet, wide corridor ──────────────────────
  {
    id: 1,
    name: 'First Steps',
    G: 80,
    gravityBodies: [
      { x: 560, y: 480, mass: 3000, radius: 44, color: 0x4488ff },
    ],
    launchZone: { x: 160, y: 420, radius: 44 },
    gateway:    { x: 1100, y: 260, radius: 36 },
  },

  // ─── Level 2 ── Two planets as stepping stones ───────────────────────────
  {
    id: 2,
    name: 'Double Trouble',
    G: 90,
    gravityBodies: [
      { x: 420, y: 440, mass: 2600, radius: 38, color: 0xff6644 },
      { x: 800, y: 310, mass: 2800, radius: 42, color: 0x44ffaa },
    ],
    launchZone: { x: 150, y: 560, radius: 42 },
    gateway:    { x: 1130, y: 160, radius: 34 },
  },

  // ─── Level 3 ── Thread the needle between two planets ────────────────────
  {
    id: 3,
    name: 'Needle Eye',
    G: 100,
    gravityBodies: [
      { x: 640, y: 230, mass: 3200, radius: 50, color: 0xaa44ff },
      { x: 640, y: 530, mass: 2200, radius: 35, color: 0xff44aa },
    ],
    launchZone: { x: 120, y: 370, radius: 40 },
    gateway:    { x: 1160, y: 370, radius: 34 },
  },

  // ─── Level 4 ── Diagonal chain of three planets ──────────────────────────
  {
    id: 4,
    name: 'Chain Reaction',
    G: 100,
    gravityBodies: [
      { x: 380, y: 510, mass: 2000, radius: 32, color: 0x00ffff },
      { x: 640, y: 360, mass: 2800, radius: 40, color: 0xff8800 },
      { x: 900, y: 220, mass: 2200, radius: 34, color: 0x88ff00 },
    ],
    launchZone: { x: 140, y: 610, radius: 40 },
    gateway:    { x: 1140, y: 120, radius: 32 },
  },

  // ─── Level 5 ── Massive center + 2 moons, true slingshot ─────────────────
  {
    id: 5,
    name: 'The Slingshot',
    G: 120,
    gravityBodies: [
      { x: 640, y: 360, mass: 8000, radius: 68, color: 0xffdd00 },
      { x: 640, y: 170, mass: 800,  radius: 18, color: 0xaaaaff },
      { x: 640, y: 550, mass: 800,  radius: 18, color: 0xaaffaa },
    ],
    launchZone: { x: 160, y: 360, radius: 40 },
    gateway:    { x: 1120, y: 360, radius: 32 },
  },

  // ─── Level 6 ── Zigzag slalom through four planets ───────────────────────
  {
    id: 6,
    name: 'Slalom',
    G: 110,
    gravityBodies: [
      { x: 330, y: 210, mass: 2600, radius: 38, color: 0xff3366 },
      { x: 530, y: 510, mass: 2400, radius: 36, color: 0x33aaff },
      { x: 730, y: 210, mass: 2600, radius: 38, color: 0xff3366 },
      { x: 930, y: 510, mass: 2400, radius: 36, color: 0x33aaff },
    ],
    launchZone: { x: 130, y: 360, radius: 38 },
    gateway:    { x: 1150, y: 360, radius: 30 },
  },

  // ─── Level 7 ── Gateway is behind the launch zone — must loop around ─────
  {
    id: 7,
    name: 'Full Circle',
    G: 130,
    gravityBodies: [
      { x: 640, y: 360, mass: 9000, radius: 74, color: 0xff6600 },
      { x: 900, y: 560, mass: 1200, radius: 22, color: 0x00ffcc },
    ],
    launchZone: { x: 150, y: 580, radius: 38 },
    gateway:    { x: 200,  y: 130, radius: 30 },
  },

  // ─── Level 8 ── Binary star, must pass through narrow center corridor ─────
  {
    id: 8,
    name: 'Binary Star',
    G: 120,
    gravityBodies: [
      { x: 380, y: 360, mass: 5000, radius: 58, color: 0xff4400 },
      { x: 900, y: 360, mass: 5000, radius: 58, color: 0x4400ff },
      { x: 640, y: 360, mass: 1500, radius: 24, color: 0xffffff },
    ],
    launchZone: { x: 640, y: 650, radius: 38 },
    gateway:    { x: 640, y:  70, radius: 30 },
  },

  // ─── Level 9 ── Five planets in defensive ring ───────────────────────────
  {
    id: 9,
    name: 'The Gauntlet',
    G: 140,
    gravityBodies: [
      { x: 450, y: 200, mass: 3000, radius: 40, color: 0xff0066 },
      { x: 640, y: 145, mass: 2500, radius: 35, color: 0x00ff99 },
      { x: 830, y: 200, mass: 3000, radius: 40, color: 0xff0066 },
      { x: 450, y: 520, mass: 3000, radius: 40, color: 0x00ff99 },
      { x: 830, y: 520, mass: 3000, radius: 40, color: 0xff0066 },
    ],
    launchZone: { x: 120, y: 360, radius: 36 },
    gateway:    { x: 1160, y: 360, radius: 28 },
  },

  // ─── Level 10 ── Maximum complexity: 10 bodies ───────────────────────────
  {
    id: 10,
    name: 'The Labyrinth',
    G: 150,
    gravityBodies: [
      { x: 285, y: 505, mass: 2000, radius: 32, color: 0xff2200 },
      { x: 460, y: 355, mass: 3500, radius: 46, color: 0x2200ff },
      { x: 355, y: 190, mass: 1800, radius: 28, color: 0x00ff44 },
      { x: 640, y: 575, mass: 2200, radius: 34, color: 0xff8800 },
      { x: 640, y: 285, mass: 4000, radius: 52, color: 0xffff00 },
      { x: 820, y: 475, mass: 2500, radius: 36, color: 0x00ccff },
      { x: 960, y: 590, mass: 1600, radius: 26, color: 0xff00cc },
      { x: 855, y: 210, mass: 3000, radius: 40, color: 0x44ff00 },
      { x: 1050, y: 385, mass: 2000, radius: 30, color: 0xff4488 },
      { x: 1090, y: 205, mass: 1400, radius: 22, color: 0x88aaff },
    ],
    launchZone: { x: 105, y: 640, radius: 36 },
    gateway:    { x: 1180, y:  75, radius: 26 },
  },
];
