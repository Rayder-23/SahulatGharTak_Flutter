import 'package:flutter/material.dart';

/// Compact error row for a single form field that failed to load its own
/// data (e.g. a city dropdown whose options never arrived) - too small a
/// space for a full [TabStatePlaceholder]/`EmptyStatePlaceholder`, but still
/// needs to say what went wrong instead of just showing an empty field with
/// no explanation.
class InlineFieldError extends StatelessWidget {
  const InlineFieldError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600))),
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.red,
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
