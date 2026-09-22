import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _readerArabicFont = 'Amiri';

/// Pages within this distance of the current page are allowed to load.
/// Pages further away stay as cheap placeholders (no render work queued).
const int _kLoadWindow = 5;

/// Order in which neighbours are prefetched, as offsets from the current
/// PDF page. Both direct neighbours come first because the user can turn
/// either way; then we go outward. Kept symmetric with [_kLoadWindow] so
/// backward flipping is prefetched just as eagerly as forward flipping.
const List<int> _kPrefetchOffsets = [1, -1, 2, -2, 3, -3, 4, -4, 5, -5];

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

  // Saved reading position.
  SharedPreferences? _prefs;
  bool _prefsReady = false;
  int? _savedPdfPage;

  String get _prefsKey => 'pdf_last_page::${widget.assetPath}';

  final ValueNotifier<bool> _zoomModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentPdfPageNotifier = ValueNotifier<int>(1);

  bool _zoomMode = false;

  PdfDocument? _cachedDocument;
  List<Widget>? _cachedPages;
  int _cachedTotalPages = 0;

  final _PageImageCache _imageCache = _PageImageCache(
    maxEntries: 20,
    maxThumbEntries: 60,
  );

  int get _currentPdfPage => _cachedTotalPages - _currentCurlPage;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Render pages at (roughly) the screen's physical width instead of a
    // fixed multiple of the PDF's own size. Big scanned pages are what make
    // rendering slow, and pixels beyond the screen width are wasted.
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
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _savedPdfPage = prefs.getInt(_prefsKey);
    } catch (_) {
      // If storage fails, just start from the first page.
    }
    // Set the notifier BEFORE pages are built, so each page widget knows
    // whether it's inside the load window from its very first frame.
    _currentPdfPageNotifier.value = _savedPdfPage ?? 1;
    if (mounted) setState(() => _prefsReady = true);
  }

  void _saveProgress(int pdfPage) {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setInt(_prefsKey, pdfPage));
  }

  /// Kicks off renders for the current page and its neighbours, both the
  /// cheap low-res thumbnail (near-instant, shown while the full page is
  /// still rendering) and the full-res image. [_PageImageCache.load] /
  /// [_PageImageCache.loadThumb] de-duplicate, so calling this repeatedly
  /// and having page widgets ask for the same page never renders it twice.
  void _prefetchAround(PdfDocument document, int curlPage) {
    final pdfPage = _cachedTotalPages - curlPage;
    void queue(int page) {
      if (page < 1 || page > _cachedTotalPages) return;
      unawaited(_imageCache.loadThumb(document, page));
      unawaited(_imageCache.load(document, page));
    }

    queue(pdfPage);
    for (final d in _kPrefetchOffsets) {
      queue(pdfPage + d);
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
                zoomMode: _zoomModeNotifier,
                currentPdfPage: _currentPdfPageNotifier,
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
    _zoomModeNotifier.value = _zoomMode;
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
          if (document == null || !_prefsReady) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A548)),
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
            final startPdfPage = (_savedPdfPage ?? 1).clamp(1, totalPages);
            final startCurlPage = totalPages - startPdfPage;

            // Start rendering the opening page + neighbours right now,
            // before the post-frame jump. Safe to call repeatedly.
            _prefetchAround(document, startCurlPage);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _openedAtUrduFirstPage) return;

              setState(() {
                _openedAtUrduFirstPage = true;
                _currentCurlPage = startCurlPage;
              });
              _currentPdfPageNotifier.value = startPdfPage;

              _bookController.jumpToPage(startCurlPage);
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
                                  _currentPdfPageNotifier.value =
                                      _cachedTotalPages - page;
                                  _prefetchAround(document, page);
                                  if (_openedAtUrduFirstPage) {
                                    _saveProgress(_cachedTotalPages - page);
                                  }
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
            ],
          );
        },
      ),
    );
  }
}

/// Renders a single PDF page as a static [ui.Image]. Only loads when the
/// page is within [_kLoadWindow] of the current page, and shares in-flight
/// renders with the prefetcher through [_PageImageCache.load]/[loadThumb].
///
/// Uses progressive rendering: a cheap low-res thumbnail is requested first
/// and shown as soon as it's ready (typically a few milliseconds), then
/// swapped for the full-res image once that finishes. This means a page
/// almost never shows a bare spinner — it shows a slightly soft image
/// immediately and sharpens shortly after.
class _ZoomablePdfPage extends StatefulWidget {
  const _ZoomablePdfPage({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.cache,
    required this.zoomMode,
    required this.currentPdfPage,
  });

  final PdfDocument document;
  final int pageNumber;
  final _PageImageCache cache;
  final ValueNotifier<bool> zoomMode;
  final ValueNotifier<int> currentPdfPage;

  @override
  State<_ZoomablePdfPage> createState() => _ZoomablePdfPageState();
}

class _ZoomablePdfPageState extends State<_ZoomablePdfPage> {
  ui.Image? _image;
  ui.Image? _thumbImage;
  bool _failed = false;
  bool _loading = false;
  bool _loadingThumb = false;

  final TransformationController _tc = TransformationController();

  bool get _inWindow =>
      (widget.pageNumber - widget.currentPdfPage.value).abs() <= _kLoadWindow;

  @override
  void initState() {
    super.initState();
    _image = widget.cache.get(widget.pageNumber);
    _thumbImage = widget.cache.getThumb(widget.pageNumber);
    if (_image == null) _maybeLoad();
    widget.zoomMode.addListener(_onZoomChanged);
    widget.currentPdfPage.addListener(_maybeLoad);
  }

  @override
  void didUpdateWidget(covariant _ZoomablePdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.document != widget.document) {
      _image = widget.cache.get(widget.pageNumber);
      _thumbImage = widget.cache.getThumb(widget.pageNumber);
      _failed = false;
      _loading = false;
      _loadingThumb = false;
      _tc.value = Matrix4.identity();
      if (_image == null) _maybeLoad();
    }
    if (oldWidget.zoomMode != widget.zoomMode) {
      oldWidget.zoomMode.removeListener(_onZoomChanged);
      widget.zoomMode.addListener(_onZoomChanged);
    }
    if (oldWidget.currentPdfPage != widget.currentPdfPage) {
      oldWidget.currentPdfPage.removeListener(_maybeLoad);
      widget.currentPdfPage.addListener(_maybeLoad);
    }
  }

  void _onZoomChanged() {
    if (!widget.zoomMode.value && _tc.value != Matrix4.identity()) {
      _tc.value = Matrix4.identity();
    }
  }

  /// Called on init and every time the current page changes.
  void _maybeLoad() {
    if (!mounted || _image != null || !_inWindow) return;

    // Already prefetched at full res? Show it immediately, no async gap.
    final cachedFull = widget.cache.get(widget.pageNumber);
    if (cachedFull != null) {
      setState(() {
        _image = cachedFull;
        _failed = false;
      });
      return;
    }

    // Already have (or can get) a thumbnail? Show that right away while the
    // full-res render happens in the background.
    final cachedThumb = widget.cache.getThumb(widget.pageNumber);
    if (cachedThumb != null) {
      if (!identical(_thumbImage, cachedThumb)) {
        setState(() => _thumbImage = cachedThumb);
      }
    } else if (!_loadingThumb) {
      _loadThumb();
    }

    if (!_loading) _load();
  }

  @override
  void dispose() {
    widget.zoomMode.removeListener(_onZoomChanged);
    widget.currentPdfPage.removeListener(_maybeLoad);
    _tc.dispose();
    super.dispose();
  }

  Future<void> _loadThumb() async {
    final page = widget.pageNumber;
    _loadingThumb = true;
    final image = await widget.cache.loadThumb(widget.document, page);
    if (page != widget.pageNumber) return; // widget was reused for another page
    _loadingThumb = false;
    if (!mounted || _image != null) return; // full image already arrived
    setState(() => _thumbImage = image);
  }

  Future<void> _load() async {
    final page = widget.pageNumber;
    _loading = true;
    final image = await widget.cache.load(widget.document, page);
    if (page != widget.pageNumber) return; // widget was reused for another page
    _loading = false;
    if (!mounted) return;
    setState(() {
      _image = image;
      _failed = image == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cachedFull = widget.cache.get(widget.pageNumber);
    if (cachedFull != null && !identical(_image, cachedFull)) {
      _image = cachedFull;
      _failed = false;
    }
    if (_image == null) {
      final cachedThumb = widget.cache.getThumb(widget.pageNumber);
      if (cachedThumb != null && !identical(_thumbImage, cachedThumb)) {
        _thumbImage = cachedThumb;
      }
    }

    final displayImage = _image ?? _thumbImage;

    if (displayImage == null && _failed) {
      return const ColoredBox(
        color: Color(0xFFFFFCF5),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF49675C)),
        ),
      );
    }

    if (displayImage == null) {
      // Only reached in the brief window before even the thumbnail has
      // rendered (essentially instant in practice).
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

    final isFullRes = identical(displayImage, _image);
    final image = RawImage(
      image: displayImage,
      fit: BoxFit.contain,
      filterQuality: isFullRes ? FilterQuality.medium : FilterQuality.low,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: widget.zoomMode,
      builder: (context, zoomOn, _) {
        return ValueListenableBuilder<int>(
          valueListenable: widget.currentPdfPage,
          builder: (context, currentPage, _) {
            final interactive = zoomOn && widget.pageNumber == currentPage;
            if (!interactive) return image;
            return InteractiveViewer(
              transformationController: _tc,
              minScale: 1.0,
              maxScale: 5.0,
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.hardEdge,
              child: image,
            );
          },
        );
      },
    );
  }
}

/// Non-interactive page used for the backdrop behind the curl. Same
/// thumbnail-first progressive loading as [_ZoomablePdfPage].
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
  ui.Image? _thumbImage;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _image = widget.cache.get(widget.pageNumber);
    _thumbImage = widget.cache.getThumb(widget.pageNumber);
    if (_image == null) {
      _loadThumb();
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant _CachedPdfPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.document != widget.document) {
      _image = widget.cache.get(widget.pageNumber);
      _thumbImage = widget.cache.getThumb(widget.pageNumber);
      _failed = false;
      if (_image == null) {
        _loadThumb();
        _load();
      }
    }
  }

  Future<void> _loadThumb() async {
    final page = widget.pageNumber;
    final image = await widget.cache.loadThumb(widget.document, page);
    if (!mounted || page != widget.pageNumber || _image != null) return;
    setState(() => _thumbImage = image);
  }

  Future<void> _load() async {
    final page = widget.pageNumber;
    final image = await widget.cache.load(widget.document, page);
    if (!mounted || page != widget.pageNumber) return;
    setState(() {
      _image = image;
      _failed = image == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cachedFull = widget.cache.get(widget.pageNumber);
    if (cachedFull != null && !identical(_image, cachedFull)) {
      _image = cachedFull;
      _failed = false;
    }
    if (_image == null) {
      final cachedThumb = widget.cache.getThumb(widget.pageNumber);
      if (cachedThumb != null && !identical(_thumbImage, cachedThumb)) {
        _thumbImage = cachedThumb;
      }
    }

    final displayImage = _image ?? _thumbImage;

    if (displayImage != null) {
      return RawImage(
        image: displayImage,
        fit: BoxFit.contain,
        filterQuality: identical(displayImage, _image)
            ? FilterQuality.medium
            : FilterQuality.low,
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

/// LRU cache for [ui.Image]s keyed by PDF page number, which also owns
/// rendering. Everything that needs a page image goes through [load] /
/// [loadThumb], so a page is never rendered twice at the same time.
///
/// Keeps two tiers:
///  - a full-resolution cache (`renderWidthPx` wide, what's actually shown)
///  - a low-resolution thumbnail cache (`_thumbWidthPx` wide, cheap and
///    nearly instant to render, used as an immediate placeholder while the
///    full render is still in flight)
class _PageImageCache {
  _PageImageCache({required this.maxEntries, this.maxThumbEntries = 40});

  final int maxEntries;
  final int maxThumbEntries;

  /// Target full-res render width in physical pixels. Set from the screen size.
  double renderWidthPx = 500;

  /// Thumbnails are tiny and fast on purpose — this is what makes the first
  /// frame of any page show something other than a spinner.
  static const double _thumbWidthPx = 120;

  final LinkedHashMap<int, ui.Image> _entries = LinkedHashMap<int, ui.Image>();
  final LinkedHashMap<int, ui.Image> _thumbs = LinkedHashMap<int, ui.Image>();
  final Map<int, Future<ui.Image?>> _inFlight = <int, Future<ui.Image?>>{};
  final Map<int, Future<ui.Image?>> _thumbInFlight = <int, Future<ui.Image?>>{};
  bool _disposed = false;

  bool contains(int key) => _entries.containsKey(key);

  ui.Image? get(int key) => _peek(_entries, key);

  ui.Image? getThumb(int key) => _peek(_thumbs, key);

  ui.Image? _peek(LinkedHashMap<int, ui.Image> map, int key) {
    final image = map.remove(key);
    if (image != null) {
      map[key] = image; // mark as most recently used
    }
    return image;
  }

  /// Returns the cached full-res image, joins an in-flight render of the
  /// same page, or starts a new one. Resolves to null on failure.
  Future<ui.Image?> load(PdfDocument document, int pageNumber) {
    final cached = get(pageNumber);
    if (cached != null) return Future.value(cached);

    return _inFlight[pageNumber] ??=
        _render(document, pageNumber, renderWidthPx)
            .then((image) {
              if (image != null && !_disposed) {
                _put(_entries, maxEntries, pageNumber, image);
              }
              return image;
            })
            .whenComplete(() => _inFlight.remove(pageNumber));
  }

  /// Returns the cached thumbnail, the full-res image if that's already
  /// available (no point rendering a smaller version), an in-flight
  /// thumbnail render, or starts a new (cheap) one.
  Future<ui.Image?> loadThumb(PdfDocument document, int pageNumber) {
    final full = get(pageNumber);
    if (full != null) return Future.value(full);

    final cached = getThumb(pageNumber);
    if (cached != null) return Future.value(cached);

    return _thumbInFlight[pageNumber] ??=
        _render(document, pageNumber, _thumbWidthPx)
            .then((image) {
              if (image != null && !_disposed) {
                _put(_thumbs, maxThumbEntries, pageNumber, image);
              }
              return image;
            })
            .whenComplete(() => _thumbInFlight.remove(pageNumber));
  }

  Future<ui.Image?> _render(
    PdfDocument document,
    int pageNumber,
    double width,
  ) async {
    try {
      final page = document.pages[pageNumber - 1];
      final scale = width / page.width;
      final pdfImage = await page.render(
        fullWidth: width,
        fullHeight: page.height * scale,
      );
      if (pdfImage == null) return null;
      try {
        final image = await pdfImage.createImage();
        if (_disposed) {
          image.dispose();
          return null;
        }
        return image;
      } finally {
        // Free the raw pixel buffer; the ui.Image has its own copy.
        pdfImage.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  void _put(
    LinkedHashMap<int, ui.Image> map,
    int limit,
    int key,
    ui.Image image,
  ) {
    final existing = map.remove(key);
    if (existing != null && !identical(existing, image)) {
      existing.dispose();
    }
    map[key] = image;

    while (map.length > limit) {
      final oldestKey = map.keys.first;
      final evicted = map.remove(oldestKey);
      evicted?.dispose();
    }
  }

  void dispose() {
    _disposed = true;
    for (final image in _entries.values) {
      image.dispose();
    }
    for (final image in _thumbs.values) {
      image.dispose();
    }
    _entries.clear();
    _thumbs.clear();
    _inFlight.clear();
    _thumbInFlight.clear();
  }
}
