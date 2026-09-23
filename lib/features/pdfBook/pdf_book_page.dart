import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/pdfBook/widgets/pdf_reader_controller.dart';
import 'package:hizb_ul_bahr/features/pdfBook/widgets/pdf_reader_header.dart';
import 'package:hizb_ul_bahr/features/widgets/chached_pdf_page_image.dart';
import 'package:hizb_ul_bahr/features/widgets/pdf_page_tile.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfBookPage extends StatefulWidget {
  const PdfBookPage({super.key, required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  State<PdfBookPage> createState() => _PdfBookPageState();
}

class _PdfBookPageState extends State<PdfBookPage> {
  late final PageCurlController _bookController;
  late final PdfReaderController _controller;

  @override
  void initState() {
    super.initState();
    _bookController = PageCurlController();
    _controller = PdfReaderController(
      assetPath: widget.assetPath,
      bookController: _bookController,
    );
    unawaited(_controller.init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    final width = (mq.size.width * mq.devicePixelRatio)
        .clamp(600.0, 1200.0)
        .toDouble();
    _controller.setRenderWidth(width);
  }

  @override
  void dispose() {
    _controller.dispose();
    _bookController.dispose();
    super.dispose();
  }

  // ── Page builders (pure UI) ───────────────────────────────────

  List<Widget> _buildPages(PdfDocument document) {
    final total = document.pages.length;
    return List.generate(total, (index) {
      final pdfPageNumber = total - index;
      return PdfPageTile(
        document: document,
        pdfPageNumber: pdfPageNumber,
        cache: _controller.imageCache,
        zoomMode: _controller.zoomModeNotifier,
        currentPdfPage: _controller.currentPdfPageNotifier,
      );
    });
  }

  Widget _buildBackdrop(PdfDocument document) {
    final pdfPageNumber = _controller.backdropPdfPage;
    if (pdfPageNumber == null) {
      return const ColoredBox(color: ReaderColors.paper);
    }
    return ColoredBox(
      color: ReaderColors.paper,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedPdfPageImage(
              key: ValueKey('pdf_backdrop_$pdfPageNumber'),
              document: document,
              pageNumber: pdfPageNumber,
              cache: _controller.imageCache,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReader(PdfDocument document) {
    // Cache pages the first time we see a document of a given size.
    if (_controller.document != document ||
        _controller.pages == null ||
        _controller.totalPages != document.pages.length) {
      _controller.attachDocument(document, _buildPages(document));

      // Schedule the initial jump on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpToStartPage();
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackdrop(document),
        IgnorePointer(
          ignoring: _controller.zoomMode,
          child: PageCurlView(
            controller: _bookController,
            radius: 0.06,
            shadowWidth: 0.14,
            backOpacity: 1.0,
            edgeZoneWidth: 0.30,
            onPageChanged: _controller.onCurlPageChanged,
            children: _controller.pages!,
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fill every pixel — no white sliver behind system bars.
      backgroundColor: ReaderColors.paper,
      extendBody: true,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              ReaderHeader(
                title: widget.title,
                soundEnabled: _controller.soundEnabled,
                onToggleSound: _controller.toggleSound,
                currentPage: _controller.currentPdfPage,
                totalPages: _controller.totalPages == 0
                    ? 1
                    : _controller.totalPages,
              ),
              Expanded(
                child: ColoredBox(
                  color: ReaderColors.paper,
                  child: PdfDocumentViewBuilder.asset(
                    widget.assetPath,
                    builder: (context, document) {
                      if (document == null || !_controller.prefsReady) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: ReaderColors.accent,
                          ),
                        );
                      }
                      return _buildReader(document);
                    },
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
