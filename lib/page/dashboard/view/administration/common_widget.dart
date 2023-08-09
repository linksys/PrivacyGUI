import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

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
    header: AppPadding(
      child: Container(
        alignment: Alignment.bottomLeft,
        child: AppPadding(
          padding: const AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: AppText.tags(title)),
              if (headerAction != null) headerAction,
            ],
          ),
        ),
      ),
    ),
    child: content,
  );
}
