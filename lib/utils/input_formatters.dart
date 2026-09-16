import 'package:flutter/services.dart';

/// Live-formats a CNIC as the user types: 12345-1234567-1.
/// Strips any non-digit input and caps at 13 digits (15 chars incl. dashes).
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 13 ? digits.substring(0, 13) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(truncated[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Live-formats a mobile number as the user types: 03XX-XXXXXXX.
/// Strips any non-digit input and caps at 11 digits (14 chars incl. dash).
class MobileNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i == 4) buffer.write('-');
      buffer.write(truncated[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Strips dashes/whitespace from a formatted mobile number back to the raw
/// digit string the backend expects (e.g. "0300-1234567" -> "03001234567").
String digitsOnlyMobile(String v) => v.replaceAll(RegExp(r'\D'), '');

/// Inserts a dash into a raw mobile-number digit string for display (e.g.
/// when prefilling a field from a stored value that has no dash).
String formatMobileForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length && i < 11; i++) {
    if (i == 4) buffer.write('-');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Inserts dashes into a raw CNIC digit string for display (e.g. when
/// prefilling a field from a stored value that has no dashes).
String formatCnicForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length && i < 13; i++) {
    if (i == 5 || i == 12) buffer.write('-');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Validates a fully-typed CNIC (with dashes) is exactly 13 digits.
String? cnicValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 13) return 'Enter a valid 13-digit CNIC';
  return null;
}

/// Validates a fully-typed Pakistani mobile number is exactly 11 digits.
String? mobileNumberValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  if (digitsOnlyMobile(v).length != 11) return 'Enter a valid 11-digit mobile number';
  return null;
}
