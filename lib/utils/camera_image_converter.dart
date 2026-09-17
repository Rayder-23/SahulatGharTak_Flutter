import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Converts a live [CameraImage] frame into an ML Kit [InputImage], isolating
/// the plane/rotation/format bookkeeping so every frame validator
/// (face/CNIC OCR/barcode) shares one correct implementation.
///
/// Only single-plane formats are supported - the capture screen must
/// initialize the [CameraController] with `ImageFormatGroup.nv21` on Android
/// and `ImageFormatGroup.bgra8888` on iOS, which is what the `camera` plugin
/// uses to hand back a single concatenated plane instead of raw YUV_420_888.
class CameraImageConverter {
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static InputImage? toInputImage(
    CameraImage image, {
    required CameraDescription description,
    required DeviceOrientation deviceOrientation,
  }) {
    final rotation = _rotationFor(description, deviceOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static InputImageRotation? _rotationFor(
    CameraDescription description,
    DeviceOrientation deviceOrientation,
  ) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(description.sensorOrientation);
    }
    if (Platform.isAndroid) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (description.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (description.sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (description.sensorOrientation - rotationCompensation + 360) % 360;
      }
      return InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    return null;
  }
}
