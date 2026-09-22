import 'package:flutter/material.dart';

import '../models/category.dart';

const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);

/// Asks the provider which of their selected [categories] should be primary.
/// Returns the chosen category's id, or null if dismissed without choosing.
///
/// Used wherever a provider's category set changes to more than one category
/// (registration and the "My Categories" profile section) so the primary is
/// always an explicit choice rather than defaulting to alphabetical/list order.
Future<int?> showPrimaryCategoryDialog(
  BuildContext context, {
  required List<Category> categories,
  int? initialPrimaryId,
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PrimaryCategoryDialog(categories: categories, initialPrimaryId: initialPrimaryId),
  );
}

class _PrimaryCategoryDialog extends StatefulWidget {
  final List<Category> categories;
  final int? initialPrimaryId;

  const _PrimaryCategoryDialog({required this.categories, required this.initialPrimaryId});

  @override
  State<_PrimaryCategoryDialog> createState() => _PrimaryCategoryDialogState();
}

class _PrimaryCategoryDialogState extends State<_PrimaryCategoryDialog> {
  late int _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.categories.any((c) => c.id == widget.initialPrimaryId)
        ? widget.initialPrimaryId!
        : widget.categories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Primary Category',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2233), letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              Text(
                'This is shown as your main service and used where only one category can be displayed.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              for (final category in widget.categories)
                RadioListTile<int>(
                  value: category.id,
                  groupValue: _selectedId,
                  onChanged: (v) => setState(() => _selectedId = v!),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  activeColor: _brandBlue,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_selectedId),
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
