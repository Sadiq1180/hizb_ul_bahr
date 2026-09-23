import 'dart:collection';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// LRU cache for [ui.Image]s keyed by PDF page number, which also owns
/// rendering. Everything that needs a page image goes through [load] /
/// [loadThumb], so a page is never rendered twice at the same time.
///
/// Keeps two tiers:
///  - a full-resolution cache (`renderWidthPx` wide, what's actually shown)
///  - a low-resolution thumbnail cache (`_thumbWidthPx` wide, cheap and
///    nearly instant to render, used as an immediate placeholder while the
///    full render is still in flight)
class PageImageCache {
  PageImageCache({required this.maxEntries, this.maxThumbEntries = 40});

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
