import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';

/// Premium Islamic emblem with an octagonal frame and circular medallion.
class Emblem extends StatelessWidget {
  const Emblem({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF17634F);
    const darkGreen = Color(0xFF29453D);
    const gold = Color(0xFFC3A05A);
    const ivory = Color(0xFFFCFBF7);
    const softIvory = Color(0xFFF1E9D6);

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.16),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Rotated square creating the octagonal frame
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: gold.withValues(alpha: 0.48),
                  width: 1.3,
                ),
              ),
            ),
          ),

          // Small inner octagonal detail
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: green.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
          ),

          // Outer circular ring
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ivory.withValues(alpha: 0.18),
              border: Border.all(
                color: gold.withValues(alpha: 0.68),
                width: 1.5,
              ),
            ),
          ),

          // Inner medallion
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ivory, softIvory],
              ),
              border: Border.all(
                color: gold.withValues(alpha: 0.82),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: gold.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decorative star
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: green.withValues(alpha: 0.06),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: gold,
                    ),
                  ),

                  const SizedBox(height: 5),

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
                        letterSpacing: 0.4,
                        color: darkGreen,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.65),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Small decorative line
                  Container(
                    width: 30,
                    height: 1.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: gold.withValues(alpha: 0.55),
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
