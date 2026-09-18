import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A bespoke, minimalist floating card pile icon widget.
/// Replaces generic dice/emojis with a tactile 3D-stacked miniature card deck.
class FloatingCardPileIcon extends StatelessWidget {
  final double size;
  final Color? accentColor;

  const FloatingCardPileIcon({
    super.key,
    this.size = 32,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.defaultAccent;
    final cardW = size * 0.72;
    final cardH = size * 0.95;
    final radius = size * 0.16;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Bottom-most card (angled left)
            Transform.translate(
              offset: Offset(-size * 0.10, size * 0.06),
              child: Transform.rotate(
                angle: -0.20,
                child: Container(
                  width: cardW,
                  height: cardH,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Middle card (angled right)
            Transform.translate(
              offset: Offset(size * 0.10, size * 0.04),
              child: Transform.rotate(
                angle: 0.16,
                child: Container(
                  width: cardW,
                  height: cardH,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: AppTheme.bgSubtle,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top active card (straight, floating forward with shadow)
            Transform.translate(
              offset: Offset(0, -size * 0.04),
              child: Container(
                width: cardW,
                height: cardH,
                padding: EdgeInsets.all(size * 0.14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini accent pip
                    Container(
                      width: size * 0.16,
                      height: size * 0.16,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(size * 0.06),
                      ),
                    ),
                    // Mini lines representing dish card layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: cardW * 0.65,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.textMain.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: cardW * 0.40,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.textLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
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
