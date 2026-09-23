import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';
import 'package:hizb_ul_bahr/core/app_constants.dart';
import 'package:hizb_ul_bahr/features/services/flip_sound.dart';
import 'package:hizb_ul_bahr/features/services/page_image_chache.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns all reader state and side effects: persistence, sound, page cache,
/// prefetching, and the current curl/Pdf page mapping.
///
/// The UI layer only reads from this and calls the intent methods
/// (`toggleSound`, `onCurlPageChanged`, `onDocumentReady`, …).
class PdfReaderController extends ChangeNotifier {
  PdfReaderController({required this.assetPath, required this.bookController});

  final String assetPath;
  final PageCurlController bookController;

  // ── Persistence keys ──────────────────────────────────────────
  String get _prefsKey => 'pdf_last_page::$assetPath';
  String get _soundPrefsKey => 'pdf_sound_enabled::$assetPath';

  // ── Image cache ───────────────────────────────────────────────
  final PageImageCache imageCache = PageImageCache(
    maxEntries: 20,
    maxThumbEntries: 60,
  );

  final FlipSoundPlayer _flipSound = FlipSoundPlayer();

  // ── Public state (UI reads these) ─────────────────────────────
  SharedPreferences? _prefs;

  /// True after preferences have loaded and the reader can show pages.
  bool prefsReady = false;

  /// Stored start page from last session (nullable).
  int? savedPdfPage;

  /// Current document + page count (set via [attachDocument]).
  PdfDocument? document;
  int totalPages = 0;
  List<Widget>? pages;

  /// Current user-visible state.
  bool soundEnabled = true;
  bool zoomMode = false;
  int currentCurlPage = 0;
  int currentPdfPage = 1;

  /// Notifiers used by the page tiles.
  final ValueNotifier<bool> zoomModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentPdfPageNotifier = ValueNotifier<int>(1);

  /// Prevents the initial "jump to saved page" from playing a flip sound.
  bool _suppressNextFlipSound = false;

  /// Set once the initial jump has been performed.
  bool openedAtStartPage = false;

  double renderWidthPx = 800;

  // ── Lifecycle ─────────────────────────────────────────────────

  Future<void> init() async {
    unawaited(_flipSound.init());
    await _restoreProgress();
  }

  @override
  void dispose() {
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
    currentPdfPageNotifier.value = savedPdfPage ?? 1;
    prefsReady = true;
    notifyListeners();
  }

  void _saveProgress(int pdfPage) {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setInt(_prefsKey, pdfPage));
  }

  // ── Document / page initialisation ────────────────────────────

  /// Called by the UI when a document is available. Returns true if the
  /// caller should schedule the initial jump to the saved page.
  bool attachDocument(PdfDocument doc, List<Widget> builtPages) {
    final changed =
        document != doc || totalPages != doc.pages.length || pages == null;

    document = doc;
    totalPages = doc.pages.length;
    pages = builtPages;
    return changed;
  }

  /// Perform the initial jump to the saved page. Called by the UI inside a
  /// post-frame callback.
  void jumpToStartPage() {
    if (openedAtStartPage || totalPages == 0) return;

    final startPdfPage = (savedPdfPage ?? 1).clamp(1, totalPages);
    final startCurlPage = totalPages - startPdfPage;

    _prefetchAround(startCurlPage);

    openedAtStartPage = true;
    currentCurlPage = startCurlPage;
    currentPdfPageNotifier.value = startPdfPage;

    _suppressNextFlipSound = true;
    bookController.jumpToPage(startCurlPage);

    notifyListeners();
  }

  // ── User intents ──────────────────────────────────────────────

  void toggleSound() {
    soundEnabled = !soundEnabled;
    _flipSound.enabled = soundEnabled;
    if (!soundEnabled) {
      unawaited(_flipSound.stopAll());
    }
    unawaited(_prefs?.setBool(_soundPrefsKey, soundEnabled));
    notifyListeners();
  }

  void toggleZoom() {
    zoomMode = !zoomMode;
    zoomModeNotifier.value = zoomMode;
    notifyListeners();
  }

  /// Called from `PageCurlView.onPageChanged`.
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

    notifyListeners();
  }

  /// Page number to render behind the curl animation.
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
