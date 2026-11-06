import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

/// Warns that the QR codes printed with the router are about to stop working,
/// with an info button explaining them. Setup and WiFi Settings both show it,
/// so the two surfaces look and explain the same.
class WiFiQRWarningCard extends StatelessWidget {
  final String message;

  const WiFiQRWarningCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Informational, not a validation failure - so not the error color.
    final color = Theme.of(context).colorSchemeExt.orange;
    // Laid out like the info cards it sits next to: same padding, icon size,
    // gap and text style. A triangle, so it does not read like the round
    // info button at the other end.
    return AppCard(
      borderColor: color,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            semanticLabel: 'warning',
            color: color,
          ),
          const AppGap.medium(),
          Expanded(
            child: AppText.bodySmall(message, maxLines: 30),
          ),
          const AppGap.medium(),
          AppIconButton.noPadding(
            icon: LinksysIcons.infoCircle,
            semanticLabel: 'info',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => showWiFiQRInfoModal(context),
          ),
        ],
      ),
    );
  }
}

/// What the printed QR codes contain and what happens to them once the WiFi
/// they encode changes.
Future<void> showWiFiQRInfoModal(BuildContext context) {
  return showSimpleAppDialog<void>(
    context,
    title: loc(context).modalWiFiQRInfoTitle,
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).modalWiFiQRInfoDesc1),
        const AppGap.medium(),
        AppText.bodyMedium(loc(context).modalWiFiQRInfoDesc2),
        const AppGap.medium(),
        AppText.bodyMedium(loc(context).modalWiFiQRInfoDesc3),
      ],
    ),
    actions: [
      AppTextButton(
        loc(context).close,
        onTap: () {
          context.pop();
        },
      ),
    ],
  );
}
