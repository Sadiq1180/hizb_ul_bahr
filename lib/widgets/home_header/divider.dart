import 'package:flutter/material.dart';

/// Ornamental divider: line — diamond — line
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key});

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
