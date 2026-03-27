import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Handles all OCR operations using Google ML Kit.
/// This service processes an image file path and returns the recognized text.
class OcrService {
  // TextRecognizer is the main ML Kit engine.
  // We use the Latin script recognizer which supports English + most
  // Western European languages out of the box, offline, for free.
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Takes an image file path and returns the recognized text as a String.
  /// Returns an empty string if no text is found.
  /// Throws an exception if processing fails.
  Future<String> extractText(String imagePath) async {
    // 1. Wrap the image file in an InputImage (ML Kit's format)
    final InputImage inputImage = InputImage.fromFilePath(imagePath);

    // 2. Run the recognizer — this is the actual OCR call
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    // 3. recognizedText.text contains the full extracted text as a plain string.
    //    You can also access recognizedText.blocks for per-paragraph data,
    //    or .lines and .elements for more granular control.
    return recognizedText.text;
  }

  /// Returns structured text blocks — useful if you want to display
  /// text with its original positioning or bounding boxes later.
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );
    return recognizedText.blocks;
  }

  /// IMPORTANT: Always call dispose() when you're done with the service
  /// (e.g., in the State's dispose() method) to free ML Kit resources.
  void dispose() {
    _textRecognizer.close();
  }
}
