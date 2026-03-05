import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A label–value row used throughout the USP Dashboard cards.
class UspInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const UspInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: labelWidth, child: AppText.labelLarge(label)),
          Expanded(child: AppText.bodyMedium(value)),
        ],
      ),
    );
  }
}
