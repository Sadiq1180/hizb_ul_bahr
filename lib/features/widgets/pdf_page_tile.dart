import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:hizb_ul_bahr/features/widgets/zomable_pdf.dart';
import 'package:pdfrx/pdfrx.dart';

/// A single page tile inside the curl view: the zoomable page image plus a
/// small page-number badge at the bottom.
class PdfPageTile extends StatelessWidget {
  const PdfPageTile({
    super.key,
    required this.document,
    required this.pdfPageNumber,
    required this.cache,
    required this.zoomMode,
    required this.currentPdfPage,
  });

  final PdfDocument document;
  final int pdfPageNumber;
  final PageImageCache cache;
  final ValueNotifier<bool> zoomMode;
  final ValueNotifier<int> currentPdfPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('pdf_page_$pdfPageNumber'),
      color: ReaderColors.paper,
      child: Stack(
        children: [
          Positioned.fill(
            child: ZoomablePdfPage(
              key: ValueKey('pdf_cached_$pdfPageNumber'),
              document: document,
              pageNumber: pdfPageNumber,
              cache: cache,
              zoomMode: zoomMode,
              currentPdfPage: currentPdfPage,
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ReaderColors.paper.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pdfPageNumber',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: ReaderColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
