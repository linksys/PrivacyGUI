import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

enum ShareWifiOption {
  clipboard(displayTitle: 'Copy to clipboard', iconId: 'copyDefault'),
  qrCode(displayTitle: 'Send QR code', iconId: 'qrcodeDefault'),
  textMessage(displayTitle: 'Text message', iconId: 'smsDefault'),
  email(displayTitle: 'Email', iconId: 'mailB'),
  more(displayTitle: 'More options', iconId: 'optionsDefault');

  const ShareWifiOption({required this.displayTitle, required this.iconId});

  final String displayTitle;
  final String iconId;
}

class WiFiShareDetailView extends ConsumerStatefulWidget {
  final String ssid;
  final String password;
  const WiFiShareDetailView({
    Key? key,
    required this.ssid,
    required this.password,
  }) : super(key: key);

  @override
  ConsumerState<WiFiShareDetailView> createState() =>
      _WiFiShareDetailViewState();
}

class _WiFiShareDetailViewState extends ConsumerState<WiFiShareDetailView>
    with PageSnackbarMixin {
  GlobalKey globalKey = GlobalKey();
  String get sharingContent =>
      'Connect to my WiFi Network:\n${widget.ssid}\n\nPassword: ${widget.password}';

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wifiInfoSection(),
        // const AppGap.large3(),
        // _optionSection(),
        AppCard(child: _qrcodeSection()),
      ],
    );
  }

  Widget _qrcodeSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppText.labelLarge(loc(context).wifiShareQRScan),
          ),
          const Divider(),
          const AppGap.large2(),
          RepaintBoundary(
            key: globalKey,
            child: Container(
              color: Colors.white,
              height: ResponsiveLayout.isMobileLayout(context) ? 240 : 200,
              width: ResponsiveLayout.isMobileLayout(context) ? 240 : 200,
              child: QrImageView(
                data: WiFiCredential(
                  ssid: widget.ssid,
                  password: widget.password,
                  type: SecurityType
                      .wpa, //TODO: The security type is fixed for now
                ).generate(),
              ),
            ),
          ),
          const AppGap.large2(),
        ],
      ),
    );
  }

  Widget _shareSection() {
    return Row(
      children: [
        Expanded(
            child: AppTextButton(
          loc(context).textMessage,
          icon: LinksysIcons.sms,
          onTap: () {
            _shareBySMS();
          },
        )),
        Expanded(
            child: AppTextButton(
          loc(context).email,
          icon: LinksysIcons.mail,
          onTap: () {
            _shareByEmail();
          },
        )),
      ],
    );
  }

  Widget _wifiInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSettingCard(
          title: loc(context).wifiName,
          description: widget.ssid,
        ),
        const AppGap.small3(),
        AppListCard(
          title: AppText.bodyMedium(loc(context).wifiPassword),
          description: IntrinsicWidth(
            child: Theme(
              data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                      isDense: true, contentPadding: EdgeInsets.zero)),
              child: AppPasswordField(
                semanticLabel: 'wifi password',
                readOnly: true,
                border: InputBorder.none,
                controller: TextEditingController()..text = widget.password,
                suffixIconConstraints: const BoxConstraints(),
              ),
            ),
          ),
          trailing: AppIconButton(
            icon: LinksysIcons.fileCopy,
            semanticLabel: 'file copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.password))
                  .then((value) => showSharedCopiedSnackBar());
            },
          ),
        ),
        // AppText.labelLarge('${widget.numOfDevices} devices connected'),
      ],
    );
  }

  void _shareBySMS() async {
    final Uri smsUrl =
        Uri(scheme: 'sms', path: '', query: '&body=$sharingContent');
    await canLaunchUrl(smsUrl).then((isAllowed) {
      if (isAllowed) {
        launchUrl(smsUrl);
      } else {
        logger.e('Share WiFi - SMS: Cannot launch url');
      }
    });
  }

  void _shareByEmail() async {
    final Uri emailUrl = Uri(
        scheme: 'mailto',
        path: '',
        query: 'subject=Connect to my WiFi&body=$sharingContent');
    await canLaunchUrl(emailUrl).then((isAllowed) {
      if (isAllowed) {
        launchUrl(emailUrl);
      } else {
        logger.e('Share WiFi - Email: Cannot launch url');
      }
    });
  }

  void _shareByOtherWays() async {
    Size size = MediaQuery.of(context).size;
    await Share.shareWithResult(
      sharingContent,
      subject: 'Connect to my WiFi',
      sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
    ).then((result) {
      logger.d('Share WiFi - More options: result=${result.status}');
    });
  }
}
