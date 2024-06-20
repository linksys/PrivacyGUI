import 'package:flutter/material.dart';
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
  const RuleItemCard(
      {super.key, required this.title, required this.isEnabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.large1),
      title: AppText.labelLarge(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(
            isEnabled ? loc(context).on : loc(context).off,
          ),
          const AppGap.medium(),
          const Icon(LinksysIcons.edit),
        ],
      ),
      onTap: onTap,
    );
  }
}
