import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/screens/Homescreen%20Widgets/decorated_circle.dart';
import 'package:hizb_ul_bahr/screens/Homescreen%20Widgets/read_now_button.dart';

/// The main gradient hero card that promotes the book.
class BookHeroCard extends StatelessWidget {
  const BookHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF087055), Color(0xFF2DA66B)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33087055),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // decorative circles
              const Positioned(
                top: -30,
                right: -30,
                child: DecorativeCircle(size: 130, opacity: .10),
              ),
              const Positioned(
                bottom: -40,
                left: -20,
                child: DecorativeCircle(size: 100, opacity: .08),
              ),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconBadge(),
                    const SizedBox(height: 22),
                    const _HeroTitle(),
                    const SizedBox(height: 26),
                    Center(child: ReadNowButton(onTap: onTap)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: Text(
            'کتاب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'مکمل متن اور ترجمہ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
