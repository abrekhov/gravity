import 'package:flutter/widgets.dart';
import '../game/gravity_game.dart';
import '../game/level_data.dart';

class MainMenuOverlay extends StatelessWidget {
  final GravityGame game;
  const MainMenuOverlay({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    final resumeId =
        (game.unlockedLevelId).clamp(1, kLevels.length);

    return GestureDetector(
      onTapDown: (_) {}, // absorb so game doesn't receive stray taps
      child: SizedBox.expand(
        child: Center(
          child: _buildPanel(context, resumeId),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, int resumeId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow
        Text(
          'S P A C E   P U Z Z L E',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            letterSpacing: 4,
            color: const Color(0xFF3D5068),
          ),
        ),
        const SizedBox(height: 16),
        // Main title
        const Text(
          'GRAVITY',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
            color: Color(0xFFFFFFFF),
            shadows: [
              Shadow(
                  color: Color(0x663D6FFF),
                  blurRadius: 32,
                  offset: Offset(0, 0)),
              Shadow(
                  color: Color(0x333D6FFF),
                  blurRadius: 64,
                  offset: Offset(0, 0)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bend gravity — reach the portal',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7A8FA8),
          ),
        ),
        const SizedBox(height: 32),
        // CONTINUE button
        _NeonButton(
          label: 'CONTINUE  ·  Level $resumeId',
          primary: true,
          width: 300,
          onTap: () => game.startLevel(resumeId),
        ),
        const SizedBox(height: 14),
        // SELECT LEVEL button
        _NeonButton(
          label: 'SELECT LEVEL',
          primary: false,
          width: 220,
          onTap: () {
            game.overlays.remove('MainMenu');
            game.overlays.add('LevelSelect');
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Drag from LAUNCH zone · Gravity curves your path',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFF3D5068),
          ),
        ),
      ],
    );
  }
}

// ─── Shared button widget ─────────────────────────────────────────────────────

class _NeonButton extends StatefulWidget {
  final String label;
  final bool primary;
  final double width;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.primary,
    required this.width,
    required this.onTap,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF3D6FFF);
    final fillColor = widget.primary
        ? accent.withOpacity(_pressed ? 0.45 : 0.20)
        : const Color(0xFF0D1E33).withOpacity(_pressed ? 1.0 : 0.8);
    final borderColor =
        widget.primary ? accent : const Color(0xFF2A4466);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: widget.width,
        height: 52,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(3),
          boxShadow: widget.primary
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 16,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              color: widget.primary
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF7A8FA8),
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

