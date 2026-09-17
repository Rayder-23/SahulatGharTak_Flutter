import 'package:flutter/material.dart';

enum OutlineShape { faceOval, cnicCard }

/// Computes the outline's rect for a given preview [Size] - shared by
/// [CaptureOutlinePainter] (what the user sees) and `capture_crop_mapper.dart`
/// (what actually gets cropped), so the visual guide and the real crop never
/// disagree.
class CaptureOutlineGeometry {
  /// ISO/IEC 7810 ID-1 card size (85.6mm x 54mm) - the standard physical CNIC
  /// dimensions, used across the chip-based Smart CNIC and the QR-based card.
  static const double cnicAspectRatio = 85.6 / 54.0;

  static Rect rectFor(Size previewSize, OutlineShape shape) {
    final center = previewSize.center(Offset.zero);
    switch (shape) {
      case OutlineShape.faceOval:
        // Wider/less-elongated than a tight headshot oval so the user doesn't
        // have to hold the phone unusually far away just to fit their face in it.
        final width = previewSize.width * 0.85;
        final height = width / 0.85;
        return Rect.fromCenter(center: center, width: width, height: height);
      case OutlineShape.cnicCard:
        final width = previewSize.width * 0.85;
        final height = width / cnicAspectRatio;
        return Rect.fromCenter(center: center, width: width, height: height);
    }
  }
}

/// Draws the live-camera framing guide: a dimmed scrim outside the outline,
/// with the outline itself white while the frame isn't yet valid and green
/// the instant it is - the user-visible signal that the object is correctly
/// placed.
class CaptureOutlinePainter extends CustomPainter {
  const CaptureOutlinePainter({required this.shape, required this.isValid});

  final OutlineShape shape;
  final bool isValid;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = CaptureOutlineGeometry.rectFor(size, shape);
    final shapePath = shape == OutlineShape.faceOval
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))));

    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      shapePath,
    );
    canvas.drawPath(scrimPath, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final strokeColor = isValid ? const Color(0xFF2ECC71) : Colors.white;
    canvas.drawPath(
      shapePath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CaptureOutlinePainter oldDelegate) => oldDelegate.isValid != isValid || oldDelegate.shape != shape;
}
