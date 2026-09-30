import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/pdfBook/widgets/pdf_reader_controller.dart';

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({super.key, required this.controller});

  final PdfReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF087055), // ReaderColors.appBar
              Color(0xFF075A45), // Darker shade for depth
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Subtle Islamic pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: ReaderColors.accent.withValues(alpha: 0.15),
                ),
              ),
            ),

            // 2. Sound button
            Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => _SoundButton(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundButton extends StatelessWidget {
  const _SoundButton({required this.controller});

  final PdfReaderController controller;

  @override
  Widget build(BuildContext context) {
    final isEnabled = controller.soundEnabled;
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.toggleSound,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ReaderColors.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: isEnabled ? ReaderColors.accent : Colors.white70,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Custom painter for the Islamic pattern ─────────────────────
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path();
        path.moveTo(x, y + step / 2);
        path.lineTo(x + step / 2, y);
        path.lineTo(x + step, y + step / 2);
        path.lineTo(x + step / 2, y + step);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
