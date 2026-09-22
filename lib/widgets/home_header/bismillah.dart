import 'package:flutter/material.dart';

/// Bismillah text with a refined, illuminated calligraphic treatment.
/// Clean, no glow behind the text, with a gold shimmer sweep.
class BismillahText extends StatefulWidget {
  const BismillahText({
    super.key,
    this.fontSize = 22,
    this.animate = true,
    this.showFrame = true,
    this.text = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْم',
  });

  final double fontSize;
  final bool animate;
  final bool showFrame;
  final String text;

  @override
  State<BismillahText> createState() => _BismillahTextState();
}

class _BismillahTextState extends State<BismillahText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  static const Color _gold = Color(0xFFD4A548);

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.animate) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showFrame) ...[_frameLine(), const SizedBox(height: 8)],
        _buildText(),
        if (widget.showFrame) ...[const SizedBox(height: 8), _frameLine()],
      ],
    );
  }

  // ---------------------------------------------------------------- TEXT
  Widget _buildText() {
    final baseText = Text(
      widget.text,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Scheherazade',
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w600,
        height: 1.7,
        letterSpacing: 0.8,
        color: Colors.white,
        shadows: const [
          // Only a subtle drop shadow for depth — no glow
          Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );

    // Metallic gold gradient fill for the text
    final gradientText = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF3C4), // bright cream highlight
          Color(0xFFF7E9B8), // soft gold
          Color(0xFFD4A548), // deeper gold
          Color(0xFFB8862F), // shadowed gold
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(bounds),
      child: baseText,
    );

    if (!widget.animate) return gradientText;

    // Gold shimmer sweep across the letters
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.plus,
                shaderCallback: (bounds) {
                  final t = _shimmer.value;
                  return LinearGradient(
                    begin: Alignment(-1.5 + 3.0 * t, 0),
                    end: Alignment(-0.5 + 3.0 * t, 0),
                    colors: [
                      _gold.withValues(alpha: 0.0),
                      const Color(0xFFFFE9A8).withValues(alpha: 0.75),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ).createShader(bounds);
                },
                child: child,
              ),
            ),
          ],
        );
      },
      child: gradientText,
    );
  }

  // ---------------------------------------------------------------- FRAME
  Widget _frameLine() {
    return SizedBox(
      width: widget.fontSize * 10,
      height: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gold.withValues(alpha: 0.0),
              _gold.withValues(alpha: 0.7),
              _gold.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
