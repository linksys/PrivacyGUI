import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AppMenuCard extends StatelessWidget {
  const AppMenuCard({
    super.key,
    this.iconData,
    this.title,
    this.description,
    this.onTap,
    this.status,
    this.isBeta = false,
  });

  final IconData? iconData;
  final String? title;
  final String? description;
  final VoidCallback? onTap;
  final bool? status;
  final bool isBeta;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FittedBox(
                fit: BoxFit.fill,
                child: iconData != null
                    ? AppIcon.font(
                        iconData!,
                        size: 24,
                      )
                    : null,
              ),
              if (status != null)
                AppBadge(
                  label: status! ? 'Off' : 'On',
                  color: status!
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticSuccess ??
                          Colors.green,
                )
            ],
          ),
          if (title != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Flexible(
                    child: AppText.titleSmall(
                      title ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isBeta) ...[
                    AppGap.sm(),
                    AppBadge(
                      label: 'BETA',
                      color: Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticWarning ??
                          Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: AppText.bodySmall(
                description ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: !context.isMobileLayout ? 3 : 1,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
