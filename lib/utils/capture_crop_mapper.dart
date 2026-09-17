import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Maps the on-screen outline rect (in the same logical-pixel coordinate
/// space the live-camera preview is laid out in) onto the pixel grid of a
/// just-captured photo, then crops to it.
///
/// The preview widget fills its box the way `BoxFit.cover` does: the image is
/// scaled up uniformly until it covers the box, and any excess is centered
/// and clipped equally on both sides. This mirrors that math in reverse to
/// recover, in native image pixels, exactly what the user saw inside the
/// outline.
class CaptureCropMapper {
  /// Returns a new cropped temp file, or `null` if cropping wasn't possible
  /// (corrupt/undecodable image, or a degenerate crop rect) - callers must
  /// fall back to the uncropped original rather than treat this as fatal.
  static Future<File?> cropToOutline({
    required File imageFile,
    required Rect outlineRect,
    required Size previewWidgetSize,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      // Camera JPEGs commonly carry an EXIF orientation tag rather than
      // storing pixels upright - normalize so pixel coordinates match what
      // was actually shown in the (always-upright) preview.
      decoded = img.bakeOrientation(decoded);

      final imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
      if (imageSize.width <= 0 || imageSize.height <= 0) return null;

      final scale = math.max(
        previewWidgetSize.width / imageSize.width,
        previewWidgetSize.height / imageSize.height,
      );
      final scaledImageSize = Size(imageSize.width * scale, imageSize.height * scale);
      final dx = (scaledImageSize.width - previewWidgetSize.width) / 2;
      final dy = (scaledImageSize.height - previewWidgetSize.height) / 2;

      final rectInScaledImage = outlineRect.translate(dx, dy);
      final cropRect = Rect.fromLTWH(
        rectInScaledImage.left / scale,
        rectInScaledImage.top / scale,
        rectInScaledImage.width / scale,
        rectInScaledImage.height / scale,
      ).intersect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));

      if (cropRect.width < 10 || cropRect.height < 10) return null;

      final cropped = img.copyCrop(
        decoded,
        x: cropRect.left.round(),
        y: cropRect.top.round(),
        width: cropRect.width.round(),
        height: cropRect.height.round(),
      );

      final dir = await getTemporaryDirectory();
      final outFile = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}_cropped.jpg');
      await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
      return outFile;
    } catch (_) {
      return null;
    }
  }
}
