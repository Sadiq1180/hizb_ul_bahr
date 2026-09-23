import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:pdfrx/pdfrx.dart';

/// Renders a single PDF page as a static [ui.Image]. Only loads when the
/// page is within [kLoadWindow] of the current page, and shares in-flight
/// renders with the prefetcher through [PageImageCache.load]/[loadThumb].
class ZoomablePdfPage extends StatefulWidget {
  const ZoomablePdfPage({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.cache,
    required this.zoomMode,
    required this.currentPdfPage,
  });

  final PdfDocument document;
  final int pageNumber;
  final PageImageCache cache;
  final ValueNotifier<bool> zoomMode;
  final ValueNotifier<int> currentPdfPage;

  @override
  State<ZoomablePdfPage> createState() => _ZoomablePdfPageState();
}

class _ZoomablePdfPageState extends State<ZoomablePdfPage> {
  ui.Image? _image;
  ui.Image? _thumbImage;
  bool _failed = false;
  bool _loading = false;
  bool _loadingThumb = false;

  final TransformationController _tc = TransformationController();

  bool get _inWindow =>
      (widget.pageNumber - widget.currentPdfPage.value).abs() <= kLoadWindow;

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
  void didUpdateWidget(covariant ZoomablePdfPage oldWidget) {
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

  void _maybeLoad() {
    if (!mounted || _image != null || !_inWindow) return;

    final cachedFull = widget.cache.get(widget.pageNumber);
    if (cachedFull != null) {
      setState(() {
        _image = cachedFull;
        _failed = false;
      });
      return;
    }

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
    if (page != widget.pageNumber) return;
    _loadingThumb = false;
    if (!mounted || _image != null) return;
    setState(() => _thumbImage = image);
  }

  Future<void> _load() async {
    final page = widget.pageNumber;
    _loading = true;
    final image = await widget.cache.load(widget.document, page);
    if (page != widget.pageNumber) return;
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
        color: ReaderColors.paper,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: ReaderColors.ink),
        ),
      );
    }

    if (displayImage == null) {
      return const ColoredBox(
        color: ReaderColors.paper,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ReaderColors.accent,
            ),
          ),
        ),
      );
    }

    final isFullRes = identical(displayImage, _image);

    // BoxFit.contain shows the whole page — nothing is cropped at the
    // edges. Transform.scale enlarges it slightly so it doesn't look small
    // inside the letterbox; tune the value below if you want it larger or
    // smaller. This MUST match CachedPdfPageImage exactly.
    final image = ColoredBox(
      color: ReaderColors.paper,
      child: Transform.scale(
        scale: 1.08,
        child: RawImage(
          image: displayImage,
          fit: BoxFit.contain,
          filterQuality: isFullRes ? FilterQuality.medium : FilterQuality.low,
        ),
      ),
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
