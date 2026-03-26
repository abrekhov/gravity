import 'package:flutter/widgets.dart';
import '../game/gravity_game.dart';
import '../game/level_data.dart';

class LevelSelectOverlay extends StatelessWidget {
  final GravityGame game;
  const LevelSelectOverlay({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {},
      child: SizedBox.expand(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _BackButton(onTap: () {
                    game.overlays.remove('LevelSelect');
                    game.overlays.add('MainMenu');
                  }),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'S E L E C T   L E V E L',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 4,
                          color: Color(0xFF3D5068),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 80), // balance the back button
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Level grid
            Expanded(
              child: Center(
                child: _LevelGrid(game: game),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: 80,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1E33).withOpacity(_pressed ? 1.0 : 0.7),
          border: Border.all(color: const Color(0xFF2A4466), width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Center(
          child: Text(
            '← BACK',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7A8FA8),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  final GravityGame game;
  const _LevelGrid({required this.game});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: kLevels.map((level) {
          final unlocked = level.id <= game.unlockedLevelId;
          return _LevelCard(
            level: level,
            unlocked: unlocked,
            onTap: unlocked ? () => game.startLevel(level.id) : null,
          );
        }).toList(),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final LevelData level;
  final bool unlocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.unlocked;
    final borderColor = isUnlocked
        ? (_hovered ? const Color(0xFF4A6AAA) : const Color(0xFF2A4466))
        : const Color(0xFF1A2433);
    final fillColor = isUnlocked
        ? (_hovered
            ? const Color(0xFF1A3050)
            : _pressed
                ? const Color(0xFF2A4466)
                : const Color(0xFF0D1A2A))
        : const Color(0xFF1E2D3E);

    return GestureDetector(
      onTapDown: isUnlocked ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isUnlocked
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: isUnlocked ? () => setState(() => _pressed = false) : null,
      child: MouseRegion(
        onEnter: isUnlocked ? (_) => setState(() => _hovered = true) : null,
        onExit: isUnlocked ? (_) => setState(() => _hovered = false) : null,
        cursor: isUnlocked
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width: 110,
          height: 120,
          decoration: BoxDecoration(
            color: fillColor.withOpacity(isUnlocked ? 0.9 : 0.6),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Level number
              Text(
                widget.level.id.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 22,
                  color: isUnlocked
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF2D4055),
                ),
              ),
              const SizedBox(height: 3),
              // Level name
              Text(
                widget.level.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: isUnlocked
                      ? const Color(0xFF7A8FA8)
                      : const Color(0xFF2D4055),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Shot dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.level.shots, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked
                            ? const Color(0xFF3D6FFF).withOpacity(0.7)
                            : const Color(0xFF1E2D3E),
                      ),
                    ),
                  );
                }),
              ),
              if (!isUnlocked) ...[
                const SizedBox(height: 6),
                const Text(
                  '🔒',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

