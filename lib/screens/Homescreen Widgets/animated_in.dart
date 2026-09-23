import 'package:flutter/material.dart';

/// Fades + slides a child into view when [visible] becomes true.
class AnimatedIn extends StatelessWidget {
  const AnimatedIn({
    super.key,
    required this.visible,
    required this.child,
    this.delayMs = 0,
  });

  final bool visible;
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 450 + delayMs);
    return AnimatedSlide(
      duration: duration,
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, .18),
      child: AnimatedOpacity(
        duration: duration,
        opacity: visible ? 1 : 0,
        child: child,
      ),
    );
  }
}
