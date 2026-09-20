import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';

/// Emblem — octagonal frame with a circular medallion inside
class Emblem extends StatelessWidget {
  const Emblem({super.key});

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
