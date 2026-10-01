import 'package:flutter/material.dart';

import 'provider_tab_header.dart' show providerBrandBlue, providerBrandDark;

/// Small left-accented section title used across provider profile screens
/// (e.g. "Provider Details", "My Categories", "My Service Titles").
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: providerBrandBlue,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14213D),
                    letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }
}

/// White, shadowed container used for grouped [ListTile] rows, matching the
/// customer profile screen's card style (see `screens/profile_screen.dart`).
class InfoCard extends StatelessWidget {
  final List<Widget> children;
  const InfoCard({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: providerBrandDark.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
