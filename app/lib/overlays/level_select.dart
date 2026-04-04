import 'package:flutter/widgets.dart';
import '../game/gravity_game.dart';
import '../game/level_data.dart';
import '../services/purchase_service.dart';

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
          final progressLocked = level.id > game.unlockedLevelId;
          final premiumLocked  = level.id > 10 &&
              !PurchaseService.instance.isPremium;
          final tappable = !progressLocked;
          return _LevelCard(
            level: level,
            progressLocked: progressLocked,
            premiumLocked: premiumLocked,
            onTap: tappable ? () => game.startLevel(level.id) : null,
          );
        }).toList(),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final LevelData level;
  final bool progressLocked;
  final bool premiumLocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.progressLocked,
    required this.premiumLocked,
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
    final tappable = widget.onTap != null;
    final isPremiumLocked = widget.premiumLocked;

    final borderColor = tappable
        ? (isPremiumLocked
            ? const Color(0xFF7A6020)  // gold tint for premium
            : (_hovered ? const Color(0xFF4A6AAA) : const Color(0xFF2A4466)))
        : const Color(0xFF1A2433);
    final fillColor = tappable
        ? (isPremiumLocked
            ? const Color(0xFF1A1505)
            : (_hovered
                ? const Color(0xFF1A3050)
                : _pressed
                    ? const Color(0xFF2A4466)
                    : const Color(0xFF0D1A2A)))
        : const Color(0xFF1E2D3E);

    return GestureDetector(
      onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: tappable
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
      child: MouseRegion(
        onEnter: tappable ? (_) => setState(() => _hovered = true) : null,
        onExit: tappable ? (_) => setState(() => _hovered = false) : null,
        cursor:
            tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: 110,
          height: 120,
          decoration: BoxDecoration(
            color: fillColor.withOpacity(tappable ? 0.9 : 0.6),
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.level.id.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 22,
                  color: tappable
                      ? (isPremiumLocked
                          ? const Color(0xFFB89030)
                          : const Color(0xFFFFFFFF))
                      : const Color(0xFF2D4055),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.level.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: tappable
                      ? (isPremiumLocked
                          ? const Color(0xFF7A6020)
                          : const Color(0xFF7A8FA8))
                      : const Color(0xFF2D4055),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
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
                        color: tappable
                            ? (isPremiumLocked
                                ? const Color(0xFFB89030).withOpacity(0.5)
                                : const Color(0xFF3D6FFF).withOpacity(0.7))
                            : const Color(0xFF1E2D3E),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              if (isPremiumLocked)
                const Text('👑', style: TextStyle(fontSize: 12))
              else if (widget.progressLocked)
                const Text('🔒', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

