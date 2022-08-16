import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

class WifiListView extends StatefulWidget {
  const WifiListView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WifiListViewState();
}

class _WifiListViewState extends State<WifiListView> {
  //TODO: Remove the dummy data
  final List<WifiListItem> items = [
    WifiListItem(WifiType.main, 'MyMainNetwork', '01234567', WifiSecurityType.wpa2Wpa3Mixed, WifiMode.mixed, true, 22, 100),
    WifiListItem(WifiType.guest, 'MyGuestNetwork', '12345678', WifiSecurityType.wpa2, WifiMode.mixed, true, 33, 100),
    WifiListItem(WifiType.iot, 'MyIotNetwork_1', '23456789', WifiSecurityType.openAndEnhancedOpen, WifiMode.mixed, false, 44, 100),
    WifiListItem(WifiType.iot, 'MyIotNetwork_2', '34567890', WifiSecurityType.open, WifiMode.mixed, true, 55, 100),
  ];

  Widget _wifiList() {
    return Column(
        children: List.generate(items.length, (index) {
      return Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/wifi_signal_3.png'),
              const SizedBox(
                width: 4,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _information(index),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  NavigationCubit.of(context)
                      .push(ShareWifiPath()..args = {'info': items[index]});
                },
                child: const Icon(Icons.ios_share),
              ),
            ],
          ),
          Offstage(
            offstage: index == items.length - 1,
            child: const Divider(
                thickness: 1, height: 1, color: MoabColor.dividerGrey),
          )
        ],
      );
    }));
  }

  Widget _information(int index) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              items[index].wifiType.displayTitle,
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
            ),
            const SizedBox(
              width: 10,
            ),
            Container(
              child: Text(
                items[index].isWifiEnabled ? 'ON' : 'OFF',
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              color: const Color(0xffc5c5c5),
              padding: const EdgeInsets.all(5),
            )
          ],
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          items[index].ssid,
          style: Theme.of(context)
              .textTheme
              .headline2
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
        ),
        const SizedBox(
          height: 8,
        ),
        HiddenPasswordWidget(password: items[index].password),
        const SizedBox(
          height: 8,
        ),
        Text(
          '${items[index].numOfDevices} devices',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: 'WiFi(${items.length})',
        ),
        content: _wifiList(),
      ),
    );
  }
}
