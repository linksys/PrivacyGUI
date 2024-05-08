import 'package:flutter/material.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';

class AddRuleCard extends StatelessWidget {
  final VoidCallback? onTap;
  const AddRuleCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.semiBig),
      title: AppText.labelLarge(
        loc(context).addRule,
      ),
      trailing: const Icon(LinksysIcons.add),
      onTap: onTap,
    );
  }
}
