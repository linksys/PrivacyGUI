import 'package:flutter/material.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

/// The router's standard page title row (as in LinksysAppBar.withBack): a back
/// arrow, then a left-aligned title. The back target keeps a specific label.
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
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.small2),
          child: Row(children: [
            ConstrainedBox(
                constraints: const BoxConstraints(minWidth: Spacing.large3),
                child: Tooltip(
                    message: backLabel,
                    child: AppIconButton(
                        padding: const EdgeInsets.all(Spacing.small1),
                        icon: LinksysIcons.arrowBack,
                        semanticLabel: backLabel,
                        onTap: onBack))),
            const SizedBox(width: Spacing.medium),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Semantics(
                      header: true,
                      child: AppText.titleLarge(title,
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (subtitle != null) subtitle!,
                ])),
          ]),
        ),
      );
}
