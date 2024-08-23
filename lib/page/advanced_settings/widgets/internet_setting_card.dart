import 'package:flutter/material.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';

class InternetSettingCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final bool showBorder;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final bool? explicitChildNodes;
  final bool? excludeSemantics;
  final String? identifier;
  final String? semanticLabel;

  const InternetSettingCard({
    Key? key,
    required this.title,
    this.description,
    this.trailing,
    this.showBorder = true,
    this.padding,
    this.onTap,
    this.margin,
    this.explicitChildNodes,
    this.excludeSemantics,
    this.identifier,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppSettingCard(
      title: title,
      description: description,
      showBorder: showBorder,
      padding: padding,
      trailing: Semantics(
          identifier: '$identifier-trailing',
          label: '$semanticLabel trailing',
          child: trailing ?? const Icon(LinksysIcons.chevronRight)),
      onTap: onTap,
      margin: margin,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      identifier: identifier,
      semanticLabel: semanticLabel,
    );
  }
}
