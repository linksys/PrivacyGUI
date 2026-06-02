import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'block_constants.dart';

// =============================================================================
// Block - Universal wrapper with surfaceContainerHighest background
// =============================================================================

/// Base block wrapper for semantic grouping within cards.
///
/// Use inside [AppCard] to create visual separation between content groups.
/// Supports optional tap handler for interactive blocks.
class Block extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const Block({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: padding ?? BlockConstants.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: BlockConstants.backgroundAlpha),
        borderRadius: BorderRadius.circular(BlockConstants.borderRadius),
        border: showBorder
            ? Border.all(
                color: colorScheme.outline
                    .withValues(alpha: BlockConstants.borderAlpha))
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BlockConstants.borderRadius),
      child: content,
    );
  }
}

// =============================================================================
// CardHeader - Unified card header with consistent height
// =============================================================================

/// Standard card header with title and optional trailing widget.
///
/// Fixed height ensures consistent vertical rhythm across cards.
class CardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const CardHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppText.titleMedium(title),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
