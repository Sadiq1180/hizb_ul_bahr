import 'package:flutter/material.dart';

/// Islamic-inspired geometric background pattern.
class DotPatternPainter extends CustomPainter {
  const DotPatternPainter({this.brightness = 1.0});

  /// Controls pattern visibility.
  ///
  /// 1.0 = normal
  /// 1.5 = brighter
  /// 2.0 = much brighter
  /// 0.5 = dimmer
  final double brightness;

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFC3A05A);
    const green = Color(0xFF17634F);

    final dotPaint = Paint()
      ..color = gold.withValues(alpha: (0.28 * brightness).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final smallDotPaint = Paint()
      ..color = gold.withValues(alpha: (0.20 * brightness).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = gold.withValues(alpha: (0.13 * brightness).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final greenPaint = Paint()
      ..color = green.withValues(alpha: (0.10 * brightness).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    const spacing = 44.0;

    for (double y = 22; y < size.height + spacing; y += spacing) {
      for (double x = 22; x < size.width + spacing; x += spacing) {
        final row = ((y - 22) / spacing).round();
        final column = ((x - 22) / spacing).round();
        final alternate = (row + column).isEven;

        // Main dot.
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);

        if (alternate) {
          // Surrounding dots.
          canvas.drawCircle(Offset(x + 9, y), 1.1, smallDotPaint);

          canvas.drawCircle(Offset(x - 9, y), 1.1, smallDotPaint);

          canvas.drawCircle(Offset(x, y + 9), 1.1, smallDotPaint);

          canvas.drawCircle(Offset(x, y - 9), 1.1, smallDotPaint);

          // Soft green center.
          canvas.drawCircle(Offset(x, y), 4.5, greenPaint);

          // Diamond.
          final diamond = Path()
            ..moveTo(x, y - 7)
            ..lineTo(x + 7, y)
            ..lineTo(x, y + 7)
            ..lineTo(x - 7, y)
            ..close();

          canvas.drawPath(diamond, linePaint);
        } else {
          // Small diamond.
          final diamond = Path()
            ..moveTo(x, y - 5)
            ..lineTo(x + 5, y)
            ..lineTo(x, y + 5)
            ..lineTo(x - 5, y)
            ..close();

          canvas.drawPath(diamond, linePaint);
        }
      }
    }

    // Diagonal geometric lines.
    const diagonalSpacing = 88.0;

    for (
      double start = -size.height;
      start < size.width + size.height;
      start += diagonalSpacing
    ) {
      canvas.drawLine(
        Offset(start, 0),
        Offset(start + size.height, size.height),
        linePaint,
      );
    }

    for (
      double start = 0;
      start < size.width + size.height;
      start += diagonalSpacing
    ) {
      canvas.drawLine(
        Offset(start, 0),
        Offset(start - size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DotPatternPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}
