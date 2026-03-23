import MenuScene from './scenes/MenuScene.js';
import GameScene from './scenes/GameScene.js';
import UIScene   from './scenes/UIScene.js';

const config = {
  type: Phaser.WEBGL,          // force GPU renderer
  backgroundColor: '#000814',
  scene: [MenuScene, GameScene, UIScene],
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: 1280,
    height: 720,
  },
  render: {
    antialias: true,
    pixelArt: false,
    resolution: window.devicePixelRatio || 1,
    roundPixels: false,
  },
};

new Phaser.Game(config);

