import 'dart:io';

/// Represents a single image in the batch gallery scan.
/// Tracks the file, its order, edit state, and extracted text.
class ScanItem {
  final String id; // Unique ID (used for reorder drag key)
  File imageFile; // The current image file (may be replaced after crop/draw)
  String? extractedText; // Null = not yet processed
  bool isProcessing;
  bool hasError;
  String? errorMessage;
  int order; // User-set display order (1-based)

  ScanItem({
    required this.id,
    required this.imageFile,
    required this.order,
    this.extractedText,
    this.isProcessing = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// Whether OCR has been run on this item
  bool get isProcessed => extractedText != null;

  /// Word count for the stats display
  int get wordCount {
    if (extractedText == null || extractedText!.trim().isEmpty) return 0;
    return extractedText!
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }

  /// Deep copy — used when replacing imageFile after editing
  ScanItem copyWith({
    File? imageFile,
    String? extractedText,
    bool? isProcessing,
    bool? hasError,
    String? errorMessage,
    int? order,
  }) {
    return ScanItem(
      id: id,
      imageFile: imageFile ?? this.imageFile,
      order: order ?? this.order,
      extractedText: extractedText ?? this.extractedText,
      isProcessing: isProcessing ?? this.isProcessing,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
