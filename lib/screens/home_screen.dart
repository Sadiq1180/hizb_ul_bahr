import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/models/menu_items.dart';
import 'package:hizb_ul_bahr/screens/pdfbook.dart';
import 'package:hizb_ul_bahr/widgets/home_footer.dart';
import 'package:hizb_ul_bahr/widgets/home_header/home_header.dart';
import 'package:hizb_ul_bahr/widgets/menu_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _menuItems = <MenuItem>[
    MenuItem(
      title: 'کتاب',
      subtitle: 'مکمل متن اور ترجمہ',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF087055), Color(0xFF2DA66B)],
    ),
    MenuItem(
      title: 'مختصر تعارف',
      subtitle: 'چند سطروں میں تعارف',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF126B83), Color(0xFF35A4B5)],
    ),
    MenuItem(
      title: 'حضرت شیخ صاحب کے بارے میں',
      subtitle: 'سوانح حیات اور خدمات',
      icon: Icons.person_outline_rounded,
      colors: [Color(0xFF644582), Color(0xFF9A6BBA)],
    ),
    MenuItem(
      title: 'رابطہ',
      subtitle: 'ہم سے رابطہ کریں',
      icon: Icons.phone_in_talk_rounded,
      colors: [Color(0xFFA3631C), Color(0xFFD89B3D)],
    ),
  ];

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _onMenuTap(int index) {
    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PdfBookPage(
            assetPath: AppConstants.bookAsset,
            title: AppConstants.appName,
          ),
        ),
      );
      return;
    }

    /// scaffold messenger to show a snackbar for unavailable features
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: EdgeInsets.zero,
          duration: const Duration(milliseconds: 1500),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsetsDirectional.only(
                  start: 18,
                  end: 8,
                  top: 10,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      const Color(0xFF145C4A).withValues(alpha: 0.88),
                      const Color(0xFF0C493B).withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF7FE0C1).withValues(alpha: 0.08),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Glass icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFFE6FFF6),
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        '${_menuItems[index].title} جلد دستیاب ہوگا',
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // iOS-style action button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          messenger.hideCurrentSnackBar();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Text(
                            'ٹھیک ہے',
                            style: TextStyle(
                              color: Color(0xFFD9FFF1),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0A604B),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (int index = 0; index < _menuItems.length; index++) ...[
                      AnimatedSlide(
                        duration: Duration(milliseconds: 450 + index * 90),
                        curve: Curves.easeOutCubic,
                        offset: _visible ? Offset.zero : const Offset(0, .25),
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 450 + index * 90),
                          opacity: _visible ? 1 : 0,
                          child: MenuButton(
                            item: _menuItems[index],
                            onTap: () => _onMenuTap(index),
                          ),
                        ),
                      ),
                      if (index != _menuItems.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const HomeFooter(),
            SizedBox(height: 14 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
