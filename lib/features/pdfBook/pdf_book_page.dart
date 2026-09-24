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
  late final PdfReaderController _controller;

  PageCurlController? _bookController;

  PdfDocument? _attachedDocument;

  /// Guards the post-frame "mark opened" so it only runs once per document.
  bool _openedScheduled = false;

  /// Guards the initial image preload so it only starts once per document.
  bool _preloadStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfReaderController(assetPath: widget.assetPath);
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
    _bookController?.dispose();
    super.dispose();
  }

  // ── Page builders ─────────────────────────────────────────────

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
    final current = _controller.backdropPdfPage;
    if (current == null) {
      return const ColoredBox(color: ReaderColors.paper);
    }

    final total = document.pages.length;
    final nextCurlIndex = _controller.currentCurlPage + 2;
    final nextPdf = nextCurlIndex < total ? total - nextCurlIndex : null;

    return ColoredBox(
      color: ReaderColors.paper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (nextPdf != null)
            Positioned.fill(
              child: CachedPdfPageImage(
                key: ValueKey('pdf_backdrop_next_$nextPdf'),
                document: document,
                pageNumber: nextPdf,
                cache: _controller.imageCache,
              ),
            ),
          Positioned.fill(
            child: CachedPdfPageImage(
              key: ValueKey('pdf_backdrop_$current'),
              document: document,
              pageNumber: current,
              cache: _controller.imageCache,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: ReaderColors.accent),
    );
  }

  Widget _buildReader(PdfDocument document) {
    // Attach the document once per identity.
    if (!identical(_attachedDocument, document)) {
      _attachedDocument = document;
      _openedScheduled = false;
      _preloadStarted = false;
      _controller.attachDocument(document, _buildPages(document));
    }

    // Wait until the start page + neighbours are in the cache. Showing the
    // curl view earlier makes it capture loading placeholders, which is why
    // the pages stayed blank until the first page turn.
    if (!_controller.pagesReady) {
      if (!_preloadStarted) {
        _preloadStarted = true;
        unawaited(_controller.preloadInitialPages(document));
      }
      return _buildLoader();
    }

    // Create the curl controller exactly once, with the correct
    // `initialPage` so the view opens on the saved page immediately.
    if (_bookController == null) {
      _bookController = PageCurlController(
        initialPage: _controller.computeStartCurlPage(),
      );
      _controller.attachBookController(_bookController!);
    }

    // Sync internal state AFTER the current frame finishes, so we never
    // notify during build.
    if (!_openedScheduled && !_controller.openedAtStartPage) {
      _openedScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.markOpenedAtStartPage(deferNotify: true);
        _controller.notifySafely();
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackdrop(document),
        IgnorePointer(
          ignoring: _controller.zoomMode,
          child: PageCurlView(
            key: ValueKey('curl_${identityHashCode(document)}'),
            controller: _bookController!,
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
      backgroundColor: ReaderColors.paper,
      extendBody: true,
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ReaderHeader(
                title: widget.title,
                soundEnabled: _controller.soundEnabled,
                onToggleSound: _controller.toggleSound,
                currentPage: _controller.currentPdfPage,
                totalPages: _controller.totalPages == 0
                    ? 1
                    : _controller.totalPages,
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: ReaderColors.paper,
              // Document loader stays OUTSIDE so it never rebuilds on
              // page turns.
              child: PdfDocumentViewBuilder.asset(
                widget.assetPath,
                builder: (context, document) {
                  if (document == null) return _buildLoader();

                  // Only the reader listens to the controller.
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      if (!_controller.prefsReady) return _buildLoader();
                      return _buildReader(document);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
