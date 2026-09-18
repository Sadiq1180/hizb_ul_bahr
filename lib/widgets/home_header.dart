import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF043D2E), Color(0xFF075A45), Color(0xFF0A6E4A)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // --- Decorative background ---
          // Large soft glow behind badge
          Positioned(
            top: -80,
            left: -80,
            child: _glowCircle(260, const Color(0xFF38A56A)),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _glowCircle(240, const Color(0xFF0B7A50)),
          ),

          // Islamic geometric pattern (dots grid)
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          // Top decorative arc
          Positioned(
            top: -140,
            left: -40,
            right: -40,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A548).withValues(alpha: 0.18),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            top: -170,
            left: -40,
            right: -40,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A548).withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
            ),
          ),

          // --- Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emblem
                  const _Emblem(),

                  const Spacer(),

                  // Bismillah with new font style
                  const _BismillahText(),

                  const SizedBox(height: 14),

                  // Ornamental divider
                  const _OrnamentalDivider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

/// Emblem — octagonal frame with a circular medallion inside
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotated square (diamond) forming an octagon look
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFD4A548).withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
            ),
          ),
          // Outer ring
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4A548).withValues(alpha: 0.85),
                width: 1.6,
              ),
            ),
          ),
          // Inner medallion
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFEF7), Color(0xFFEFE1BE)],
              ),
              border: Border.all(color: const Color(0xFFD4A548), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFD4A548).withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Small decorative star
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFFD4A548),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppConstants.arabicNameFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: 0.6,
                        color: const Color(0xFF054A38),
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.9),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bismillah text with a refined, elegant font treatment
class _BismillahText extends StatelessWidget {
  const _BismillahText();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow behind text
        Container(
          width: 260,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: RadialGradient(
              colors: [
                const Color(0xFF38A56A).withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // The text itself
        const Text(
          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْم',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily:
                'Scheherazade', // elegant Arabic font — swap if unavailable
            fontSize: 30,
            fontWeight: FontWeight.w500,
            height: 1.8,
            letterSpacing: 1.0,
            color: Color(0xFFF7E9B8), // soft gold
            shadows: [
              Shadow(
                color: Color(0x99000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
              Shadow(color: Color(0x66D4A548), blurRadius: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ornamental divider: line — diamond — line
class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(),
        const SizedBox(width: 10),
        // Diamond shape
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A548),
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A548).withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _line(),
      ],
    );
  }

  Widget _line() {
    return Container(
      width: 56,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4A548).withValues(alpha: 0.0),
            const Color(0xFFD4A548).withValues(alpha: 0.8),
            const Color(0xFFD4A548).withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Subtle Islamic-style dot grid background
class _DotPatternPainter extends CustomPainter {
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
