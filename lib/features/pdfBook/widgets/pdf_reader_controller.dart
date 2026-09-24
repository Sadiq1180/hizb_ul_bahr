import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/flip_sound.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns all reader state and side effects: persistence, sound, page cache,
/// prefetching, and the current curl/Pdf page mapping.
class PdfReaderController extends ChangeNotifier {
  PdfReaderController({required this.assetPath});

  final String assetPath;

  bool _disposed = false;

  /// Attached lazily by the UI once preferences are loaded.
  PageCurlController? bookController;

  void attachBookController(PageCurlController controller) {
    bookController = controller;
  }

  // ── Persistence keys ──────────────────────────────────────────
  String get _prefsKey => 'pdf_last_page::$assetPath';
  String get _soundPrefsKey => 'pdf_sound_enabled::$assetPath';

  // ── Image cache ───────────────────────────────────────────────
  final PageImageCache imageCache = PageImageCache(
    maxEntries: 20,
    maxThumbEntries: 60,
  );

  final FlipSoundPlayer _flipSound = FlipSoundPlayer();

  // ── Public state ──────────────────────────────────────────────
  SharedPreferences? _prefs;

  bool prefsReady = false;

  /// True once the images around the start page are in the cache, so the
  /// curl view can be shown without drawing loading placeholders.
  bool pagesReady = false;
  bool _preloading = false;

  int? savedPdfPage;

  PdfDocument? document;
  int totalPages = 0;
  List<Widget>? pages;

  bool soundEnabled = true;
  bool zoomMode = false;
  int currentCurlPage = 0;
  int currentPdfPage = 1;

  final ValueNotifier<bool> zoomModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentPdfPageNotifier = ValueNotifier<int>(1);

  bool _suppressNextFlipSound = false;
  bool openedAtStartPage = false;

  double renderWidthPx = 800;

  // ── Safe notification ─────────────────────────────────────────

  void _notify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────

  Future<void> init() async {
    unawaited(_flipSound.init());
    await _restoreProgress();
  }

  @override
  void dispose() {
    _disposed = true;
    if (openedAtStartPage && totalPages > 0) {
      _saveProgress(currentPdfPage);
    }
    zoomModeNotifier.dispose();
    currentPdfPageNotifier.dispose();
    imageCache.dispose();
    _flipSound.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      savedPdfPage = prefs.getInt(_prefsKey);
      soundEnabled = prefs.getBool(_soundPrefsKey) ?? true;
      _flipSound.enabled = soundEnabled;
    } catch (_) {}

    if (_disposed) return;

    currentPdfPageNotifier.value = savedPdfPage ?? 1;
    prefsReady = true;
    _notify();
  }

  void _saveProgress(int pdfPage) {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setInt(_prefsKey, pdfPage));
  }

  // ── Document / page initialisation ────────────────────────────

  bool attachDocument(PdfDocument doc, List<Widget> builtPages) {
    final changed =
        document != doc || totalPages != doc.pages.length || pages == null;

    if (changed) {
      pagesReady = false;
      _preloading = false;
      openedAtStartPage = false;
    }

    document = doc;
    totalPages = doc.pages.length;
    pages = builtPages;
    return changed;
  }

  /// Loads the start page and the next page (the one revealed when turning
  /// forward) and flips [pagesReady] as soon as those two are cached.
  /// Other neighbours load in the background without blocking the UI.
  Future<void> preloadInitialPages(PdfDocument doc) async {
    if (_preloading || pagesReady || _disposed) return;
    _preloading = true;

    final total = doc.pages.length;
    final start = (savedPdfPage ?? 1).clamp(1, total);

    Future<void> safeLoad(int page) async {
      if (page < 1 || page > total) return;
      try {
        await imageCache.load(doc, page).timeout(const Duration(seconds: 3));
      } catch (_) {
        // A slow/failed page must not block the reader.
      }
    }

    // Background: everything else nearby, not awaited.
    for (final p in [start + 1, start + 2, start - 2]) {
      unawaited(safeLoad(p));
    }

    // Wait only for what is visible now: current page + next page, in
    // parallel (not one after the other).
    await Future.wait([safeLoad(start), safeLoad(start - 1)]);

    if (_disposed) return;
    pagesReady = true;
    _preloading = false;
    _notify();
  }

  /// Curl-page index that corresponds to the saved (or first) PDF page.
  int computeStartCurlPage() {
    if (totalPages == 0) return 0;
    final startPdfPage = (savedPdfPage ?? 1).clamp(1, totalPages);
    return totalPages - startPdfPage;
  }

  /// Syncs internal state to match the page the curl view opened on.
  void markOpenedAtStartPage({bool deferNotify = false}) {
    if (openedAtStartPage || totalPages == 0) return;

    final startPdfPage = (savedPdfPage ?? 1).clamp(1, totalPages);
    final startCurlPage = totalPages - startPdfPage;

    openedAtStartPage = true;
    currentCurlPage = startCurlPage;
    currentPdfPage = startPdfPage;
    currentPdfPageNotifier.value = startPdfPage;

    _prefetchAround(startCurlPage);
    _suppressNextFlipSound = true;

    if (!deferNotify) {
      _notify();
    }
  }

  /// Safe to call from a post-frame callback or async context.
  void notifySafely() {
    _notify();
  }

  // ── User intents ──────────────────────────────────────────────

  void toggleSound() {
    soundEnabled = !soundEnabled;
    _flipSound.enabled = soundEnabled;
    if (!soundEnabled) {
      unawaited(_flipSound.stopAll());
    }
    unawaited(_prefs?.setBool(_soundPrefsKey, soundEnabled));
    _notify();
  }

  void toggleZoom() {
    zoomMode = !zoomMode;
    zoomModeNotifier.value = zoomMode;
    _notify();
  }

  void onCurlPageChanged(int page) {
    final skipSound = _suppressNextFlipSound;
    _suppressNextFlipSound = false;

    _prefetchAround(page);

    currentCurlPage = page;
    currentPdfPage = totalPages - page;
    currentPdfPageNotifier.value = currentPdfPage;

    if (openedAtStartPage) {
      _saveProgress(currentPdfPage);
    }

    if (!skipSound) {
      unawaited(_flipSound.play());
    }

    _notify();
  }

  int? get backdropPdfPage {
    final nextCurlIndex = currentCurlPage + 1;
    if (nextCurlIndex >= totalPages) return null;
    return totalPages - nextCurlIndex;
  }

  void setRenderWidth(double width) {
    renderWidthPx = width;
    imageCache.renderWidthPx = width;
  }

  // ── Prefetching ───────────────────────────────────────────────

  void _prefetchAround(int curlPage) {
    final doc = document;
    if (doc == null) return;

    final pdfPage = totalPages - curlPage;

    void queue(int page) {
      if (page < 1 || page > totalPages) return;
      unawaited(imageCache.loadThumb(doc, page));
      unawaited(imageCache.load(doc, page));
    }

    queue(pdfPage);
    for (var d = 1; d <= kLoadWindow + 2; d++) {
      queue(pdfPage + d);
      queue(pdfPage - d);
    }
  }
}
