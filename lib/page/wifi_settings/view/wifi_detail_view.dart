import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/core/utils/storage.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/util/wifi_credential.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
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

class WifiDetailView extends ConsumerStatefulWidget {
  final WifiListItem item;
  const WifiDetailView({Key? key, required this.item}) : super(key: key);

  @override
  ConsumerState<WifiDetailView> createState() => _WifiDetailViewState();
}

class _WifiDetailViewState extends ConsumerState<WifiDetailView> {
  GlobalKey globalKey = GlobalKey();
  String get sharingContent =>
      'Connect to my WiFi Network:\n${widget.item.ssid}\n\nPassword: ${widget.item.password}';

  @override
  initState() {
    super.initState();
  }

  Widget _qrcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.labelLarge(
          'JOIN THIS NETWORK',
        ),
        const AppGap.regular(),
        RepaintBoundary(
          key: globalKey,
          child: Container(
            color: Colors.white,
            height: 240,
            width: 240,
            child: QrImageView(
              data: WiFiCredential(
                ssid: widget.item.ssid,
                password: widget.item.password,
                type:
                    SecurityType.wpa, //TODO: The security type is fixed for now
              ).generate(),
            ),
          ),
        ),
        const AppGap.regular(),
      ],
    );
  }

  Widget _wifiInfoSection() {
    return AppPadding.regular(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AbsorbPointer(
              absorbing: true,
              child: AppSwitch(
                value: widget.item.isWifiEnabled,
                onChanged: (value) {},
              ),
            ),
          ),
          AppText.labelLarge('WiFi name'),
          const AppGap.small(),
          AppText.headlineMedium(
            widget.item.ssid,
          ),
          const AppGap.regular(),
          AppText.labelLarge('Password'),
          const AppGap.small(),
          HiddenPasswordWidget(password: widget.item.password),
          const AppGap.small(),
          AppText.labelLarge('${widget.item.numOfDevices} devices connected'),
        ],
      ),
    );
  }

  Widget _optionSection() {
    final List<ShareWifiOption> options = [
      ShareWifiOption.clipboard,
      ShareWifiOption.qrCode,
      ShareWifiOption.textMessage,
      ShareWifiOption.email,
      ShareWifiOption.more,
    ];

    return Column(
        children: List.generate(options.length, (index) {
      return Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            // child: Container(
            //   child: AppText.textLinkLarge(
            //     options[index].displayTitle,
            //   ),
            //   height: 80,
            //   alignment: Alignment.centerLeft,
            // ),
            child: AppSimplePanel(
              title: options[index].displayTitle,
              icon:
                  getCharactersIcons(context).getByName(options[index].iconId),
            ),
            onTap: () {
              _onOptionTapped(options[index]);
            },
          ),
        ],
      );
    }));
  }

  void _shareByClipboard() async {
    await Clipboard.setData(ClipboardData(text: sharingContent));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: AppText.bodyLarge(
      'Copied to clipboard',
    )));
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

  void _onOptionTapped(ShareWifiOption option) {
    switch (option) {
      case ShareWifiOption.clipboard:
        _shareByClipboard();
        break;
      case ShareWifiOption.qrCode:
        _shareByQrCode();
        break;
      case ShareWifiOption.textMessage:
        _shareBySMS();
        break;
      case ShareWifiOption.email:
        _shareByEmail();
        break;
      case ShareWifiOption.more:
        _shareByOtherWays();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      scrollable: true,
      padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.semiBig),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.regular(),
            Card(child: _wifiInfoSection()),
            const AppGap.big(),
            _optionSection(),
            const AppGap.big(),
            _qrcodeSection(),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
