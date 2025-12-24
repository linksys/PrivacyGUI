import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

class WifiListTile extends StatelessWidget {
  final Widget title;
  final Widget? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  const WifiListTile({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (description != null) ...[
                      AppGap.xs(),
                      description!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                AppGap.md(),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
