import 'package:flutter/widgets.dart';

import '../game/gravity_game.dart';
import '../services/purchase_service.dart';
import 'overlay_button.dart';

class PremiumOverlay extends StatefulWidget {
  final GravityGame game;
  const PremiumOverlay({required this.game, super.key});

  @override
  State<PremiumOverlay> createState() => _PremiumOverlayState();
}

class _PremiumOverlayState extends State<PremiumOverlay> {
  bool _buying = false;

  void _dismiss() {
    widget.game.overlays.remove('PremiumOffer');
  }

  Future<void> _buy() async {
    setState(() => _buying = true);
    await PurchaseService.instance.buyPremium();
    if (mounted) setState(() => _buying = false);
  }

  @override
  Widget build(BuildContext context) {
    final price = PurchaseService.instance.price;

    return GestureDetector(
      onTapDown: (_) {},
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Dimmed background — tap outside to dismiss
            GestureDetector(
              onTap: _dismiss,
              child: Container(color: const Color(0xCC000814)),
            ),
            Center(
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF060D18),
                  border: Border.all(
                    color: const Color(0xFF3D6FFF),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x403D6FFF),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Crown icon (unicode)
                    const Text('👑',
                        style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 14),
                    const Text(
                      'GRAVITAS PREMIUM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FeatureLine('All 31 levels unlocked'),
                    _FeatureLine('No ads, ever'),
                    _FeatureLine('One-time purchase'),
                    const SizedBox(height: 24),
                    OverlayButton(
                      label: _buying ? 'OPENING STORE…' : 'UNLOCK  ·  $price',
                      primary: true,
                      width: 260,
                      onTap: _buying ? () {} : _buy,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => PurchaseService.instance.restorePurchases(),
                      child: const Text(
                        'Restore previous purchase',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3D5068),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF3D5068),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Text(
                        'CONTINUE FREE',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3D5068),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
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

class _FeatureLine extends StatelessWidget {
  final String text;
  const _FeatureLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('·  ',
              style: TextStyle(color: Color(0xFF3D6FFF), fontSize: 14)),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF7A8FA8), fontSize: 14)),
        ],
      ),
    );
  }
}
