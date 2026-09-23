import 'package:flutter/material.dart';

/// The gradient header shown above the PDF content in the reader.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    super.key,
    required this.title,
    required this.soundEnabled,
    required this.onToggleSound,
    required this.currentPage,
    required this.totalPages,
    this.onBack,
  });

  final String title;
  final bool soundEnabled;
  final VoidCallback onToggleSound;
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
          // ── Back button ────────────────────────────────
          // _GlassButton(
          //   icon: Icons.arrow_back_rounded,
          //   tooltip: 'Back',
          //   onTap: onBack ?? () => Navigator.of(context).maybePop(),
          // ),
          const SizedBox(width: 4),

          // ── Title + page counter ───────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'صفحہ $currentPage / $totalPages',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Sound toggle ───────────────────────────────
          _GlassButton(
            icon: soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            tooltip: soundEnabled ? 'Mute page sound' : 'Unmute page sound',
            onTap: onToggleSound,
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .16),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: Icon(icon, color: Colors.white, size: 22)),
          ),
        ),
      ),
    );
  }
}
