import 'package:flutter/material.dart';

/// The gradient header shown above the PDF content in the reader.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    this.onBack,
  });

  final String title;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topInset + 8,
        bottom: 12,
        left: 6,
        right: 6,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF087055), Color(0xFF1F9A6B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Back button (Commented out as per original) ──
          // _GlassButton(
          //   icon: Icons.arrow_back_rounded,
          //   tooltip: 'Back',
          //   onTap: onBack ?? () => Navigator.of(context).maybePop(),
          // ),
          // const SizedBox(width: 4),

          // ── Title + page counter (Centered now) ────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Centered
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'صفحہ $currentPage / $totalPages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
