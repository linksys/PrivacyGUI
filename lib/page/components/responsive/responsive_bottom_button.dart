import 'package:flutter/widgets.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_widgets/widgets/base/gap.dart';
import 'package:linksys_widgets/widgets/buttons/button.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

Widget responsiveGap(BuildContext context) {
  return ResponsiveLayout.isLayoutBreakpoint(context)
      ? const Spacer()
      : const AppGap.big();
}

Widget responsiveBottomButton({
  required BuildContext context,
  String? title,
  VoidCallback? onTap,
}) {
  return ResponsiveLayout.isLayoutBreakpoint(context)
      ? AppFilledButton.fillWidth(
          title ?? loc(context).save,
          onTap: onTap,
        )
      : AppFilledButton(
          title ?? loc(context).save,
          onTap: onTap,
        );
}
