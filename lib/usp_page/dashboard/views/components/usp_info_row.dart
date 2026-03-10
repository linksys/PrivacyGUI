import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A label–value row used throughout the USP Dashboard cards.
///
/// Uses the UI Kit 12-column grid system for responsive label sizing.
/// [labelColumns] controls how many grid columns the label occupies
/// (default 2, calculated via `context.colWidth()`).
class UspInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int labelColumns;

  const UspInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.colWidth(labelColumns),
            child: AppText.labelLarge(label),
          ),
          Expanded(child: AppText.bodyMedium(value)),
        ],
      ),
    );
  }
}
