import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/wifi_settings/view/wifi_settings_view.dart';
import 'package:linksys_moab/route/model/wifi_settings_path.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';

class WifiListView extends StatefulWidget {
  const WifiListView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WifiListViewState();
}

class _WifiListViewState extends State<WifiListView> {
  //TODO: Remove the dummy data
  List<WifiListItem> items = [];

  @override
  void initState() {
    super.initState();

    items = _getWifiInfo();
  }

  List<WifiListItem> _getWifiInfo() {
    List<WifiListItem> _items = [];
    final state = context.read<NetworkCubit>().state;
    List<RouterRadioInfo>? radioInfo = state.selected?.radioInfo;
    if (radioInfo != null) {
      Map<String, RouterRadioInfo> infoMap =
          Map.fromEntries(radioInfo.map((e) => MapEntry(e.settings.ssid, e)));
      _items = List.from(infoMap.values).map((e) {
        RouterRadioInfo info = e as RouterRadioInfo;
        return WifiListItem(
          WifiType.main,
          info.settings.ssid,
          info.settings.wpaPersonalSettings.passphrase,
          WifiListItem.convertToWifiSecurityType(info.settings.security),
          WifiListItem.convertToWifiMode(info.settings.mode),
          info.settings.isEnabled,
          getConnectionDeviceCount(state.selected?.devices),
          100,
        );
      }).toList();
    }
    return _items;
  }

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
                  ?.copyWith(color: Theme.of(context).colorScheme.surface),
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
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
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
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
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

  int getConnectionDeviceCount(List<RouterDevice>? devices) {
    int deviceCount = 0;
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (!device.isAuthority && device.nodeType == null) {
          deviceCount += 1;
        }
      }
    }
    return deviceCount;
  }
}
