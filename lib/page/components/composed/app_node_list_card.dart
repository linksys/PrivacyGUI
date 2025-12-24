import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A node list card with image, title, description and trailing widget.
///
/// This component was migrated from privacygui_widgets to decouple dependencies.
class AppNodeListCard extends StatelessWidget {
  final ImageProvider leading;
  final String title;
  final String? description;
  final Widget? trailing;
  final String? band;
  final VoidCallback? onTap;
  final void Function(bool)? onSelected;
  final bool isSelected;
  final Color? color;
  final Color? borderColor;

  const AppNodeListCard({
    super.key,
    required this.leading,
    required this.title,
    this.description,
    required this.trailing,
    this.band,
    this.isSelected = false,
    this.onTap,
    this.onSelected,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Leading section with optional checkbox
            if (onSelected != null) ...[
              AppCheckbox(
                value: isSelected,
                onChanged: (value) => onSelected?.call(value ?? false),
              ),
              AppGap.lg(),
            ],
            // Image
            SizedBox(
              width: 48,
              height: 48,
              child: Image(
                image: leading,
                fit: BoxFit.contain,
              ),
            ),
            AppGap.lg(),
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title),
                  if (description != null) AppText.bodySmall(description!),
                ],
              ),
            ),
            // Band and trailing
            if (band != null) ...[
              AppGap.lg(),
              AppText.labelLarge(band!),
            ],
            if (trailing != null) ...[
              AppGap.lg(),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
