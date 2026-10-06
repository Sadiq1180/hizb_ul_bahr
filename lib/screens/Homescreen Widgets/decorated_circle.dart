import 'package:flutter/material.dart';

/// A soft glass-like decorative circle used inside gradient cards.
class DecorativeCircle extends StatelessWidget {
  const DecorativeCircle({
    super.key,
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 0.75,
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: opacity * 0.45),
              Colors.white.withValues(alpha: opacity * 0.08),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity * 0.75),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: opacity * 0.35),
              blurRadius: size * 0.12,
              spreadRadius: size * 0.015,
            ),
          ],
        ),
      ),
    );
  }
}
