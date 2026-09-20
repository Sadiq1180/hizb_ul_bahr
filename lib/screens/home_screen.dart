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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_menuItems[index].title} جلد دستیاب ہوگا')),
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
