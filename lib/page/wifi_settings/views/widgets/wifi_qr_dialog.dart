import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart'
    if (dart.library.io) 'package:privacy_gui/util/export_selector/export_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/export_selector/export_web.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// One network the user can be handed a QR code for.
class WiFiQRBand {
  const WiFiQRBand({
    required this.label,
    required this.ssid,
    required this.password,
  });

  final String label;
  final String ssid;
  final String password;
}

/// Shown right after WiFi settings are saved: the QR codes printed on the Quick
/// Start Guide have just stopped working, so hand the user a replacement they
/// can print or download before they leave the page.
Future<void> showWiFiQRDialog(
  BuildContext context, {
  required List<WiFiQRBand> bands,
}) {
  return showSimpleAppDialog<void>(
    context,
    title: loc(context).wifiNewQRTitle,
    scrollable: true,
    // The default 328 is too narrow for a QR plus a Print / Download row side by
    // side; on mobile there is no room to widen, so the actions stack instead.
    width: ResponsiveLayout.isMobileLayout(context) ? null : 480.0,
    content: WiFiQRDialogContent(bands: bands),
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

class WiFiQRDialogContent extends StatefulWidget {
  const WiFiQRDialogContent({super.key, required this.bands});

  final List<WiFiQRBand> bands;

  @override
  State<WiFiQRDialogContent> createState() => _WiFiQRDialogContentState();
}

class _WiFiQRDialogContentState extends State<WiFiQRDialogContent>
    with PageSnackbarMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).wifiNewQRDesc, maxLines: 5),
        const AppGap.medium(),
        AppText.bodySmall(loc(context).wifiShareQRScan, maxLines: 3),
        const AppGap.large2(),
        if (widget.bands.length == 1)
          _unifiedCard(widget.bands.first)
        else
          ...widget.bands.map((band) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.small2),
                child: _perBandCard(band),
              )),
      ],
    );
  }

  // A single network: large QR, actions underneath, password on its own card -
  // the same shape the setup flow ends on.
  Widget _unifiedCard(WiFiQRBand band) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              _qrImage(band, size: 200),
              const AppGap.medium(),
              _actions(band),
            ],
          ),
        ),
        const AppGap.small2(),
        AppSettingCard(
          title: loc(context).wifiPassword,
          description: band.password,
          trailing: AppIconButton(
            icon: LinksysIcons.fileCopy,
            semanticLabel: 'file copy',
            onTap: () => _copyPassword(band.password),
          ),
        ),
      ],
    );
  }

  // Bands broadcasting different credentials each need their own QR. The card
  // is narrow, so the QR sits beside the details and the actions wrap.
  Widget _perBandCard(WiFiQRBand band) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _qrImage(band, size: 120),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(band.label),
                const AppGap.small1(),
                AppText.bodySmall(loc(context).wifiName),
                AppText.bodyMedium(band.ssid),
                const AppGap.small1(),
                AppText.bodySmall(loc(context).wifiPassword),
                Row(
                  children: [
                    Expanded(child: AppText.bodyMedium(band.password)),
                    AppIconButton.noPadding(
                      icon: LinksysIcons.fileCopy,
                      semanticLabel: 'file copy',
                      onTap: () => _copyPassword(band.password),
                    ),
                  ],
                ),
                const AppGap.small2(),
                _actions(band, wrap: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrImage(WiFiQRBand band, {required double size}) {
    return Container(
      color: Colors.white,
      height: size,
      width: size,
      child: QrImageView(
        data: WiFiCredential(
          ssid: band.ssid,
          password: band.password,
          type: SecurityType.wpa, //TODO: The security type is fixed for now
        ).generate(),
      ),
    );
  }

  // Printing or saving the new QR is the whole point of this dialog, so both
  // actions get button weight rather than plain text links.
  Widget _actions(WiFiQRBand band, {bool wrap = false}) {
    if (wrap) {
      // Labels get long in other locales and the per-band card is narrow.
      return Wrap(
        spacing: Spacing.small2,
        runSpacing: Spacing.small2,
        children: [
          AppOutlinedButton(
            loc(context).print,
            icon: LinksysIcons.print,
            onTap: () => _printWiFi(band),
          ),
          AppOutlinedButton(
            loc(context).downloadQR,
            icon: LinksysIcons.download,
            onTap: () => _downloadWiFi(band),
          ),
        ],
      );
    }
    final print = AppOutlinedButton.fillWidth(
      loc(context).print,
      icon: LinksysIcons.print,
      onTap: () => _printWiFi(band),
    );
    final download = AppOutlinedButton.fillWidth(
      loc(context).downloadQR,
      icon: LinksysIcons.download,
      onTap: () => _downloadWiFi(band),
    );
    // A mobile dialog is too narrow to put both labels on one line.
    if (ResponsiveLayout.isMobileLayout(context)) {
      return Column(
        children: [print, const AppGap.small2(), download],
      );
    }
    return Row(
      children: [
        Expanded(child: print),
        const AppGap.medium(),
        Expanded(child: download),
      ],
    );
  }

  void _printWiFi(WiFiQRBand band) {
    final ctx = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        createWiFiQRCode(_credential(band)).then((imageBytes) {
          if (!mounted) return;
          printWiFiQRCode(ctx, imageBytes, band.ssid, band.password);
        });
      }
    });
  }

  void _downloadWiFi(WiFiQRBand band) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        createWiFiQRCode(_credential(band)).then((imageBytes) {
          exportFileFromBytes(
              fileName: 'share_wifi_${band.ssid}.png', utf8Bytes: imageBytes);
        });
      }
    });
  }

  WiFiCredential _credential(WiFiQRBand band) => WiFiCredential(
        ssid: band.ssid,
        password: band.password,
        type: SecurityType.wpa,
      );

  void _copyPassword(String password) {
    service.Clipboard.setData(service.ClipboardData(text: password))
        .then((value) => showSharedCopiedSnackBar());
  }
}
