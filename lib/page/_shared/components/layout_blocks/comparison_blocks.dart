import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/status_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

// =============================================================================
// VersionBlock - Before/After version comparison
// =============================================================================

class VersionBlock extends StatelessWidget {
  final String currentLabel;
  final String currentValue;
  final String? newLabel;
  final String? newValue;
  final bool showNewBadge;

  const VersionBlock({
    super.key,
    this.currentLabel = 'Current',
    required this.currentValue,
    this.newLabel,
    this.newValue,
    this.showNewBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNew = newValue != null && newValue!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _VersionCard(
            label: currentLabel,
            value: currentValue,
          ),
        ),
        if (hasNew) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AppIcon.font(
              Icons.arrow_forward,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _VersionCard(
              label: newLabel ?? 'Available',
              value: newValue!,
              showBadge: showNewBadge,
            ),
          ),
        ],
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String label;
  final String value;
  final bool showBadge;

  const _VersionCard({
    required this.label,
    required this.value,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Block(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              AppGap.xs(),
              AppText.titleSmall(value),
            ],
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: AppBadge(label: 'NEW'),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// ComparisonBlock - A vs B side-by-side
// =============================================================================

class ComparisonBlock extends StatelessWidget {
  final String beforeLabel;
  final Widget beforeContent;
  final String afterLabel;
  final Widget afterContent;

  const ComparisonBlock({
    super.key,
    this.beforeLabel = 'Before',
    required this.beforeContent,
    this.afterLabel = 'After',
    required this.afterContent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border(
                left: BorderSide(
                  color: colorScheme.onSurfaceVariant,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall(
                  beforeLabel.toUpperCase(),
                  color: colorScheme.onSurfaceVariant,
                ),
                AppGap.sm(),
                beforeContent,
              ],
            ),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall(
                  afterLabel.toUpperCase(),
                  color: colorScheme.primary,
                ),
                AppGap.sm(),
                afterContent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
