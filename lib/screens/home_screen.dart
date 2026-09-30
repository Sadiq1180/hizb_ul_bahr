import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/pdfbook/pdf_book_page.dart';
import 'package:hizb_ul_bahr/screens/Homescreen%20Widgets/animated_in.dart';
import 'package:hizb_ul_bahr/screens/Homescreen%20Widgets/book_hero.dart';
import 'package:hizb_ul_bahr/screens/Homescreen%20Widgets/info.dart';
import 'package:hizb_ul_bahr/widgets/home_footer.dart';
import 'package:hizb_ul_bahr/widgets/home_header/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _openBook() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PdfBookPage(
          assetPath: AppConstants.bookAsset,
          title: AppConstants.appName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    AnimatedIn(
                      visible: _visible,
                      child: BookHeroCard(onTap: _openBook),
                    ),
                    const SizedBox(height: 18),
                    AnimatedIn(
                      visible: _visible,
                      delayMs: 120,
                      child: const InfoStrip(),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // const HomeFooter(),
            SizedBox(height: 14 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
