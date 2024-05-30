import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
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
  final int numOfDevices;
  const WiFiShareDetailView({
    Key? key,
    required this.ssid,
    required this.password,
    required this.numOfDevices,
  }) : super(key: key);

  @override
  ConsumerState<WiFiShareDetailView> createState() =>
      _WiFiShareDetailViewState();
}

class _WiFiShareDetailViewState extends ConsumerState<WiFiShareDetailView> {
  GlobalKey globalKey = GlobalKey();
  String get sharingContent =>
      'Connect to my WiFi Network:\n${widget.ssid}\n\nPassword: ${widget.password}';

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      scrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.semiBig),
      menuWidget: ResponsiveLayout.isLayoutBreakpoint(context)
          ? null
          : IntrinsicWidth(child: _qrcodeSection()),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wifiInfoSection(),
            // const AppGap.big(),
            // _optionSection(),
            if (ResponsiveLayout.isLayoutBreakpoint(context))
              AppCard(child: _qrcodeSection()),
            if (!ResponsiveLayout.isLayoutBreakpoint(context))
              AppCard(child: _shareSection()),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
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
          const AppGap.semiBig(),
          RepaintBoundary(
            key: globalKey,
            child: Container(
              color: Colors.white,
              height: ResponsiveLayout.isLayoutBreakpoint(context) ? 240 : 200,
              width: ResponsiveLayout.isLayoutBreakpoint(context) ? 240 : 200,
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
          const AppGap.semiBig(),
          const Divider(),
          if (ResponsiveLayout.isLayoutBreakpoint(context)) _shareSection(),
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
        const AppGap.small(),
        AppListCard(
          title: AppText.bodyMedium(loc(context).wifiPassword),
          description: IntrinsicWidth(
            child: Theme(
              data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                      isDense: true, contentPadding: EdgeInsets.zero)),
              child: AppPasswordField(
                readOnly: true,
                border: InputBorder.none,
                controller: TextEditingController()..text = widget.password,
                suffixIconConstraints: const BoxConstraints(),
              ),
            ),
          ),
          trailing: AppIconButton(
            icon: LinksysIcons.copyAll,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.password)).then(
                  (value) =>
                      showSuccessSnackBar(context, loc(context).sharedCopied));
            },
          ),
        ),
        // AppText.labelLarge('${widget.numOfDevices} devices connected'),
      ],
    );
  }

  void _shareByClipboard() {
    Clipboard.setData(ClipboardData(text: sharingContent))
        .then((value) => showSuccessSnackBar(context, 'Copied to clipboard'));
  }

  void _shareByQrCode() async {
    Size size = MediaQuery.of(context).size;
    // Capture the image of this render object convert it to byte data
    final RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    // Save the image byte data to the temp directory
    Uri fileUri =
        Uri.parse('${Storage.tempDirectory?.path}/shared_wifi_qr_code.png');
    logger.i('Share WiFi - QRCode: Saved path=${fileUri.path}');

    await Storage.saveByteFile(fileUri, pngBytes).then((_) async {
      await Share.shareFilesWithResult(
        [fileUri.path],
        text: 'Connect to my WiFi',
        sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
      ).then((result) {
        logger.d('Share WiFi - QRCode: result=${result.status}');
        // Delete the qr code image once the sharing operation ends
        Storage.deleteFile(fileUri);
      });
    });
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
