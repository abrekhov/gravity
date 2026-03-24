import 'package:flutter/widgets.dart';

class OverlayButton extends StatefulWidget {
  final String label;
  final bool primary;
  final double width;
  final VoidCallback onTap;

  const OverlayButton({
    required this.label,
    required this.primary,
    required this.width,
    required this.onTap,
    super.key,
  });

  @override
  State<OverlayButton> createState() => _OverlayButtonState();
}

class _OverlayButtonState extends State<OverlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.primary
        ? const Color(0xFF1A3A5A).withOpacity(_pressed ? 1.0 : 0.8)
        : const Color(0xFF0C1A28).withOpacity(_pressed ? 1.0 : 0.7);
    final borderColor =
        widget.primary ? const Color(0xFF3D6FFF) : const Color(0xFF2A4060);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: widget.width,
        height: 50,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(3),
          boxShadow: widget.primary
              ? [
                  BoxShadow(
                    color: const Color(0xFF3D6FFF).withOpacity(0.2),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              letterSpacing: 1,
              color: widget.primary
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF6A8AAA),
            ),
          ),
        ),
      ),
    );
  }
}
