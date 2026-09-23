import 'package:flutter/material.dart';

/// A white card that gives a short introduction to the book.
class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A604B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(),
          const SizedBox(width: 14),
          const Expanded(child: _InfoContent()),
        ],
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF087055),
        size: 22,
      ),
    );
  }
}

class _InfoContent extends StatelessWidget {
  const _InfoContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حزب البحر',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A2A22),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'حضرت شیخ ابو الحسن الشاذلی رحمۃ اللہ علیہ کی مشہور دعا، '
          'آسان اردو ترجمے کے ساتھ مکمل متن۔',
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF5A6B65)),
        ),
      ],
    );
  }
}
