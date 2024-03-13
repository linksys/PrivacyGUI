import 'package:flutter/material.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

showSuccessSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    icon: const Icon(
      LinksysIcons.check,
      color: Colors.white,
    ),
    background: Color(greenTonal.get(40)),
  );
}

showFailedSnackBar(BuildContext context, String message) {
  showSimpleSnackBar(
    context,
    message,
    icon: const Icon(
      LinksysIcons.close,
      color: Colors.white,
    ),
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
    content: Container(
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            icon ?? const Center(),
            const AppGap.regular(),
            Text(message),
          ],
        ),
      ),
    ),
  );
}

showSnackBar(BuildContext context,
    {required Widget content, Color? background}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: background,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      content: content,
    ),
  );
}
