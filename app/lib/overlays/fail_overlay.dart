import 'dart:async';
import 'package:flutter/widgets.dart';
import '../game/gravity_game.dart';
import '../services/ad_service.dart';
import 'overlay_button.dart';

class FailOverlayWidget extends StatefulWidget {
  final GravityGame game;
  const FailOverlayWidget({required this.game, super.key});

  @override
  State<FailOverlayWidget> createState() => _FailOverlayWidgetState();
}

class _FailOverlayWidgetState extends State<FailOverlayWidget> {
  late StreamSubscription<GameEvent> _sub;
  bool _buttonsVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _buttonsVisible = true);
    });
    _sub = widget.game.events.listen((_) {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {},
      child: SizedBox.expand(
        child: Stack(
          children: [
            Container(color: const Color(0xB2000814)),
            Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0A0A).withOpacity(0.95),
                  border: Border.all(
                    color: const Color(0xFF3A1A1A),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MISSION FAILED',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFCC4433),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_buttonsVisible) ...[
                      OverlayButton(
                        label: 'TRY AGAIN',
                        primary: true,
                        width: 190,
                        onTap: () => AdService.instance
                            .showIfReady(onDismissed: widget.game.retry),
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
                      const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
