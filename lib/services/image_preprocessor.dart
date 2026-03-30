import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePreprocessor {
  /// Takes the original image file, applies enhancements,
  /// saves to a temp file, and returns the new path for ML Kit.
  static Future<String> preprocess(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return imagePath;

    // 1. Grayscale
    image = img.grayscale(image);

    // 2. Contrast
    image = img.adjustColor(image, contrast: 1.5);

    // 3. Sharpen (The corrected line for version 4+)
    // This uses a predefined sharpen kernel to make text edges crisp
    image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(img.encodePng(image));

    return outPath;
  }
}
