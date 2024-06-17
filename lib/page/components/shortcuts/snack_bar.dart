import 'package:flutter/material.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

showSuccessSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    background: Theme.of(context).colorSchemeExt.green,
  );
}

showFailedSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    background: Theme.of(context).colorScheme.error,
  );
}

showSimpleSnackBar(
  BuildContext context,
  String message, {
  Icon? icon,
  Color? background,
}) {
  showSnackBar(
    context,
    background: background,
    content: Row(
      children: [
        if (icon != null) ...[
          icon,
          const AppGap.medium(),
        ],
        AppText.labelMedium(
          message,
          color: Theme.of(context).colorScheme.onInverseSurface,
        ),
      ],
    ),
  );
}

showSnackBar(BuildContext context,
    {required Widget content, Color? background}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: ResponsiveLayout.isMobileLayout(context)
          ? const EdgeInsets.only(left: 24, right: 24, bottom: 24)
          : EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.6,
              right: 24,
              bottom: 24),
      content: content,
      backgroundColor: background,
    ),
  );
}
