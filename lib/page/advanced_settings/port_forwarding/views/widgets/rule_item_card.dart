import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class RuleItemCard extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final VoidCallback? onTap;
  final bool explicitChildNodes;
  final bool excludeSemantics;
  final String? identifier;
  final String? semanticLabel;

  const RuleItemCard({
    super.key,
    required this.title,
    required this.isEnabled,
    this.onTap,
    this.explicitChildNodes = true,
    this.excludeSemantics = false,
    this.identifier,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.large2),
      title: AppText.labelLarge(
        title,
        identifier: identifier != null ? '$identifier-title' : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(
            isEnabled ? loc(context).on : loc(context).off,
            identifier: identifier != null ? '$identifier-${isEnabled ? 'on' : 'off'}' : null,
          ),
          const AppGap.medium(),
          Semantics(
              identifier: identifier != null ? '$identifier-icon' : null,
              label: semanticLabel != null ? '$semanticLabel icon' : null,
              child: const Icon(LinksysIcons.edit)),
        ],
      ),
      onTap: onTap,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      identifier: identifier,
      semanticLabel: semanticLabel,
    );
  }
}
