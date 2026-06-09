import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A titled header for sections within a card.
///
/// Use to group related content with an optional badge and trailing widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                AppText.titleSmall(title),
                if (badge != null) ...[
                  AppGap.sm(),
                  badge!,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
