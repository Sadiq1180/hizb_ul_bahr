import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:pdfrx/pdfrx.dart';

/// Non-interactive page used for the backdrop behind the curl. Same
/// thumbnail-first progressive loading as [ZoomablePdfPage].
class CachedPdfPageImage extends StatefulWidget {
  const CachedPdfPageImage({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.cache,
  });

  final PdfDocument document;
  final int pageNumber;
  final PageImageCache cache;

  @override
  State<CachedPdfPageImage> createState() => _CachedPdfPageImageState();
}

class _CachedPdfPageImageState extends State<CachedPdfPageImage> {
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
  void didUpdateWidget(covariant CachedPdfPageImage oldWidget) {
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
      // Must match ZoomablePdfPage exactly — same ColoredBox + same
      // Transform.scale + same BoxFit — or the backdrop and the flipping
      // page will disagree at the flip midpoint and you'll see a jump.
      return ColoredBox(
        color: ReaderColors.paper,
        child: Transform.scale(
          scale: 1.08,
          child: RawImage(
            image: displayImage,
            fit: BoxFit.contain,
            filterQuality: identical(displayImage, _image)
                ? FilterQuality.medium
                : FilterQuality.low,
          ),
        ),
      );
    }

    if (_failed) {
      return const ColoredBox(
        color: ReaderColors.paper,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: ReaderColors.ink),
        ),
      );
    }

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
}
