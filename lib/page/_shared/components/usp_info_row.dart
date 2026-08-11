import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A label–value row used throughout the USP Dashboard cards.
///
/// The label column is sized from the width the row is actually given
/// (read via a [LayoutBuilder]), not from screen width. [labelColumns]
/// controls the fraction of a nominal 12-column grid the label occupies
/// (default 2 of 12). Sizing against the real available width keeps the
/// value legible when the row lives inside a shrunken card, where a
/// screen-derived width would over-claim the label column and clip the
/// value against the card surface with no overflow raised.
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = constraints.maxWidth * labelColumns / 12;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: AppText.labelLarge(label),
              ),
              Expanded(child: AppText.bodyMedium(value)),
            ],
          );
        },
      ),
    );
  }
}
