import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/pdfBook/widgets/pdf_reader_controller.dart';
import 'package:hizb_ul_bahr/features/pdfBook/widgets/pdf_reader_header.dart';

class ReaderAppBar extends StatelessWidget {
  const ReaderAppBar({
    super.key,
    required this.controller,
    required this.title,
    this.onBack,
  });

  final PdfReaderController controller;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Existing header underneath
              ReaderHeader(
                title: title,
                currentPage: controller.currentPdfPage,
                totalPages: controller.totalPages == 0
                    ? 1
                    : controller.totalPages,
              ),

              // Back button — left edge, vertically centered with the header
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _BorderedBackButton(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BorderedBackButton extends StatelessWidget {
  const _BorderedBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 4, left: 6, right: 6),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ReaderColors.accent.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_outlined,
            color: Colors.yellow,
            size: 20,
          ),
        ),
      ),
    );
  }
}
