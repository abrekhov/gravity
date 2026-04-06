import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/gravity_game.dart';
import 'overlays/fail_overlay.dart';
import 'overlays/hud.dart';
import 'overlays/level_select.dart';
import 'overlays/main_menu.dart';
import 'overlays/premium_overlay.dart';
import 'overlays/win_overlay.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Ads and IAP are mobile-only; both packages lack web implementations.
  if (!kIsWeb) {
    await PurchaseService.instance.initialize();
    await AdService.instance.initialize();
  }

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
            'PremiumOffer': (context, game) =>
                PremiumOverlay(game: game),
          },
          initialActiveOverlays: const ['MainMenu'],
        ),
      ),
    ),
  );
}
