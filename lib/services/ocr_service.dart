import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Handles all OCR operations using Google ML Kit.
/// Supports single image and batch processing.
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extracts text from a single image path.
  Future<String> extractText(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognized =
        await _textRecognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Batch process a list of image paths.
  /// Returns a map of imagePath → extractedText.
  /// Processes sequentially to avoid overloading ML Kit.
  ///
  /// [onProgress] is called after each image is processed,
  /// with the current index (0-based) so you can show a progress indicator.
  Future<Map<String, String>> extractTextBatch(
    List<String> imagePaths, {
    void Function(int processedIndex)? onProgress,
  }) async {
    final Map<String, String> results = {};

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        final text = await extractText(imagePaths[i]);
        results[imagePaths[i]] = text;
      } catch (e) {
        // Store empty string on error — caller can check for empty
        results[imagePaths[i]] = '';
      }
      // Report progress after each image
      onProgress?.call(i);
    }

    return results;
  }

  /// Combines results from multiple images into a single string,
  /// separated by a divider showing the image number.
  static String combineResults(
    List<String> orderedPaths,
    Map<String, String> results,
  ) {
    final buffer = StringBuffer();
    for (int i = 0; i < orderedPaths.length; i++) {
      final text = results[orderedPaths[i]] ?? '';
      if (text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln('── Screenshot ${i + 1} ──');
        buffer.writeln(text.trim());
      }
    }
    return buffer.toString().trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
