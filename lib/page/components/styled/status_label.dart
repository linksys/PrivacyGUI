import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

StatusLabel betaLabel() => StatusLabel(label: 'Beta');

class StatusLabel extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? labelColor;
  const StatusLabel({
    super.key,
    required this.label,
    this.background,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: background ?? Theme.of(context).colorScheme.secondaryContainer,
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: AppText.bodyExtraSmall(label),
    );
  }
}
