import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A label-value row for AI-generated content.
///
/// Simplified version of [UspInfoRow] without grid columns.
/// Used by all Section components to display data consistently.
class AiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const AiInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: AppText.labelLarge(label),
          ),
          Expanded(child: AppText.bodyMedium(value)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
