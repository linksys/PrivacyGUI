import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

enum ShareWifiOption {
  clipboard(displayTitle: 'Copy to clipboard'),
  qrCode(displayTitle: 'Send QR code'),
  textMessage(displayTitle: 'Text message'),
  email(displayTitle: 'Email'),
  more(displayTitle: 'More options');

  const ShareWifiOption({required this.displayTitle});

  final String displayTitle;
}

class ShareWifiView extends ArgumentsStatefulView {
  const ShareWifiView({Key? key, super.args}) : super(key: key);

  @override
  _ShareWifiViewState createState() => _ShareWifiViewState();
}

class _ShareWifiViewState extends State<ShareWifiView> {
  GlobalKey globalKey = GlobalKey();
  late WifiListItem _currentItem;
  String get sharingContent =>
      'Connect to my WiFi Network:\n${_currentItem.ssid}\n\nPassword: ${_currentItem.password}';

  @override
  initState() {
    super.initState();
    if (widget.args.containsKey('info')) {
      _currentItem = widget.args['info'];
    }
  }

  Widget _wifiInfoSection() {
    return Column(
      children: [
        Text(
          _currentItem.wifiType.displayTitle,
          style: Theme.of(context).textTheme.headline4,
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          _currentItem.ssid,
          style: Theme.of(context).textTheme.headline2,
        ),
        HiddenPasswordWidget(password: _currentItem.password),
        const SizedBox(
          height: 40,
        ),
        Text(
          'JOIN THIS NETWORK',
          style: Theme.of(context).textTheme.headline4,
        ),
        const SizedBox(
          height: 20,
        ),
        RepaintBoundary(
          key: globalKey,
          child: SizedBox(
            child: QrImage(
              data: sharingContent,
              padding: EdgeInsets.zero,
            ),
            height: 160,
            width: 160,
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Container(
              child: Text(
                options[index].displayTitle,
                style: Theme.of(context).textTheme.headline3,
              ),
              height: 80,
              alignment: Alignment.centerLeft,
            ),
            onTap: () {
              _onOptionTapped(options[index]);
            },
          ),
          if (index != options.length - 1)
            const Divider(thickness: 1, height: 1, color: MoabColor.dividerGrey)
        ],
      );
    }));
  }

  void _shareByClipboard() async {
    await Clipboard.setData(ClipboardData(text: sharingContent));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      'Copied to clipboard',
      style: Theme.of(context)
          .textTheme
          .bodyText1
          ?.copyWith(color: Theme.of(context).primaryColor),
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
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: 'Share ${_currentItem.wifiType.displayTitle} WiFi',
        ),
        content: Column(
          children: [
            _wifiInfoSection(),
            _optionSection(),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
