import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_toast.dart';

Future<void> callNumber(BuildContext context, String mobileNo) async {
  final uri = Uri(scheme: 'tel', path: mobileNo);
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    showAppToast(context, 'Could not start a call.', type: AppToastType.error);
  }
}

/// Digits-only international form for [wa.me](https://wa.me/923001234567),
/// e.g. `0313-5355770` / `+923135355770` → `923135355770`.
String whatsAppNumber(String mobileNo) {
  final digits = mobileNo.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('92')) return digits;
  if (digits.startsWith('0') && digits.length > 1) {
    return '92${digits.substring(1)}';
  }
  return digits;
}

Future<void> openWhatsApp(BuildContext context, String mobileNo) async {
  final uri = Uri.parse('https://wa.me/${whatsAppNumber(mobileNo)}');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppToast(context, 'Could not open WhatsApp.', type: AppToastType.error);
  }
}

/// Opens the Google Maps app (or web fallback) with driving directions
/// routed to [destination] — used for "get directions to the client" from a
/// read-only location view, not for picking/editing a pin.
Future<void> openDirections(BuildContext context, LatLng destination) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
  );
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppToast(context, 'Could not open Google Maps.', type: AppToastType.error);
  }
}
