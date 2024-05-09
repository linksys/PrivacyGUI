import 'package:flutter/material.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';

class EmptyRuleCard extends StatelessWidget {
  const EmptyRuleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: SizedBox(
      height: 180,
      child: Center(
        child: AppText.bodyLarge(loc(context).noRules),
      ),
    ));
  }
}
