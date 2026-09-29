import 'dart:async';
import 'dart:ui' as ui;

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

  // ── BEAUTIFUL ISLAMIC BOTTOM BAR ──────────────────────────────
  // This builds the bottom bar with the sound button and Islamic design.
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100, // Height of the bottom bar
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF087055), // ReaderColors.appBar
              Color(0xFF075A45), // Darker shade for depth
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Subtle Islamic Pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: ReaderColors.accent.withValues(alpha: 0.15),
                ),
              ),
            ),

            // 2. Content (Sound Button)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return _buildSoundButton();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundButton() {
    final isEnabled = _controller.soundEnabled;
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _controller.toggleSound,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ReaderColors.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: isEnabled ? ReaderColors.accent : Colors.white70,
            size: 26,
          ),
        ),
      ),
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

    // Wait until the start page + neighbours are in the cache.
    if (!_controller.pagesReady) {
      if (!_preloadStarted) {
        _preloadStarted = true;
        unawaited(_controller.preloadInitialPages(document));
      }
      return _buildLoader();
    }

    // Create the curl controller exactly once.
    if (_bookController == null) {
      _bookController = PageCurlController(
        initialPage: _controller.computeStartCurlPage(),
      );
      _controller.attachBookController(_bookController!);
    }

    // Sync internal state AFTER the current frame finishes.
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
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 700,
              height: 1440,
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
      body: Stack(
        children: [
          // 1. The PDF Reader fills the entire screen
          Positioned.fill(
            child: PdfDocumentViewBuilder.asset(
              widget.assetPath,
              builder: (context, document) {
                if (document == null) return _buildLoader();

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

          // 2. The Header floats on top (Only Title + Page Number)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return ReaderHeader(
                  title: widget.title,
                  currentPage: _controller.currentPdfPage,
                  totalPages: _controller.totalPages == 0
                      ? 1
                      : _controller.totalPages,
                );
              },
            ),
          ),

          // 3. The Beautiful Islamic Bottom Bar (with Sound Button)
          _buildBottomBar(),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER FOR ISLAMIC PATTERN ──────────────────────────
// This draws a subtle geometric pattern for the bottom bar background.
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw a simple repeating diamond/star pattern
    final double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path();
        path.moveTo(x, y + step / 2);
        path.lineTo(x + step / 2, y);
        path.lineTo(x + step, y + step / 2);
        path.lineTo(x + step / 2, y + step);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
