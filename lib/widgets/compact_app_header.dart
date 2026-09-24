import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Compact branded top bar — a shorter, flatter alternative to Flutter's
/// default [AppBar] (no shadow, reduced height) for screens like full-screen
/// pickers where maximizing content height matters more than a tall header.
class CompactAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color color;

  const CompactAppHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.color = kPrimaryColor,
  });

  static const double height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
