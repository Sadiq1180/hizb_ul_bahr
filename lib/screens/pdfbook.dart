import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:pdfrx/pdfrx.dart';

const _readerArabicFont = 'Amiri';

/// Render scale for pre-rasterized pages. 1.6 keeps text crisp on most
/// phones while using far less memory than 2.0+.
const double _kPageRenderScale = 1.6;

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

  /// When true, the curl is wrapped in an InteractiveViewer so the user
  /// can pinch-zoom and pan. The curl is disabled while this is on.
  bool _zoomMode = false;

  PdfDocument? _cachedDocument;
  List<Widget>? _cachedPages;
  int _cachedTotalPages = 0;

  final _PageImageCache _imageCache = _PageImageCache(maxEntries: 8);
  final Set<int> _rendering = <int>{};

  // Tracks for rebuild detection.
  bool _lastZoomMode = false;
  int _lastZoomPdfPage = 0;

  int get _currentPdfPage => _cachedTotalPages - _currentCurlPage;

  @override
  void dispose() {
    _bookController.dispose();
    _imageCache.dispose();
    super.dispose();
  }

  Future<void> _prefetchPage(PdfDocument document, int pdfPageNumber) async {
    if (pdfPageNumber < 1 || pdfPageNumber > _cachedTotalPages) return;
    if (_imageCache.contains(pdfPageNumber)) return;
    if (_rendering.contains(pdfPageNumber)) return;

    _rendering.add(pdfPageNumber);
    try {
      final page = document.pages[pdfPageNumber - 1];
      final pdfImage = await page.render(
        fullWidth: page.width * _kPageRenderScale,
        fullHeight: page.height * _kPageRenderScale,
      );
      if (pdfImage == null) return;
      final image = await pdfImage.createImage();
      _imageCache.put(pdfPageNumber, image);
    } catch (_) {
      // ignore
    } finally {
      _rendering.remove(pdfPageNumber);
    }
  }

  void _prefetchAround(PdfDocument document, int curlPage) {
    final candidates = <int>[
      curlPage + 1,
      curlPage - 1,
      curlPage + 2,
      curlPage - 2,
    ];
    for (final c in candidates) {
      if (c < 0 || c >= _cachedTotalPages) continue;
      final pdfPageNumber = _cachedTotalPages - c;
      _prefetchPage(document, pdfPageNumber);
    }
  }

  List<Widget> _buildPages(PdfDocument document, int totalPages) {
    // Reversed for Urdu.
    return List.generate(totalPages, (index) {
      final pdfPageNumber = totalPages - index;

      return Container(
        key: ValueKey('pdf_page_$pdfPageNumber'),
        color: const Color(0xFFFFFCF5),
        child: Stack(
          children: [
            Positioned.fill(
              child: _ZoomablePdfPage(
                key: ValueKey('pdf_cached_$pdfPageNumber'),
                document: document,
                pageNumber: pdfPageNumber,
                cache: _imageCache,
                // Only the page currently under the curl may zoom. All
                // other pages must stay plain so the curl can receive
                // drag gestures.
                interactive: _zoomMode && pdfPageNumber == _currentPdfPage,
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
                      color: const Color(0xFFFFFCF5).withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pdfPageNumber',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFF49675C),
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
    });
  }

  Widget _buildBackdropPage(PdfDocument document) {
    final nextCurlIndex = _currentCurlPage + 1;

    if (nextCurlIndex >= _cachedTotalPages) {
      return const ColoredBox(color: Color(0xFFFFFCF5));
    }

    final pdfPageNumber = _cachedTotalPages - nextCurlIndex;

    return Container(
      color: const Color(0xFFFFFCF5),
      child: Stack(
        children: [
          Positioned.fill(
            child: _CachedPdfPageImage(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF193B33),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF075A45),
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: _readerArabicFont,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleZoom,
            icon: Icon(_zoomMode ? Icons.zoom_out_map : Icons.zoom_in_map),
            tooltip: _zoomMode ? 'Exit zoom' : 'Zoom in',
          ),
        ],
      ),
      body: PdfDocumentViewBuilder.asset(
        widget.assetPath,
        builder: (context, document) {
          if (document == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A548)),
            );
          }

          final totalPages = document.pages.length;

          // Rebuild the page list when document OR zoom mode OR current
          // PDF page changes (so only the current page becomes interactive).
          if (_cachedDocument != document ||
              _cachedPages == null ||
              _cachedTotalPages != totalPages) {
            _cachedDocument = document;
            _cachedTotalPages = totalPages;
            _cachedPages = _buildPages(document, totalPages);
          } else if (_zoomMode != _lastZoomMode ||
              _lastZoomPdfPage != _currentPdfPage) {
            _cachedPages = _buildPages(document, totalPages);
          }
          _lastZoomMode = _zoomMode;
          _lastZoomPdfPage = _currentPdfPage;

          if (!_openedAtUrduFirstPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _openedAtUrduFirstPage) return;

              setState(() {
                _openedAtUrduFirstPage = true;
                _currentCurlPage = totalPages - 1;
              });

              _bookController.jumpToPage(totalPages - 1);
              _prefetchAround(document, totalPages - 1);
            });
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 18,
                            offset: Offset(4, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildBackdropPage(document),
                            // Disable the curl entirely while in zoom
                            // mode so InteractiveViewer gets all gestures.
                            IgnorePointer(
                              ignoring: _zoomMode,
                              child: PageCurlView(
                                controller: _bookController,
                                radius: 0.06,
                                shadowWidth: 0.14,
                                backOpacity: 1.0,
                                edgeZoneWidth: 0.30,
                                onPageChanged: (page) {
                                  setState(() => _currentCurlPage = page);
                                  _prefetchAround(document, page);
                                },
                                children: _cachedPages!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'صفحہ ${_currentPdfPage} / $totalPages',
                  style: const TextStyle(
                    color: Color(0xFFE2EDE6),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

/// Renders a single PDF page as a static [ui.Image]. If [interactive] is
/// true, wraps it in an InteractiveViewer for pinch-zoom and pan.
class _ZoomablePdfPage extends StatefulWidget {
  const _ZoomablePdfPage({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.cache,
    required this.interactive,
  });

  final PdfDocument document;
  final int pageNumber;
  final _PageImageCache cache;
  final bool interactive;

  @override
  State<_ZoomablePdfPage> createState() => _ZoomablePdfPageState();
}

class _ZoomablePdfPageState extends State<_ZoomablePdfPage> {
  ui.Image? _image;
  bool _failed = false;

  final TransformationController _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ZoomablePdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.document != widget.document) {
      _image = null;
      _failed = false;
      _tc.value = Matrix4.identity();
      _load();
    }
    // If zoom mode was turned off, snap back to 1x.
    if (oldWidget.interactive && !widget.interactive) {
      _tc.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cached = widget.cache.get(widget.pageNumber);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _image = cached;
        _failed = false;
      });
      return;
    }

    try {
      final page = widget.document.pages[widget.pageNumber - 1];
      final pdfImage = await page.render(
        fullWidth: page.width * _kPageRenderScale,
        fullHeight: page.height * _kPageRenderScale,
      );
      if (pdfImage == null) {
        if (!mounted) return;
        setState(() => _failed = true);
        return;
      }
      final image = await pdfImage.createImage();
      widget.cache.put(widget.pageNumber, image);
      if (!mounted) return;
      setState(() {
        _image = image;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null && _failed) {
      return const ColoredBox(
        color: Color(0xFFFFFCF5),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF49675C)),
        ),
      );
    }

    if (_image == null) {
      return const ColoredBox(
        color: Color(0xFFFFFCF5),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFD4A548),
            ),
          ),
        ),
      );
    }

    final image = RawImage(
      image: _image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (!widget.interactive) {
      // Plain image — curl gets all gestures.
      return image;
    }

    return InteractiveViewer(
      transformationController: _tc,
      minScale: 1.0,
      maxScale: 5.0,
      panEnabled: true,
      scaleEnabled: true,
      clipBehavior: Clip.hardEdge,
      child: image,
    );
  }
}

/// Non-interactive page used for the backdrop behind the curl.
class _CachedPdfPageImage extends StatefulWidget {
  const _CachedPdfPageImage({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.cache,
  });

  final PdfDocument document;
  final int pageNumber;
  final _PageImageCache cache;

  @override
  State<_CachedPdfPageImage> createState() => _CachedPdfPageImageState();
}

class _CachedPdfPageImageState extends State<_CachedPdfPageImage> {
  ui.Image? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CachedPdfPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.document != widget.document) {
      _image = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cached = widget.cache.get(widget.pageNumber);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _image = cached;
        _failed = false;
      });
      return;
    }

    try {
      final page = widget.document.pages[widget.pageNumber - 1];
      final pdfImage = await page.render(
        fullWidth: page.width * _kPageRenderScale,
        fullHeight: page.height * _kPageRenderScale,
      );
      if (pdfImage == null) {
        if (!mounted) return;
        setState(() => _failed = true);
        return;
      }
      final image = await pdfImage.createImage();
      widget.cache.put(widget.pageNumber, image);
      if (!mounted) return;
      setState(() {
        _image = image;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return RawImage(
        image: _image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }

    if (_failed) {
      return const ColoredBox(
        color: Color(0xFFFFFCF5),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF49675C)),
        ),
      );
    }

    return const ColoredBox(
      color: Color(0xFFFFFCF5),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD4A548),
          ),
        ),
      ),
    );
  }
}

/// LRU cache for [ui.Image]s keyed by PDF page number.
class _PageImageCache {
  _PageImageCache({required this.maxEntries});

  final int maxEntries;

  final LinkedHashMap<int, ui.Image> _entries = LinkedHashMap<int, ui.Image>();

  bool contains(int key) => _entries.containsKey(key);

  ui.Image? get(int key) {
    final image = _entries.remove(key);
    if (image != null) {
      // Re-insert to mark as most recently used.
      _entries[key] = image;
    }
    return image;
  }

  void put(int key, ui.Image image) {
    final existing = _entries.remove(key);
    if (existing != null && !identical(existing, image)) {
      existing.dispose();
    }
    _entries[key] = image;

    while (_entries.length > maxEntries) {
      final oldestKey = _entries.keys.first;
      final evicted = _entries.remove(oldestKey);
      evicted?.dispose();
    }
  }

  void dispose() {
    for (final image in _entries.values) {
      image.dispose();
    }
    _entries.clear();
  }
}
