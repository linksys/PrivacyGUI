import 'package:flutter/material.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

/// A balanced page title with a separate, predictable back target.
class InstantTestPageHeader extends StatelessWidget {
  const InstantTestPageHeader(
      {super.key,
      required this.title,
      required this.backLabel,
      required this.onBack,
      this.subtitle});
  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.medium, vertical: Spacing.small3),
        child: Row(children: [
          SizedBox(
              width: Spacing.large5,
              height: Spacing.large5,
              child: Tooltip(
                  message: backLabel,
                  child: AppIconButton(
                      icon: LinksysIcons.arrowBack,
                      semanticLabel: backLabel,
                      onTap: onBack))),
          Expanded(
              child: Column(children: [
            Semantics(
                header: true,
                child: AppText.titleLarge(title, textAlign: TextAlign.center)),
            if (subtitle != null) subtitle!,
          ])),
          const SizedBox(width: Spacing.large5),
        ]),
      );
}
