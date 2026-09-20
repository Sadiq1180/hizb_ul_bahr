import 'package:flutter/material.dart';

/// Subtle Islamic-style dot grid background
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.4;

    for (double y = 20; y < size.height; y += spacing) {
      for (double x = 20; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
