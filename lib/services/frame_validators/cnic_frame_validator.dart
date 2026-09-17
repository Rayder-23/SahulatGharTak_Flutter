import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of checking a single live-camera frame against the CNIC criteria.
class FrameValidationResult {
  const FrameValidationResult({required this.isValid, this.matchedPattern = false, this.matchedKeyword = false, this.matchedBarcode = false});

  final bool isValid;
  final bool matchedPattern;
  final bool matchedKeyword;
  final bool matchedBarcode;

  static const invalid = FrameValidationResult(isValid: false);
}

/// Checks a live frame for signs it contains a genuine Pakistani CNIC.
///
/// Front: valid if OCR finds the 13-digit CNIC number pattern and/or one of
/// the standard NIC boilerplate keywords.
///
/// Back: CNIC back layouts differ across eras (pre-2012 laminated card, the
/// long-standing chip-based Smart CNIC, and the QR-based chipless card NADRA
/// began rolling out in August 2026) and exact element positions aren't
/// reliably documented, so this deliberately does not assume a corner/layout.
/// It's valid if a barcode/QR symbol is found anywhere in frame, OR the same
/// 13-digit number is OCR-readable anywhere in frame.
///
/// Only the Latin-script recognizer is used - the 13-digit number and the
/// NIC boilerplate keywords we check for are all Latin/English text.
/// ML Kit's on-device text recognizer has no Urdu/Arabic-script option at
/// all (only Latin, Chinese, Devanagari, Japanese, Korean), so the CNIC's
/// Urdu text is never read, but nothing here needs it to be.
class CnicFrameValidator {
  CnicFrameValidator()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin),
        _barcodeScanner = BarcodeScanner();

  final TextRecognizer _textRecognizer;
  final BarcodeScanner _barcodeScanner;

  static final RegExp _cnicPattern = RegExp(r'\d{5}-?\d{7}-?\d{1}');
  static const _keywords = [
    'national identity card',
    'government of pakistan',
    'islamic republic of pakistan',
    'pakistan',
  ];

  Future<FrameValidationResult> validate(InputImage image, {required bool isBack}) async {
    if (isBack) return _validateBack(image);
    return _validateFront(image);
  }

  Future<FrameValidationResult> _validateFront(InputImage image) async {
    final recognized = await _textRecognizer.processImage(image);
    final text = recognized.text.toLowerCase();
    final matchedPattern = _cnicPattern.hasMatch(recognized.text);
    final matchedKeyword = _keywords.any(text.contains);
    return FrameValidationResult(
      isValid: matchedPattern || matchedKeyword,
      matchedPattern: matchedPattern,
      matchedKeyword: matchedKeyword,
    );
  }

  Future<FrameValidationResult> _validateBack(InputImage image) async {
    final barcodes = await _barcodeScanner.processImage(image);
    final matchedBarcode = barcodes.isNotEmpty;
    if (matchedBarcode) {
      return const FrameValidationResult(isValid: true, matchedBarcode: true);
    }

    final recognized = await _textRecognizer.processImage(image);
    final matchedPattern = _cnicPattern.hasMatch(recognized.text);
    return FrameValidationResult(isValid: matchedPattern, matchedPattern: matchedPattern);
  }

  Future<void> close() async {
    await _textRecognizer.close();
    await _barcodeScanner.close();
  }
}
