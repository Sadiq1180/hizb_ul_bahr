import 'package:flutter/material.dart';

/// Ornamental divider: line — diamond — line
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key});

  static const Color _gold = Color(0xFFD4A548);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(fadeToLeft: true),
        const SizedBox(width: 14),
        _diamond(),
        const SizedBox(width: 14),
        _line(fadeToLeft: false),
      ],
    );
  }

  /// A thin line that fades toward the outer edge.
  Widget _line({required bool fadeToLeft}) {
    final colors = fadeToLeft
        ? [_gold.withValues(alpha: 0.0), _gold.withValues(alpha: 0.7)]
        : [_gold.withValues(alpha: 0.7), _gold.withValues(alpha: 0.0)];

    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: fadeToLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: fadeToLeft ? Alignment.centerRight : Alignment.centerLeft,
          ),
        ),
      ),
    );
  }

  /// A softly glowing rotated square.
  Widget _diamond() {
    return Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.55),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
    );
  }
}
