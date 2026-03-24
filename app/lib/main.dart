import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/gravity_game.dart';
import 'overlays/fail_overlay.dart';
import 'overlays/hud.dart';
import 'overlays/level_select.dart';
import 'overlays/main_menu.dart';
import 'overlays/win_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = GravityGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000814),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF000814),
        body: GameWidget<GravityGame>(
          game: game,
          overlayBuilderMap: {
            'MainMenu': (context, game) =>
                MainMenuOverlay(game: game),
            'LevelSelect': (context, game) =>
                LevelSelectOverlay(game: game),
            'HUD': (context, game) => HUDOverlay(game: game),
            'WinOverlay': (context, game) =>
                WinOverlayWidget(game: game),
            'FailOverlay': (context, game) =>
                FailOverlayWidget(game: game),
          },
          initialActiveOverlays: const ['MainMenu'],
        ),
      ),
    ),
  );
}
