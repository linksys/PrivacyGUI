import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/widgets/wifi_qr/wifi_qr_band.dart';
import 'package:privacy_gui/util/qr_code.dart';
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

/// The QR codes for a WiFi the printed codes no longer join, with Print,
/// Download QR and the password to copy - what both the end of setup and a
/// WiFi Settings save hand the user.
///
/// One band gets a single large code; bands broadcasting different
/// credentials each get a compact card of their own.
class WiFiQRCards extends StatefulWidget {
  final List<WiFiQRBand> bands;

  /// Side of the single large code. Per-band codes are always compact.
  final double qrSize;

  const WiFiQRCards({super.key, required this.bands, this.qrSize = 200});

  @override
  State<WiFiQRCards> createState() => _WiFiQRCardsState();
}

class _WiFiQRCardsState extends State<WiFiQRCards> with PageSnackbarMixin {
  static const double _bandQRSize = 120;

  @override
  Widget build(BuildContext context) {
    if (widget.bands.length == 1) {
      return _singleCard(widget.bands.single);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final band in widget.bands)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.small2),
            child: _bandCard(band),
          ),
      ],
    );
  }

  // Large code with the actions underneath, password on its own card.
  Widget _singleCard(WiFiQRBand band) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          child: Column(
            children: [
              _qrImage(band, widget.qrSize),
              const AppGap.medium(),
              _wideActions(band),
            ],
          ),
        ),
        if (band.hasPassword) ...[
          const AppGap.small2(),
          AppSettingCard(
            title: loc(context).wifiPassword,
            description: band.credential.password,
            trailing: AppIconButton(
              icon: LinksysIcons.fileCopy,
              semanticLabel: 'file copy',
              onTap: () => _copyPassword(band),
            ),
          ),
        ],
      ],
    );
  }

  // The card is narrow, so the code sits beside the details.
  Widget _bandCard(WiFiQRBand band) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _qrImage(band, _bandQRSize),
          const AppGap.medium(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.labelLarge(band.label),
                const AppGap.small1(),
                AppText.bodySmall(loc(context).wifiName),
                AppText.bodyMedium(band.credential.ssid),
                if (band.hasPassword) ...[
                  const AppGap.small1(),
                  AppText.bodySmall(loc(context).wifiPassword),
                  Row(
                    children: [
                      Expanded(
                        child: AppText.bodyMedium(band.credential.password),
                      ),
                      AppIconButton.noPadding(
                        icon: LinksysIcons.fileCopy,
                        semanticLabel: 'file copy',
                        onTap: () => _copyPassword(band),
                      ),
                    ],
                  ),
                ],
                const AppGap.small2(),
                _compactActions(band),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrImage(WiFiQRBand band, double size) {
    return Container(
      color: Colors.white,
      height: size,
      width: size,
      child: QrImageView(data: band.credential.generate()),
    );
  }

  // Printing or downloading the new code is the point here, so both actions
  // get button weight. They share the width, and stack on a phone where the
  // two labels do not fit side by side.
  Widget _wideActions(WiFiQRBand band) {
    final printButton = AppOutlinedButton.fillWidth(
      loc(context).print,
      icon: LinksysIcons.print,
      onTap: () => _printQR(band),
    );
    final downloadButton = AppOutlinedButton.fillWidth(
      loc(context).downloadQR,
      icon: LinksysIcons.download,
      onTap: () => _downloadQR(band),
    );
    if (ResponsiveLayout.isMobileLayout(context)) {
      return Column(
        children: [printButton, const AppGap.small2(), downloadButton],
      );
    }
    return Row(
      children: [
        Expanded(child: printButton),
        const AppGap.medium(),
        Expanded(child: downloadButton),
      ],
    );
  }

  // A band card is narrow and these labels get long in other locales, so the
  // actions wrap.
  Widget _compactActions(WiFiQRBand band) {
    return Wrap(
      spacing: Spacing.medium,
      runSpacing: Spacing.small1,
      children: [
        AppOutlinedButton(
          loc(context).print,
          icon: LinksysIcons.print,
          onTap: () => _printQR(band),
        ),
        AppOutlinedButton(
          loc(context).downloadQR,
          icon: LinksysIcons.download,
          onTap: () => _downloadQR(band),
        ),
      ],
    );
  }

  void _printQR(WiFiQRBand band) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      createWiFiQRCode(band.credential).then((imageBytes) {
        if (!mounted) return;
        printWiFiQRCode(
          context,
          imageBytes,
          band.credential.ssid,
          band.hasPassword ? band.credential.password : '',
        );
      });
    });
  }

  void _downloadQR(WiFiQRBand band) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      createWiFiQRCode(band.credential).then((imageBytes) {
        exportFileFromBytes(
          fileName: 'share_wifi_${band.credential.ssid}.png',
          utf8Bytes: imageBytes,
        );
      });
    });
  }

  void _copyPassword(WiFiQRBand band) {
    service.Clipboard.setData(
            service.ClipboardData(text: band.credential.password))
        .then((value) => showSharedCopiedSnackBar());
  }
}
