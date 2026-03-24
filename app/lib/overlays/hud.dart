import 'dart:async';
import 'package:flutter/widgets.dart';
import '../game/gravity_game.dart';
import '../game/level_data.dart';

class HUDOverlay extends StatefulWidget {
  final GravityGame game;
  const HUDOverlay({required this.game, super.key});

  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  late StreamSubscription<GameEvent> _sub;
  int _shotsRemaining = 0;
  LevelData? _level;
  bool _hintVisible = true;

  @override
  void initState() {
    super.initState();
    _level = widget.game.activeLevel;
    _shotsRemaining = _level?.shots ?? 0;
    _sub = widget.game.events.listen(_onEvent);
  }

  void _onEvent(GameEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event) {
        case LevelStarted(:final level):
          _level = level;
          _shotsRemaining = level.shots;
          _hintVisible = true;
        case ShotUsed(:final remaining):
          _shotsRemaining = remaining;
        case DotLaunched():
          _hintVisible = false;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _level ?? widget.game.activeLevel;
    if (level == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Level info — top-left
        Positioned(
          top: 16,
          left: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL ${level.id.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF5A7090),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                level.name,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFC8D8EA),
                ),
              ),
            ],
          ),
        ),
        // Shot dots — top-right
        Positioned(
          top: 22,
          right: 18,
          child: Row(
            children: List.generate(level.shots, (i) {
              final active = i < _shotsRemaining;
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: AnimatedOpacity(
                  opacity: active ? 0.9 : 0.12,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4466AA),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Aim hint — bottom center
        if (_hintVisible)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Drag from LAUNCH zone · Release to fire',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF3D5570),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
