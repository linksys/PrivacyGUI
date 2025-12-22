import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Composed UI Kit version of AppPanelWithValueCheck
///
/// This component combines ui_kit elements to replicate the functionality
/// of the original privacygui_widgets AppPanelWithValueCheck.
///
/// Used for displaying selectable options with title, optional description,
/// value text, and a check indicator when selected.
class AppPanelWithValueCheck extends StatelessWidget {
  final String title;
  final String? description;
  final String valueText;
  final Color? valueTextColor;
  final bool isChecked;

  const AppPanelWithValueCheck({
    Key? key,
    required this.title,
    this.description,
    required this.valueText,
    this.valueTextColor,
    this.isChecked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = (description == null) ? 56.0 : 74.0;

    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isChecked
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.bodyLarge(title),
                if (description != null) ...[
                  AppGap.xs(),
                  AppText.bodyMedium(
                    description!,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          AppGap.md(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bodyLarge(
                valueText,
                color: valueTextColor,
              ),
              if (isChecked) ...[
                AppGap.sm(),
                AppIcon.font(
                  AppFontIcons.check,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
