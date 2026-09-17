import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Leniently checks a live camera frame for the presence of any face - the
/// profile photo slot only needs *a* face in view, not a centered/well-lit one.
class FaceFrameValidator {
  FaceFrameValidator()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableContours: false,
            enableLandmarks: false,
            enableClassification: false,
            enableTracking: false,
          ),
        );

  final FaceDetector _detector;

  Future<bool> hasFace(InputImage image) async {
    final faces = await _detector.processImage(image);
    return faces.isNotEmpty;
  }

  Future<void> close() => _detector.close();
}
