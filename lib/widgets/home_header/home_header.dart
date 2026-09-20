import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/widgets/home_header/bismillah.dart';
import 'package:hizb_ul_bahr/widgets/home_header/divider.dart';
import 'package:hizb_ul_bahr/widgets/home_header/dot_pattern.dart';

import 'emblem.dart';

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
          Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),

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
                children: const [
                  // Emblem
                  Emblem(),

                  Spacer(),

                  // Bismillah with new font style
                  BismillahText(),

                  SizedBox(height: 14),

                  // Ornamental divider
                  OrnamentalDivider(),
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
