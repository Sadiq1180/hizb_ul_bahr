import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 18, height: 1, color: const Color(0xFFBFD1C7)),
            const SizedBox(width: 6),
            const Icon(
              Icons.auto_awesome_rounded,
              size: 12,
              color: Color(0xFF779087),
            ),
            const SizedBox(width: 6),
            Container(width: 18, height: 1, color: const Color(0xFFBFD1C7)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          AppConstants.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
