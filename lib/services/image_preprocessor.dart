import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePreprocessor {
  /// Takes the original image file, applies enhancements,
  /// saves to a temp file, and returns the new path for ML Kit.
  static Future<String> preprocess(String imagePath) async {
    // 1. Load the image into memory
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return imagePath; // Fallback to original

    // 2. Convert to grayscale — reduces color noise, helps ML Kit
    //    focus purely on contrast differences between text and background
    image = img.grayscale(image);

    // 3. Boost contrast — makes dark text darker, light background lighter
    //    The value 1.5 means 50% more contrast. Range: 1.0 (none) to 2.0+ (extreme)
    image = img.adjustColor(image, contrast: 1.5);

    // 4. Sharpen — enhances edges of characters, helps with blurry photos
    image = img.sharpen(image, amount: 0.5);

    // 5. Save preprocessed image to a temp file
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(img.encodePng(image));

    return outPath; // ← This path goes into OcrService.extractText()
  }
}
