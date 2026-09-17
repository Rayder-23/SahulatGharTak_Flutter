import 'package:flutter/material.dart';

import '../utils/constants.dart';

enum AppToastType { success, error, info }

/// A small, branded, auto-dismissing toast for transient feedback (form
/// validation nudges, quick success/failure confirmations) that shouldn't
/// interrupt the user the way [showMessageDialog] does. Visually matches
/// [showMessageDialog]'s icon/color language so the two feel like one
/// design system rather than two unrelated components.
///
/// Deliberately has no action button - a toast that requires a tap to
/// dismiss isn't a toast. It auto-hides after [duration], and (via the
/// underlying [SnackBar]) can still be swiped away sooner if desired.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  Color color;
  IconData icon;
  switch (type) {
    case AppToastType.success:
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
      break;
    case AppToastType.error:
      color = Colors.red;
      icon = Icons.error_outline_rounded;
      break;
    case AppToastType.info:
      color = kPrimaryColor;
      icon = Icons.info_outline_rounded;
      break;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1A2233),
      elevation: 6,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
