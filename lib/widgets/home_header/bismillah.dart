import 'package:flutter/material.dart';

/// Bismillah text with a refined, elegant font treatment
class BismillahText extends StatelessWidget {
  const BismillahText({super.key});

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
