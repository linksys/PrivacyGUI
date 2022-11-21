import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/guest_radio_settings.dart';
import 'package:linksys_moab/model/router/iot_network_settings.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/customs/hidden_password_widget.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
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
    Map<WifiType, int> deviceCountMap = getConnectionDeviceCount(state.selected?.devices);
    if (radioInfo != null) {
      Map<String, RouterRadioInfo> infoMap =
          Map.fromEntries(radioInfo.map((e) => MapEntry(e.settings.ssid, e)));
      _items = List.from(infoMap.values).map((e) {
        RouterRadioInfo info = e as RouterRadioInfo;
        return WifiListItem(
            wifiType: WifiType.main,
            ssid: info.settings.ssid,
            password: info.settings.wpaPersonalSettings.passphrase,
            securityType:
                WifiListItem.convertToWifiSecurityType(info.settings.security),
            mode: WifiListItem.convertToWifiMode(info.settings.mode),
            isWifiEnabled: info.settings.isEnabled,
            numOfDevices: deviceCountMap[WifiType.main] ?? 0,
            signal: 0);
      }).toList();
    }
    GuestRadioSetting? guestRadioSetting = state.selected?.guestRadioSetting;
    if (guestRadioSetting != null) {
      _items.add(WifiListItem(
          wifiType: WifiType.guest,
          ssid: guestRadioSetting.radios.first.guestSSID,
          password: guestRadioSetting.radios.first.guestWPAPassphrase ?? '',
          securityType: _items.isNotEmpty
              ? _items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: _items.isNotEmpty ? _items.first.mode : WifiMode.mixed,
          isWifiEnabled: guestRadioSetting.isGuestNetworkEnabled,
          numOfDevices: deviceCountMap[WifiType.guest] ?? 0,
          signal: 0));
    }
    IoTNetworkSetting? iotNetworkSetting = state.selected?.iotNetworkSetting;
    if (iotNetworkSetting != null) {
      _items.add(WifiListItem(
          wifiType: WifiType.iot,
          ssid: '',
          password: '',
          securityType: _items.isNotEmpty
              ? _items.first.securityType
              : WifiSecurityType.wpa2Wpa3Mixed,
          mode: _items.isNotEmpty ? _items.first.mode : WifiMode.mixed,
          isWifiEnabled: iotNetworkSetting.isIoTNetworkEnabled,
          numOfDevices: deviceCountMap[WifiType.iot] ?? 0,
          signal: 0));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: 'WiFi(${items.length})',
        ),
        content: _wifiList(),
      ),
    );
  }

  Map<WifiType, int> getConnectionDeviceCount(List<RouterDevice>? devices) {
    Map<WifiType, int> map = {
      WifiType.main: 0,
      WifiType.guest: 0,
      WifiType.iot: 0,
    };
    int mainCount = 0;
    int guestCount = 0;
    int iotCount = 0;
    if (devices != null && devices.isNotEmpty) {
      for (RouterDevice device in devices) {
        if (device.connections.isNotEmpty && (device.connections.first.isGuest ?? false)) {
          guestCount += 1;
        } else if (!device.isAuthority && device.nodeType == null) {
          mainCount += 1;
        }
      }
      map[WifiType.main] = mainCount;
      map[WifiType.guest] = guestCount;
      map[WifiType.iot] = iotCount;
    }
    return map;
  }
}
