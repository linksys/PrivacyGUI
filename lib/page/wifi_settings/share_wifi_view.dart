import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
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

enum ShareWifiType {
  main(displayTitle: 'MAIN WIFI'),
  guest(displayTitle: 'GUEST WIFI'),
  legacy24(displayTitle: 'LEGACY 2.4 GHz');

  const ShareWifiType({required this.displayTitle});

  final String displayTitle;
}

class ShareWifiView extends StatefulWidget {
  const ShareWifiView({Key? key}) : super(key: key);

  @override
  _ShareWifiViewState createState() => _ShareWifiViewState();
}

class _ShareWifiViewState extends State<ShareWifiView> {
  ShareWifiType wifiType = ShareWifiType.main;
  String ssid = 'MyWiFiNetworkSSID';
  String password = 'Belkin123!';
  bool isPwSecure = true;

  Widget _wifiInfoSection() {
    return Column(
      children: [
        Text(
          wifiType.displayTitle,
          style: Theme.of(context).textTheme.headline4?.copyWith(
            color: Theme.of(context).colorScheme.tertiary
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          ssid,
          style: Theme.of(context).textTheme.headline2?.copyWith(
              color: Theme.of(context).colorScheme.primary
          ),
        ),
        Row(
          children: [
            Text(_getSecurePassword()),
            IconButton(
              icon: Icon(isPwSecure
                  ? Icons.remove_red_eye_outlined
                  : Icons.remove_red_eye_sharp),
              onPressed: () {
                setState(() {
                  isPwSecure = !isPwSecure;
                });
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Text(
            'JOIN THIS NETWORK',
            style: Theme.of(context).textTheme.headline4?.copyWith(
                color: Theme.of(context).colorScheme.tertiary
            ),
          ),
        ),
        SizedBox(
          child: QrImage(
            data: 'Connect to my WiFi Network:\n$ssid\n\nPassword: $password',
            padding: EdgeInsets.zero,
          ),
          height: 160,
          width: 160,
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  String _getSecurePassword() {
    String result = password;
    if (isPwSecure) {
      for (var i = 0; i < result.length - 2; i++) {
        result = result.replaceRange(i, i + 1, '*');
      }
    }
    return result;
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
                style: Theme.of(context)
                    .textTheme
                    .headline3
                    ?.copyWith(color: Theme.of(context).primaryColor),
              ),
              height: 80,
              alignment: Alignment.centerLeft,
              // color: Colors.red,
            ),
            onTap: () {
              _onOptionTapped(options[index]);
            },
          ),
          if (index != options.length - 1)
            const Divider(thickness: 1, height: 1, color: Colors.grey)
        ],
      );
    }));
  }

  void _onOptionTapped(ShareWifiOption option) async {
    switch (option) {
      case ShareWifiOption.clipboard:
      case ShareWifiOption.textMessage:
      case ShareWifiOption.email:
      case ShareWifiOption.more:
        final result = await Share.shareWithResult(
          subject: 'Connect to my WiFi',
          'Connect to my WiFi Network:\n$ssid\n\nPassword: $password',
        );
        if (result.status == ShareResultStatus.success) {
          //TODO: Show toast
        } else if (result.status == ShareResultStatus.dismissed) {
          print('User dismissed');
        }
        break;
      case ShareWifiOption.qrCode:
        final result = await Share.shareFilesWithResult(
            ['assets/images/place_node.png'],
            text: 'IIIIIMAGE', subject: 'SUBBB');
        print('resultt=${result.status}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Share Main WiFi',
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
