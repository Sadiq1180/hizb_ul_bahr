import 'package:flutter/material.dart';

/// A beautiful, purely decorative Islamic-styled card.
/// No text — just a rich pattern and a gold icon badge.
class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 90, // Fixed height for a slim banner look
      decoration: BoxDecoration(
        // Rich Islamic green gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A604B), // Deep green
            Color(0xFF087055), // Mid green
            Color(0xFF075A45), // Darker green
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400A604B),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Subtle Islamic Pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _InfoPatternPainter(
                  color: const Color(0xFFD4A548)
                      .withValues(alpha: 0.10), // Gold
                ),
              ),
            ),
          ),

          // 2. Centered Gold Icon Badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Soft gold gradient circle
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4A548), // Gold
                    Color(0xFFB88A3E), // Darker gold
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4A548).withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),

          // 3. Optional: Decorative side lines (like a classic Islamic banner)
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFFD4A548)],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A548), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER FOR SUBTLE ISLAMIC PATTERN ──────────────────
class _InfoPatternPainter extends CustomPainter {
  final Color color;
  _InfoPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw a repeating 8-pointed star (Khatam) pattern
    const double step = 30.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path();
        path.moveTo(x, y + step / 3);
        path.lineTo(x + step / 3, y);
        path.lineTo(x + 2 * step / 3, y + step / 3);
        path.lineTo(x + step, y);
        path.lineTo(x + 2 * step / 3, y + 2 * step / 3);
        path.lineTo(x + step, y + step);
        path.lineTo(x + 2 * step / 3, y + 2 * step / 3);
        path.lineTo(x + step / 3, y + step);
        path.lineTo(x, y + 2 * step / 3);
        path.lineTo(x + step / 3, y + step / 3);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
