import 'package:flutter/material.dart';

/// A small circular icon button meant to float over page content.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background = const Color(0x73000000),
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        tooltip: tooltip,
        iconSize: 22,
        splashRadius: 22,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
