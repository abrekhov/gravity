import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/gravity_game.dart';
import '../game/level_data.dart';
import '../services/ad_service.dart';
import 'overlay_button.dart';

class WinOverlayWidget extends StatefulWidget {
  final GravityGame game;
  const WinOverlayWidget({required this.game, super.key});

  @override
  State<WinOverlayWidget> createState() => _WinOverlayWidgetState();
}

class _WinOverlayWidgetState extends State<WinOverlayWidget> {
  late StreamSubscription<GameEvent> _sub;
  bool _buttonsVisible = false;
  int _wonLevelId = 0;

  @override
  void initState() {
    super.initState();
    _wonLevelId = widget.game.activeLevel?.id ?? 0;
    // Delay buttons to prevent phantom taps
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _buttonsVisible = true);
    });
    _sub = widget.game.events.listen((e) {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextId = _wonLevelId + 1;
    final isLast = nextId > kLevels.length;
    final subText =
        isLast ? 'All levels complete!' : 'Level $nextId unlocked';
    final nextLabel = isLast ? 'PLAY AGAIN' : 'NEXT LEVEL';

    return GestureDetector(
      onTapDown: (_) {},
      child: SizedBox.expand(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 280),
          child: Stack(
            children: [
              // Dark overlay
              Container(color: const Color(0xB2000814)),
              Center(
                child: Container(
                  width: 460,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 36),
                  decoration: BoxDecoration(
                    color: const Color(0xFF060D18).withOpacity(0.95),
                    border: Border.all(
                      color: const Color(0xFF2A4060),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LEVEL COMPLETE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFFFFF),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF6A8AAA),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_buttonsVisible) ...[
                        OverlayButton(
                          label: nextLabel,
                          primary: true,
                          width: 220,
                          onTap: () async {
                            final action = isLast
                                ? () => widget.game.startLevel(1)
                                : widget.game.nextLevel;
                            // Show an interstitial every 3rd completed level.
                            final prefs =
                                await SharedPreferences.getInstance();
                            final count =
                                (prefs.getInt('gravity_win_count') ?? 0) + 1;
                            await prefs.setInt('gravity_win_count', count);
                            if (count % 3 == 0) {
                              AdService.instance
                                  .showIfReady(onDismissed: action);
                            } else {
                              action();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        OverlayButton(
                          label: 'LEVELS',
                          primary: false,
                          width: 130,
                          onTap: () =>
                              widget.game.goToMenu(showLevels: true),
                        ),
                      ] else
                        const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

