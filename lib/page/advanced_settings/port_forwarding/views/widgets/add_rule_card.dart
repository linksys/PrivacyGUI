import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class AddRuleCard extends StatelessWidget {
  final VoidCallback? onTap;
  final bool explicitChildNodes;
  final bool excludeSemantics;
  final String? identifier;
  final String? semanticLabel;

  const AddRuleCard({
    super.key,
    this.onTap,
    this.explicitChildNodes = false,
    this.excludeSemantics = false,
    this.identifier,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.large2),
      title: AppText.labelLarge(
        loc(context).addRule,
        identifier: identifier,
      ),
      trailing: Semantics(
          identifier: identifier != null ? '$identifier-add-icon' : null,
          label: semanticLabel != null ? '$semanticLabel add icon' : null,
          child: const Icon(LinksysIcons.add)),
      onTap: onTap,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      identifier: identifier,
      semanticLabel: semanticLabel,
    );
  }
}
