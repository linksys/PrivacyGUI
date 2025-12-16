import 'package:flutter/material.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

@Deprecated('Use UI Kit instead')
StatusLabel betaLabel() => StatusLabel(label: 'BETA');

@Deprecated('Use UI Kit instead')
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
          color: background ?? Theme.of(context).colorScheme.primary,
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(2)),
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Text(label,
          style: Theme.of(context).textSchemeExt.bodyExtraSmall?.copyWith(
              fontSize: 6,
              color: labelColor ?? Theme.of(context).colorScheme.onPrimary)),
    );
  }
}
