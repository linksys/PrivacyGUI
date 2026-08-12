import 'package:flutter/material.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';
import 'package:ui_kit_library/ui_kit.dart';

class AppMenuCard extends StatelessWidget {
  const AppMenuCard({
    super.key,
    this.iconData,
    this.title,
    this.description,
    this.onTap,
    this.badges = const [],
    this.semanticLabel,
    this.identifier,
  });

  final IconData? iconData;
  final String? title;
  final String? description;
  final VoidCallback? onTap;
  final List<MenuBadge> badges;
  final String? semanticLabel;

  /// Stable E2E test hook, mapped to the `flt-semantics-identifier` DOM attr
  /// (silent to screen readers). Prefer this over [semanticLabel] for test
  /// slugs so the accessible name stays the localized [title].
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final card = AppCard(
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
              if (badges.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < badges.length; i++) ...[
                      if (i > 0) AppGap.xs(),
                      AppBadge(
                        label: badges[i].label,
                        color: badges[i].color ??
                            _defaultColorForLabel(
                                badges[i].label, colorScheme, appColors),
                        textColor: badges[i].textColor,
                      ),
                    ],
                  ],
                ),
            ],
          ),
          if (title != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: AppText.titleSmall(
                title ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: AppText.bodySmall(
                description ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: !context.isMobileLayout ? 3 : 1,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
    if (semanticLabel != null || identifier != null) {
      return Semantics(
        label: semanticLabel,
        identifier: identifier,
        button: true,
        child: card,
      );
    }
    return card;
  }

  Color _defaultColorForLabel(
    String label,
    ColorScheme colorScheme,
    AppColorScheme? appColors,
  ) {
    switch (label.toUpperCase()) {
      case 'ON':
        return appColors?.semanticSuccess ?? Colors.green;
      case 'OFF':
        return colorScheme.outline;
      case 'BETA':
        return appColors?.semanticWarning ?? Colors.orange;
      default:
        return colorScheme.secondary;
    }
  }
}
