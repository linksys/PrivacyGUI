import 'package:flutter/material.dart';
import 'package:linksys_app/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

@Deprecated('Use #package:linksys_widgets/panel/AppSection instead')
Widget administrationSection({
  required String title,
  required Widget content,
  Widget? headerAction,
  bool enabled = false,
  EdgeInsets? contentPadding,
  Color? contentBackground,
}) {
  return SectionTile(
    header: Padding(
      padding: const EdgeInsets.all(Spacing.regular),
      child: Container(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: AppText.titleLarge(title)),
              if (headerAction != null) headerAction,
            ],
          ),
        ),
      ),
    ),
    child: content,
  );
}
