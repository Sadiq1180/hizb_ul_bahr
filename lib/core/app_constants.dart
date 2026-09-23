import 'dart:ui';

class AppConstants {
  AppConstants._();

  static const appName = 'حزب البحر';
  static const arabicNameFont = 'Amiri';

  // Change this if your PDF file path is different.
  static const bookAsset = 'assets/book.pdf';
}

/// Pages within this distance of the current page are allowed to load.
/// Pages further away stay as cheap placeholders (no render work queued).
const int kLoadWindow = 5;

/// Order in which neighbours are prefetched, as offsets from the current
/// PDF page. Both direct neighbours come first because the user can turn
/// either way; then we go outward. Kept symmetric with [kLoadWindow] so
/// backward flipping is prefetched just as eagerly as forward flipping.
const List<int> kPrefetchOffsets = [1, -1, 2, -2, 3, -3, 4, -4, 5, -5];

/// App-wide colour palette for the reader.
class ReaderColors {
  static const background = Color(0xFF193B33);
  static const appBar = Color(0xFF075A45);
  static const paper = Color(0xFFFFFCF5);
  static const accent = Color(0xFFD4A548);
  static const ink = Color(0xFF49675C);
}
