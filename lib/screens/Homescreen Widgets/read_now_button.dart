import 'package:flutter/material.dart';

/// A polished, pressable "Read now" CTA button.
class ReadNowButton extends StatefulWidget {
  const ReadNowButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<ReadNowButton> createState() => _ReadNowButtonState();
}

class _ReadNowButtonState extends State<ReadNowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B8A63), Color(0xFF19A56D), Color(0xFF32C48A)],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: .28),
            width: 1.2,
          ),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                    color: Color(0x33087055),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x4D087055),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconCircle(),
            const SizedBox(width: 12),
            const Text(
              'پڑھنا شروع کریں',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .22),
        border: Border.all(
          color: Colors.white.withValues(alpha: .35),
          width: 1,
        ),
      ),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        offset: _pressed ? const Offset(.15, 0) : Offset.zero,
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
