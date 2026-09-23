import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/flip_sound.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:hizb_ul_bahr/features/widgets/chached_pdf_page_image.dart';
import 'package:hizb_ul_bahr/features/widgets/pdf_page_tile.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfBookPage extends StatefulWidget {
  const PdfBookPage({super.key, required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  State<PdfBookPage> createState() => _PdfBookPageState();
}

class _PdfBookPageState extends State<PdfBookPage> {
  final PageCurlController _bookController = PageCurlController();

  int _currentCurlPage = 0;
  bool _openedAtUrduFirstPage = false;

  SharedPreferences? _prefs;
  bool _prefsReady = false;
  int? _savedPdfPage;

  String get _prefsKey => 'pdf_last_page::${widget.assetPath}';
  String get _soundPrefsKey => 'pdf_sound_enabled::${widget.assetPath}';

  final ValueNotifier<bool> _zoomModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentPdfPageNotifier = ValueNotifier<int>(1);

  bool _zoomMode = false;
  bool _soundEnabled = true;

  PdfDocument? _cachedDocument;
  List<Widget>? _cachedPages;
  int _cachedTotalPages = 0;

  final PageImageCache _imageCache = PageImageCache(
    maxEntries: 20,
    maxThumbEntries: 60,
  );

  final FlipSoundPlayer _flipSound = FlipSoundPlayer();

  bool _suppressNextFlipSound = false;

  int get _currentPdfPage => _cachedTotalPages - _currentCurlPage;

  @override
  void initState() {
    super.initState();
    unawaited(_flipSound.init());
    _restoreProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _imageCache.renderWidthPx = (mq.size.width * mq.devicePixelRatio)
        .clamp(600.0, 1200.0)
        .toDouble();
  }

  @override
  void dispose() {
    if (_openedAtUrduFirstPage && _cachedTotalPages > 0) {
      _saveProgress(_currentPdfPage);
    }
    _zoomModeNotifier.dispose();
    _currentPdfPageNotifier.dispose();
    _bookController.dispose();
    _imageCache.dispose();
    _flipSound.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _savedPdfPage = prefs.getInt(_prefsKey);
      _soundEnabled = prefs.getBool(_soundPrefsKey) ?? true;
      _flipSound.enabled = _soundEnabled;
    } catch (_) {}
    _currentPdfPageNotifier.value = _savedPdfPage ?? 1;
    if (mounted) setState(() => _prefsReady = true);
  }

  void _saveProgress(int pdfPage) {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setInt(_prefsKey, pdfPage));
  }

  void _prefetchAround(PdfDocument document, int curlPage) {
    final pdfPage = _cachedTotalPages - curlPage;
    void queue(int page) {
      if (page < 1 || page > _cachedTotalPages) return;
      unawaited(_imageCache.loadThumb(document, page));
      unawaited(_imageCache.load(document, page));
    }

    queue(pdfPage);
    // Prefetch a wider ring than kLoadWindow so a flip never outruns memory.
    for (var d = 1; d <= kLoadWindow + 2; d++) {
      queue(pdfPage + d);
      queue(pdfPage - d);
    }
  }

  List<Widget> _buildPages(PdfDocument document, int totalPages) {
    return List.generate(totalPages, (index) {
      final pdfPageNumber = totalPages - index;
      return PdfPageTile(
        document: document,
        pdfPageNumber: pdfPageNumber,
        cache: _imageCache,
        zoomMode: _zoomModeNotifier,
        currentPdfPage: _currentPdfPageNotifier,
      );
    });
  }

  Widget _buildBackdropPage(PdfDocument document) {
    final nextCurlIndex = _currentCurlPage + 1;

    if (nextCurlIndex >= _cachedTotalPages) {
      return const ColoredBox(color: ReaderColors.paper);
    }

    final pdfPageNumber = _cachedTotalPages - nextCurlIndex;

    return Container(
      color: ReaderColors.paper,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedPdfPageImage(
              key: ValueKey('pdf_backdrop_$pdfPageNumber'),
              document: document,
              pageNumber: pdfPageNumber,
              cache: _imageCache,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleZoom() {
    setState(() => _zoomMode = !_zoomMode);
    _zoomModeNotifier.value = _zoomMode;
  }

  void _toggleSound() {
    setState(() => _soundEnabled = !_soundEnabled);
    _flipSound.enabled = _soundEnabled;
    if (!_soundEnabled) {
      unawaited(_flipSound.stopAll());
    }
    unawaited(_prefs?.setBool(_soundPrefsKey, _soundEnabled));
  }

  void _handlePageChanged(PdfDocument document, int page) {
    final skipSound = _suppressNextFlipSound;
    _suppressNextFlipSound = false;

    // Prefetch immediately, so the new page's neighbours are ready.
    _prefetchAround(document, page);

    // Update UI state on the NEXT frame, not now. This keeps the backdrop
    // (which reads _currentCurlPage) in sync with the curl animation
    // instead of jumping ahead by one frame — the source of the blink.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // NOTE: we deliberately do NOT call setState here. The page change
      // is already visible via the curl animation; rebuilding the whole
      // tree mid-flip is what produced the flicker. Only the notifier
      // needs to update.
      _currentCurlPage = page;
      _currentPdfPageNotifier.value = _cachedTotalPages - page;
      if (_openedAtUrduFirstPage) {
        _saveProgress(_cachedTotalPages - page);
      }
    });

    if (!skipSound) {
      unawaited(_flipSound.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReaderColors.background,
      // No AppBar — gives the page the whole screen height, so `contain`
      // crops nothing.
      body: SafeArea(
        // We only want SafeArea on top so the buttons don't sit under the
        // status bar; the page itself should extend underneath.
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            // ── PDF content, full-bleed ─────────────────────────────
            Positioned.fill(
              child: PdfDocumentViewBuilder.asset(
                widget.assetPath,
                builder: (context, document) {
                  if (document == null || !_prefsReady) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ReaderColors.accent,
                      ),
                    );
                  }

                  final totalPages = document.pages.length;

                  if (_cachedDocument != document ||
                      _cachedPages == null ||
                      _cachedTotalPages != totalPages) {
                    _cachedDocument = document;
                    _cachedTotalPages = totalPages;
                    _cachedPages = _buildPages(document, totalPages);
                  }

                  if (!_openedAtUrduFirstPage) {
                    final startPdfPage = (_savedPdfPage ?? 1).clamp(
                      1,
                      totalPages,
                    );
                    final startCurlPage = totalPages - startPdfPage;

                    _prefetchAround(document, startCurlPage);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _openedAtUrduFirstPage) return;

                      setState(() {
                        _openedAtUrduFirstPage = true;
                        _currentCurlPage = startCurlPage;
                      });
                      _currentPdfPageNotifier.value = startPdfPage;

                      _suppressNextFlipSound = true;
                      _bookController.jumpToPage(startCurlPage);
                    });
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBackdropPage(document),
                      IgnorePointer(
                        ignoring: _zoomMode,
                        child: PageCurlView(
                          controller: _bookController,
                          radius: 0.06,
                          shadowWidth: 0.14,
                          backOpacity: 1.0,
                          edgeZoneWidth: 0.30,
                          onPageChanged: (page) =>
                              _handlePageChanged(document, page),
                          children: _cachedPages!,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Floating toolbar over the page ──────────────────────
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _CircleButton(
                    icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
                    tooltip: _soundEnabled
                        ? 'Mute page sound'
                        : 'Unmute page sound',
                    onPressed: _toggleSound,
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: _zoomMode ? Icons.zoom_out_map : Icons.zoom_in_map,
                    tooltip: _zoomMode ? 'Exit zoom' : 'Zoom in',
                    onPressed: _toggleZoom,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small circular icon button meant to float over the page content.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        tooltip: tooltip,
      ),
    );
  }
}
