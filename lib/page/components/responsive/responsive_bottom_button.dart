import 'package:flutter/widgets.dart';
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
  required String title,
  bool enable = true,
  VoidCallback? onTap,
}) {
  return ResponsiveLayout.isLayoutBreakpoint(context)
      ? AppFilledButton.fillWidth(
          title,
          onTap: enable ? onTap : null,
        )
      : AppFilledButton(
          title,
          onTap: enable ? onTap : null,
        );
}
