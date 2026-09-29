import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class ImageDownsampler {
  /// Downsamples an image file to max 768px on the longest side, encodes to JPEG ~70%,
  /// and returns the base64 string suitable for the Vision AI backend.
  static Future<String> processImageForVisionAi(String filePath) async {
    final file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image for vision processing');
    }

    img.Image resized = decoded;
    final int width = decoded.width;
    final int height = decoded.height;
    final int maxDim = AppConstants.maxImageLongSide;

    if (width > maxDim || height > maxDim) {
      if (width >= height) {
        final targetHeight = (height * (maxDim / width)).round();
        resized = img.copyResize(decoded, width: maxDim, height: targetHeight, interpolation: img.Interpolation.linear);
      } else {
        final targetWidth = (width * (maxDim / height)).round();
        resized = img.copyResize(decoded, width: targetWidth, height: maxDim, interpolation: img.Interpolation.linear);
      }
    }

    final Uint8List jpegBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: AppConstants.imageJpegQuality),
    );

    return base64Encode(jpegBytes);
  }
}
