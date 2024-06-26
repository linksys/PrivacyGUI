import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class AddRuleCard extends StatelessWidget {
  final VoidCallback? onTap;
  const AddRuleCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.large2),
      title: AppText.labelLarge(
        loc(context).addRule,
      ),
      trailing: const Icon(LinksysIcons.add),
      onTap: onTap,
    );
  }
}
