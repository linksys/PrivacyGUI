import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_qr_credentials.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_qr_cards.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

/// Shown right after WiFi settings are saved: the QR codes that came printed
/// with the router have just stopped working, so hand the user a replacement
/// they can print or download before they leave the page - the same content
/// setup ends on.
Future<void> showWiFiQRDialog(
  BuildContext context, {
  required List<WiFiQRBand> bands,
}) {
  return showSimpleAppDialog<void>(
    context,
    title: loc(context).wifiNewQRTitle(bands.length),
    scrollable: true,
    // The default 328 is too narrow for a QR plus a Print / Download row side by
    // side; on mobile there is no room to widen, so the actions stack instead.
    width: ResponsiveLayout.isMobileLayout(context) ? null : 480.0,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).wifiNewQRDesc(bands.length),
            maxLines: 5),
        const AppGap.medium(),
        AppText.bodySmall(loc(context).pnpScanQR, maxLines: 3),
        const AppGap.large2(),
        WiFiQRCards(bands: bands),
        const AppGap.medium(),
        // Where to find the code again once the dialog is closed.
        AppText.bodySmall(
          loc(context).pnpWiFiReadyReshareInfo(bands.length),
          maxLines: 5,
        ),
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
